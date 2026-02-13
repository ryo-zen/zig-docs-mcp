# std.Io.Dir.max_name_bytes

This represents the maximum size of a `[]u8` file name component that the platform's common file systems support. File name components returned by file system operations are likely to fit into a `u8` array of this length, but (depending on the platform) this assumption may not hold for every configuration. The byte count does not include a null sentinel byte. On Windows, `[]u8` file name components are encoded as WTF-8. On WASI, file name components are encoded as valid UTF-8. On other platforms, `[]u8` components are an opaque sequence of bytes with no particular encoding.

## Source Code

```
pub const max_name_bytes = switch (native_os) {
    .linux, .driverkit, .ios, .maccatalyst, .macos, .tvos, .visionos, .watchos, .freebsd, .openbsd, .netbsd, .dragonfly, .illumos, .serenity => std.posix.NAME_MAX,
    // Haiku's NAME_MAX includes the null terminator, so subtract one.
    .haiku => std.posix.NAME_MAX - 1,
    // Each WTF-16LE character may be expanded to 3 WTF-8 bytes.
    // If it would require 4 WTF-8 bytes, then there would be a surrogate
    // pair in the WTF-16LE, and we (over)account 3 bytes for it that way.
    .windows => std.os.windows.NAME_MAX * 3,
    // For WASI, the MAX_NAME will depend on the host OS, so it needs to be
    // as large as the largest max_name_bytes (Windows) in order to work on any host OS.
    // TODO determine if this is a reasonable approach
    .wasi => std.os.windows.NAME_MAX * 3,
    else => if (@hasDecl(root, "os") and @hasDecl(root.os, "NAME_MAX"))
  root.os.NAME_MAX
    else
  @compileError("NAME_MAX not implemented for " ++ @tagName(native_os)),
}
```
