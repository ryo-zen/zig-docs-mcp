# std.process.ReplaceError

## Errors

AccessDenied  

BadPathName PathNameError  
File system cannot encode the requested file name bytes. Could be due to invalid WTF-8 on Windows, invalid UTF-8 on WASI, invalid characters on Windows, etc. Filesystem and operating specific.

Canceled Cancelable  
Caller has requested the async operation to stop.

FileBusy  

FileNotFound  

FileSystem  

InvalidExe  

IsDir  

NameTooLong PathNameError  
Returned when an insufficient buffer is provided that cannot fit the path name.

NotDir  

OperationUnsupported  
The target operating system cannot replace the process image with a new one.

OutOfMemory Error  

PermissionDenied  

ProcessFdQuotaExceeded  

SystemFdQuotaExceeded  

SystemResources  

Unexpected UnexpectedError  
The Operating System returned an undocumented error code.

This error is in theory not possible, but it would be better to handle this error than to invoke undefined behavior.

When this error code is observed, it usually means the Zig Standard Library needs a small patch to add the error code to the error set for the respective function.
