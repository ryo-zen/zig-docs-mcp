# std.process.OpenExecutableError

## Errors

AccessDenied OpenError  
In WASI, this error may occur when the file descriptor does not hold the required rights to open a new resource relative to it.

AntivirusInterference OpenError  
On Windows, antivirus software is enabled by default. It can be disabled, but Windows Update sometimes ignores the user's preference and re-enables it. When enabled, antivirus software on Windows intercepts file system operations and makes them significantly slower in addition to possibly failing with this error code.

BadPathName PathNameError  
File system cannot encode the requested file name bytes. Could be due to invalid WTF-8 on Windows, invalid UTF-8 on WASI, invalid characters on Windows, etc. Filesystem and operating specific.

Canceled Cancelable  
Caller has requested the async operation to stop.

DeviceBusy OpenError  

FileBusy OpenError  
One of these three things:

- pathname refers to an executable image which is currently being executed and write access was requested.
- pathname refers to a file that is currently in use as a swap file, and the O_TRUNC flag was specified.
- pathname refers to a file that is currently being read by the kernel (e.g., for module/firmware loading), and write access was requested.

FileLocksUnsupported OpenError  

FileNotFound OpenError  
Either:

- One of the path components does not exist.
- Cwd was used, but cwd has been deleted.
- The path associated with the open directory handle has been deleted.
- On macOS, multiple processes or threads raced to create the same file with `O.EXCL` set to `false`.

FileSystem ExecutablePathBaseError  

FileTooBig OpenError  
The file is too large to be opened. This error is unreachable for 64-bit targets, as well as when opening directories.

InputOutput ExecutablePathBaseError  

IsDir OpenError  
Either:

- The path refers to a directory and write permissions were requested.
- The path refers to a directory and `allow_directory` was set to false.

NameTooLong PathNameError  
Returned when an insufficient buffer is provided that cannot fit the path name.

NetworkNotFound OpenError  
On Windows, `\\server` or `\\server\share` was not found.

NoDevice OpenError  

NoSpaceLeft OpenError  
A new path cannot be created because the device has no room for the new file. This error is only reachable when the `CREAT` flag is provided.

NotDir OpenError  
A component used as a directory in the path was not, in fact, a directory, or `DIRECTORY` was specified and the path was not a directory.

NotLink ExecutablePathBaseError  

OperationUnsupported ExecutablePathBaseError  
The operating system does not support an executable learning its own path.

PathAlreadyExists OpenError  
The path already exists and the `CREAT` and `EXCL` flags were provided.

PermissionDenied OpenError  

PipeBusy OpenError  

ProcessFdQuotaExceeded OpenError  

ProcessNotFound ExecutablePathBaseError  

SymLinkLoop OpenError  

SystemFdQuotaExceeded OpenError  

SystemResources OpenError  
The path exceeded `max_path_bytes` bytes. Insufficient kernel memory was available, or the named file is a FIFO and per-user hard limit on memory allocation for pipes has been reached.

Unexpected UnexpectedError  
The Operating System returned an undocumented error code.

This error is in theory not possible, but it would be better to handle this error than to invoke undefined behavior.

When this error code is observed, it usually means the Zig Standard Library needs a small patch to add the error code to the error set for the respective function.

UnrecognizedVolume ExecutablePathBaseError  
On Windows, the volume does not contain a recognized file system. File system drivers might not be loaded, or the volume may be corrupt.

WouldBlock OpenError  
Non-blocking was requested and the operation cannot return immediately.
