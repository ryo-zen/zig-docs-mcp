# std.process.Environ.CreateWindowsBlockOptions

### Fields

    zig_progress_handle: ?std.os.windows.HANDLE = null

`null` means to leave the `ZIG_PROGRESS` environment variable unmodified. If non-null, `std.os.windows.INVALID_HANDLE_VALUE` means to remove the environment variable, otherwise provide it with the given handle as an integer.
