# std.process.Child.WaitError

📚 **[See Comprehensive Examples & Tests](../../Examples/)**

## Overview

`std.process.Child.WaitError` is the error set returned by `child.wait()`. It includes errors related to I/O cancellation and unexpected operating system responses.

---

## Errors

`AccessDenied`
------
The caller does not have sufficient permissions to wait for the child process.

`Canceled`
------
The wait operation was canceled via the `std.Io` interface.

`Unexpected`
------
The operating system returned an undocumented or unexpected error code. This usually indicates a condition that the Zig standard library doesn't yet have a specific error for.

---

## See Also

- **std.process.Child.wait** - The function that returns this error set.
- **std.process.Child.Term** - The successful return type of `wait()`.
