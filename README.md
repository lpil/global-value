# global_value

Create singleton values accessible anywhere in your application.

[![Package Version](https://img.shields.io/hexpm/v/global_value)](https://hex.pm/packages/global_value)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/global_value/)

```sh
gleam add global_value@1
```
```gleam
// test/my_app_test.gleam
import database
import global_value

// Define the global data

pub type TestGlobalData {
  TestGlobalData(db: database.ConnectionPool)
}

// A function to get-or-create the global data.
// In this example the first time the global data is accessed the database
// connection is created, and then the following times the already-created
// database connection is used.
pub fn global_data() -> TestGlobalData {
  global_value.create_with_unique_name("my_app_test.global.data", fn() {
    TestGlobalData(db: database.create_connection_pool())
  })
}

// Use it in tests

pub fn first_test() {
  let globals = global_data()
  // ... use the database connection here
}

pub fn second_test() {
  let globals = global_data()
  // ... use the database connection here
}
```

Further documentation can be found at <https://hexdocs.pm/global_value>.
