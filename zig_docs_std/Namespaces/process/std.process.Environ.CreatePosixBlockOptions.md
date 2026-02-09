# std.process.Environ.CreatePosixBlockOptions

### Fields

    zig_progress_fd: ?i32 = null

`null` means to leave the `ZIG_PROGRESS` environment variable unmodified. If non-null, negative means to remove the environment variable, and \>= 0 means to provide it with the given integer.
