# std.process.ProtectMemoryError

## Errors

AccessDenied
The memory cannot be given the specified access. This can happen, for example, if you memory map a file to which you have read-only access, then use `protectMemory` to mark it writable.

OutOfMemory
Changing the protection of a memory region would result in the total number of mappings with distinct attributes exceeding the allowed maximum.

PermissionDenied
OpenBSD will refuse to change memory protection if the specified region contains any pages that have previously been marked immutable using the `mimmutable` function.

Unexpected UnexpectedError
The Operating System returned an undocumented error code.

This error is in theory not possible, but it would be better to handle this error than to invoke undefined behavior.

When this error code is observed, it usually means the Zig Standard Library needs a small patch to add the error code to the error set for the respective function.

UnsupportedOperation
