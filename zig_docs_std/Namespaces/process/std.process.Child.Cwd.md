# std.process.Child.Cwd

⚠️ **Deprecated / Internal in Zig 0.16**

In Zig 0.16, `std.process.spawn` and `std.process.run` have moved away from this union in favor of explicit fields in their options structs:

- `cwd: ?[]const u8` - Specify a path as a string.
- `cwd_dir: ?std.Io.Dir` - Specify a directory handle (preferred).

## Historical / Internal Fields

`inherit`
------
CWD of the child is the same as the current CWD.

`dir: std.Io.Dir`
------
Uses a directory handle to set the working directory.

`path: []const u8`
------
Uses a string path to set the working directory.

---

## See Also

- **std.process.SpawnOptions** - Contains the modern `cwd` and `cwd_dir` fields.
- **std.process.RunOptions** - Contains the modern `cwd` and `cwd_dir` fields.
