# std.process.Child.WaitError

## Errors

AccessDenied  

Canceled Cancelable  
Caller has requested the async operation to stop.

Unexpected UnexpectedError  
The Operating System returned an undocumented error code.

This error is in theory not possible, but it would be better to handle this error than to invoke undefined behavior.

When this error code is observed, it usually means the Zig Standard Library needs a small patch to add the error code to the error set for the respective function.
