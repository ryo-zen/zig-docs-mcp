# std.process.SpawnOptions

📚 **[See Comprehensive Examples & Tests](../../Examples/)**

## Overview

`std.process.SpawnOptions` is the configuration structure used by `std.process.spawn()` and `std.process.spawnPath()`. It provides fine-grained control over how a child process is created, its working directory, environment, and standard I/O redirection.

---

## Fields

`argv: []const []const u8`
------
**Mandatory.** The command and its arguments. `argv[0]` is the name of the program to execute.

`cwd: ?[]const u8 = null`
------
The current working directory for the child process. If `null`, it inherits the parent's current working directory.

`cwd_dir: ?std.Io.Dir = null`
------
An alternative to `cwd` that uses an open directory handle. This is more robust against race conditions and is required for WASI.

`environ_map: ?*const std.process.Environ.Map = null`
------
If provided, replaces the child's environment variables. If `null`, the child inherits the parent's environment.

`expand_arg0: std.process.ArgExpansion = .no_expand`
------
Controls whether `argv[0]` should be expanded (e.g., searching the PATH).

`stdin: StdIo = .inherit`
------
Redirection for the child's standard input.

`stdout: StdIo = .inherit`
------
Redirection for the child's standard output.

`stderr: StdIo = .inherit`
------
Redirection for the child's standard error.

`uid: ?std.posix.uid_t = null`
------
**POSIX-only.** The user ID to set for the child process.

`gid: ?std.posix.gid_t = null`
------
**POSIX-only.** The group ID to set for the child process.

---

## Nested Types

### `StdIo` (union)

Controls standard stream redirection.

- `.inherit` - Use the parent's stream.
- `.pipe` - Create a pipe between parent and child.
- `.ignore` - Redirect to `/dev/null` (or `NUL` on Windows).
- `.file: std.Io.File` - Redirect to an already open file handle.

---

## Usage Example

```zig
const options = std.process.SpawnOptions{
    .argv = &[_][]const u8{ "git", "status" },
    .cwd = "/home/user/repo",
    .stdout = .pipe,
    .stderr = .inherit,
};

var child = try std.process.spawn(init.io, options);
```

---

## See Also

- **std.process.spawn** - The function that consumes this struct.
- **std.process.StdIo** - Details on the redirection union.
- **std.process.Environ.Map** - For setting custom environment variables.
