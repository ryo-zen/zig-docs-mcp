# std.process.ExecutablePathAllocError

## Errors

AccessDenied ExecutablePathBaseError

AntivirusInterference ExecutablePathBaseError
On Windows, antivirus software is enabled by default. It can be disabled, but Windows Update sometimes ignores the user's preference and re-enables it. When enabled, antivirus software on Windows intercepts file system operations and makes them significantly slower in addition to possibly failing with this error code.

BadPathName ExecutablePathBaseError

Canceled Cancelable
Caller has requested the async operation to stop.

DeviceBusy ExecutablePathBaseError

FileNotFound ExecutablePathBaseError

FileSystem ExecutablePathBaseError

FileTooBig ExecutablePathBaseError

InputOutput ExecutablePathBaseError

IsDir ExecutablePathBaseError

NetworkNotFound ExecutablePathBaseError
On Windows, `\\server` or `\\server\share` was not found.

NoDevice ExecutablePathBaseError

NoSpaceLeft ExecutablePathBaseError

NotDir ExecutablePathBaseError

NotLink ExecutablePathBaseError

OperationUnsupported ExecutablePathBaseError
The operating system does not support an executable learning its own path.

OutOfMemory Error

PathAlreadyExists ExecutablePathBaseError

PermissionDenied ExecutablePathBaseError

PipeBusy ExecutablePathBaseError

ProcessFdQuotaExceeded ExecutablePathBaseError

ProcessNotFound ExecutablePathBaseError

SymLinkLoop ExecutablePathBaseError

SystemFdQuotaExceeded ExecutablePathBaseError

SystemResources ExecutablePathBaseError

Unexpected UnexpectedError
The Operating System returned an undocumented error code.

This error is in theory not possible, but it would be better to handle this error than to invoke undefined behavior.

When this error code is observed, it usually means the Zig Standard Library needs a small patch to add the error code to the error set for the respective function.

UnrecognizedVolume ExecutablePathBaseError
On Windows, the volume does not contain a recognized file system. File system drivers might not be loaded, or the volume may be corrupt.
