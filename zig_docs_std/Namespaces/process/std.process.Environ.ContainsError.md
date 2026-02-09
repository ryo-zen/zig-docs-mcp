# std.process.Environ.ContainsError

## Errors

InvalidWtf8  
On Windows, environment variable keys provided by the user must be valid WTF-8. This error is unreachable if the key is statically known to be valid.

OutOfMemory  

Unexpected  
WASI-only. `environ_sizes_get` or `environ_get` failed for an unexpected reason.
