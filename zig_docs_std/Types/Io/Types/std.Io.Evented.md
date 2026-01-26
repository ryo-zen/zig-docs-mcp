# std.Io.Evented

## Source Code

```
pub const Evented = switch (builtin.os.tag) {
    .linux => switch (builtin.cpu.arch) {
        .x86_64, .aarch64 => IoUring,
        else => void, // context-switching code not implemented yet
    },
    .dragonfly, .freebsd, .netbsd, .openbsd, .driverkit, .ios, .maccatalyst, .macos, .tvos, .visionos, .watchos => switch (builtin.cpu.arch) {
        .x86_64, .aarch64 => Kqueue,
        else => void, // context-switching code not implemented yet
    },
    else => void,
}
```
