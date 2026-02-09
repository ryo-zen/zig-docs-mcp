# std.process.Child.Cwd

### Fields

    inherit

CWD of the child is the same as the current CWD.

    dir: Io.Dir

On POSIX systems, `fchdir` is called after `fork` using this handle. On Windows, the path is inferred from the provided handle and that path is used when calling `CreateProcessW`.

    path: []const u8

On POSIX systems, `chdir` is called after `fork` using this path. On Windows, this path is used when calling `CreateProcessW`.
