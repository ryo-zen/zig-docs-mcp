# std.process.SpawnError

## Errors

AccessDenied

BadPathName PathNameError
File system cannot encode the requested file name bytes. Could be due to invalid WTF-8 on Windows, invalid UTF-8 on WASI, invalid characters on Windows, etc. Filesystem and operating specific.

Canceled Cancelable
Caller has requested the async operation to stop.

FileBusy

FileNotFound

FileSystem

InvalidBatchScriptArg
Windows-only. NUL (U+0000), LF (U+000A), CR (U+000D) are not allowed within arguments when executing a `.bat`/`.cmd` script.

- NUL/LF signifiies end of arguments, so anything afterwards would be lost after execution.
- CR is stripped by `cmd.exe`, so any CR codepoints would be lost after execution.

InvalidExe

InvalidName

InvalidProcessGroupId

InvalidUserId

InvalidWtf8
Windows-only. `cwd` or `argv` was provided and it was invalid WTF-8. https://wtf-8.codeberg.page/

IsDir

NameTooLong PathNameError
Returned when an insufficient buffer is provided that cannot fit the path name.

NoDevice
POSIX-only. `StdIo.ignore` was selected and opening `/dev/null` returned ENODEV.

NotDir

OperationUnsupported
The operating system does not support creating child processes.

OutOfMemory

PermissionDenied

ProcessAlreadyExec
An attempt was made to change the process group ID of one of the children of the calling process and the child had already performed an image replacement.

ProcessFdQuotaExceeded

ResourceLimitReached

SymLinkLoop

SystemFdQuotaExceeded

SystemResources

Unexpected UnexpectedError
The Operating System returned an undocumented error code.

This error is in theory not possible, but it would be better to handle this error than to invoke undefined behavior.

When this error code is observed, it usually means the Zig Standard Library needs a small patch to add the error code to the error set for the respective function.

UnrecognizedVolume
On Windows, the volume does not contain a recognized file system. File system drivers might not be loaded, or the volume may be corrupt.
