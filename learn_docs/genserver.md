# How genserver works

Gen server is wrapper around otp libraries and can be consideres a essential bulding block for multi process apps.

## server callbacks

Those are the calls from GenServer functions
handle_call -> Returns a value to caller
handle_cast -> Does not return a value but handles a cast message
handle_info -> Handles external calls like from send() function as send(genserver_pid, message)
handle_continue ->

## client calls

This functions are preferd to be wrapped into user defined functions

GenServer.call
GenServer.cast
GenServer.start_link
