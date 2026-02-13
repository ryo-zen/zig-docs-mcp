# std.process.ExecutablePathBaseError

## Errors

AccessDenied

AntivirusInterference
On Windows, antivirus software is enabled by default. It can be disabled, but Windows Update sometimes ignores the user's preference and re-enables it. When enabled, antivirus software on Windows intercepts file system operations and makes them significantly slower in addition to possibly failing with this error code.

BadPathName

Canceled Cancelable
Caller has requested the async operation to stop.

DeviceBusy

FileNotFound

FileSystem

FileTooBig

InputOutput

IsDir

NetworkNotFound
On Windows, `\\server` or `\\server\share` was not found.

NoDevice

NoSpaceLeft

NotDir

NotLink

OperationUnsupported
The operating system does not support an executable learning its own path.

PathAlreadyExists

PermissionDenied

PipeBusy

ProcessFdQuotaExceeded

ProcessNotFound

SymLinkLoop

SystemFdQuotaExceeded

SystemResources

Unexpected UnexpectedError
The Operating System returned an undocumented error code.

This error is in theory not possible, but it would be better to handle this error than to invoke undefined behavior.

When this error code is observed, it usually means the Zig Standard Library needs a small patch to add the error code to the error set for the respective function.

UnrecognizedVolume
On Windows, the volume does not contain a recognized file system. File system drivers might not be loaded, or the volume may be corrupt.
