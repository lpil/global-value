-module(global_value_ffi).
-export([persistent_term_get/1]).

persistent_term_get(Key) ->
    try persistent_term:get(Key) of
        {gleam_global_value, Value} -> {ok, Value};
        _ -> {error, invalid_stored_format}
    catch
        error:badarg -> {error, does_not_exist}
    end.

