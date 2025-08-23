// TODO: document
pub fn create_with_unique_name(name: String, initialiser: fn() -> t) -> t {
  let name_hash = phash2(name)
  case get_previously_stored_value(name_hash) {
    Ok(value) -> value

    // There is no previous stored instance, so we need to initialise the
    // value and store it.
    Error(_) -> {
      // There could be multiple processes trying to create this at the same
      // time, so we create a global transaction to ensure that only one of
      // them can.
      let me = current_process()
      transaction(id: #(name_hash, me), nodes: [current_node()], run: fn() {
        case get_previously_stored_value(name_hash) {
          // If the name now exists that means that there were multiple
          // processes attempting to initialise the global variable and one of
          // the other ones beat this one to acquire the transaction, so they
          // initialised it.
          Ok(value) -> value

          // The value still does not exist, so this process won the
          // transaction race and needs to initialise the value.
          Error(_) -> {
            let value = initialiser()
            persistent_term_put(name_hash, #(GleamGlobalValue, value))
            value
          }
        }
      })
    }
  }
}

fn get_previously_stored_value(name_hash: Int) -> Result(t, Nil) {
  case persistent_term_get(name_hash) {
    // Successfully retrieved previously stored value.
    Ok(value) -> Ok(value)

    Error(InvalidStoredFormat) ->
      panic as "global_value error: the name was already taken by something else in persistent_term storage"

    Error(DoesNotExist) -> Error(Nil)
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
