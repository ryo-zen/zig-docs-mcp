# std.process.ReplaceOptions

### Fields

    argv: []const []const u8

    expand_arg0: ArgExpansion = .no_expand

    environ_map: ?*const Environ.Map = null

Replaces the environment when provided. The PATH value from here is never used to resolve `argv[0]`.
