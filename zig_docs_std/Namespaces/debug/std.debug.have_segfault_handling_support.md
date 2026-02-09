# std.debug.have_segfault_handling_support

Whether or not the current target can print useful debug information when a segfault occurs.

## Source Code

```
pub const have_segfault_handling_support = switch (native_os) {
    .haiku,
    .linux,
    .serenity,

    .dragonfly,
    .freebsd,
    .netbsd,
    .openbsd,

    .driverkit,
    .ios,
    .maccatalyst,
    .macos,
    .tvos,
    .visionos,
    .watchos,

    .illumos,

    .windows,
    => true,

    else => false,
}
```
