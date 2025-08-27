/// Create a global value using a function and a string name. **The string name
/// must be globally unique**, e.g. the name of the module + the name of the
/// function. If you pick a name that is not unique then two global values can
/// collide at runtime, which can violate the type system and cause crashes or
/// worse.
///
/// This is most likely useful in your test suite for shared things such as
/// a database pool, assuming your test runner doesn't have a way to specify
/// shared state.
///
/// The value is held in persistent term storage on Erlang and in a singleton
/// object on JavaScript, so accessing the value from any process is efficient,
/// but you should have as few global values as possible. Ideally only have one
/// per project and put all the global state in a single value.
///
/// ## Example
///
/// ```gleam
/// // test/my_app_test.gleam
/// import database
/// import global_value
/// 
/// // Define the global data
/// 
/// pub type TestGlobalData {
///   TestGlobalData(db: database.ConnectionPool)
/// }
/// 
/// // A function to get-or-create the global data.
/// // In this example the first time the global data is accessed the database
/// // connection is created, and then the following times the already-created
/// // database connection is used.
/// pub fn global_data() -> TestGlobalData {
///   global_value.create_with_unique_name("my_app_test.global.data", fn() {
///     TestGlobalData(db: database.create_connection_pool())
///   })
/// }
/// 
/// // Use it in tests
/// 
/// pub fn first_test() {
///   let globals = global_data()
///   // ... use the database connection here
/// }
/// 
/// pub fn second_test() {
///   let globals = global_data()
///   // ... use the database connection here
/// }
/// ```
///
@external(javascript, "./global_value_ffi.mjs", "create_with_unique_name")
pub fn create_with_unique_name(name: String, initialiser: fn() -> t) -> t {
  let name_hash = phash2(name)

  let get_previously_stored_value = fn() -> Result(t, Nil) {
    case persistent_term_get(name_hash) {
      // Successfully retrieved previously stored value.
      Ok(value) -> Ok(value)

      Error(InvalidStoredFormat) ->
        panic as "global_value error: the name was already taken by something else in persistent_term storage"

      Error(DoesNotExist) -> Error(Nil)
    }
  }

  case get_previously_stored_value() {
    Ok(value) -> value

    // There is no previous stored instance, so we need to initialise the
    // value and store it.
    Error(_) -> {
      // There could be multiple processes trying to create this at the same
      // time, so we create a global transaction to ensure that only one of
      // them can.
      let me = current_process()
      transaction(id: #(name_hash, me), nodes: [current_node()], run: fn() {
        case get_previously_stored_value() {
          // If the name now exists that means that there were multiple
          // processes attempting to initialise the global variable and one of
          // the other ones beat this one to acquire the transaction, so they
          // initialised it.
          Ok(value) -> value

          // The value still does not exist, so this process won the
          // transaction race and needs to initialise the value.
          Error(_) -> {
            let value = initialiser()
            let _ = persistent_term_put(name_hash, #(GleamGlobalValue, value))
            value
          }
        }
      })
    }
  }
}

type Node

type Pid

@external(erlang, "erlang", "self")
fn current_process() -> Pid

@external(erlang, "erlang", "phash2")
fn phash2(value: anything) -> Int

@external(erlang, "erlang", "node")
fn current_node() -> Node

@external(erlang, "global", "trans")
fn transaction(
  id id: #(Int, Pid),
  run f: fn() -> t,
  nodes nodes: List(Node),
) -> t

@external(erlang, "persistent_term", "put")
fn persistent_term_put(key: Int, value: #(Header, t)) -> DoNotLeak

@external(erlang, "global_value_ffi", "persistent_term_get")
fn persistent_term_get(key: Int) -> Result(t, GetError)

type DoNotLeak

type Header {
  GleamGlobalValue
}

type GetError {
  InvalidStoredFormat
  DoesNotExist
}
