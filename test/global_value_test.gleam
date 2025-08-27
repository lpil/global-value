import gleeunit
import global_value

pub fn main() -> Nil {
  gleeunit.main()
}

type DoNotLeak

type Pid

@external(erlang, "erlang", "unique_integer")
@external(javascript, "./global_value_test_ffi.mjs", "unique_int")
fn unique_int() -> Int

@external(erlang, "timer", "sleep")
@external(javascript, "./global_value_test_ffi.mjs", "sleep")
fn sleep(ms: Int) -> DoNotLeak

@external(erlang, "global_value_test_ffi", "yield")
@external(javascript, "./global_value_test_ffi.mjs", "yield_")
fn yield(ms: Int, next: fn() -> t) -> Nil

@external(erlang, "erlang", "spawn_link")
@external(javascript, "./global_value_test_ffi.mjs", "spawn")
fn spawn_link(f: fn() -> anything) -> Pid

@external(erlang, "erlang", "send")
@external(javascript, "./global_value_test_ffi.mjs", "send")
fn send(pid: Pid, message: Int) -> DoNotLeak

@external(erlang, "erlang", "self")
@external(javascript, "./global_value_test_ffi.mjs", "self")
fn self() -> Pid

@external(erlang, "global_value_test_ffi", "rec")
@external(javascript, "./global_value_test_ffi.mjs", "rec")
fn receive() -> Int

fn global1() -> Int {
  use <- global_value.create_with_unique_name("global-value-1")
  unique_int()
}

fn global2() -> Int {
  use <- global_value.create_with_unique_name("global-value-2")
  unique_int()
}

fn slow_global() -> Int {
  use <- global_value.create_with_unique_name("global-value-slow")
  sleep(250)
  unique_int()
}

pub fn initialisation_only_once_test() {
  let value = global1()
  // Every time it is called the same unique int it returned, so the
  // initialiser must have only run once.
  assert value == global1()
  assert value == global1()
  assert value == global1()

  // The other global got a different unique int
  assert value != global2()
}

pub fn concurrent_initialisation_test() {
  let parent = self()

  // The these child processes will race to initialise this global value.
  spawn_link(fn() { send(parent, slow_global()) })
  spawn_link(fn() { send(parent, slow_global()) })
  spawn_link(fn() { send(parent, slow_global()) })
  spawn_link(fn() { send(parent, slow_global()) })

  use <- yield(300)

  // They all got the same unique int, so only one of them could have
  // succeeded.
  let t1 = receive()
  let t2 = receive()
  let t3 = receive()
  let t4 = receive()
  assert t1 == t2
  assert t2 == t3
  assert t3 == t4
}
