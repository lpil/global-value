-module(global_value_test_ffi).
-export([rec/0, yield/2]).

rec() ->
    receive
        X -> X
    after
        1000 -> erlang:error(timeout)
    end.

yield(Ms, F) ->
    timer:sleep(Ms),
    F(),
    nil.
