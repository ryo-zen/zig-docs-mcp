# std.Io.Dir.max_path_bytes

The maximum length of a file path that the operating system will accept.

## Source Code

```
pub const max_path_bytes = switch (native_os) {
    .linux, .driverkit, .ios, .maccatalyst, .macos, .tvos, .visionos, .watchos, .freebsd, .openbsd, .netbsd, .dragonfly, .haiku, .illumos, .plan9, .emscripten, .wasi, .serenity => std.posix.PATH_MAX,
    // Each WTF-16LE code unit may be expanded to 3 WTF-8 bytes.
    // If it would require 4 WTF-8 bytes, then there would be a surrogate
    // pair in the WTF-16LE, and we (over)account 3 bytes for it that way.
    // +1 for the null byte at the end, which can be encoded in 1 byte.
    .windows => std.os.windows.PATH_MAX_WIDE * 3 + 1,
    else => if (@hasDecl(root, "os") and @hasDecl(root.os, "PATH_MAX"))
  root.os.PATH_MAX
    else
  @compileError("PATH_MAX not implemented for " ++ @tagName(native_os)),
}
```
