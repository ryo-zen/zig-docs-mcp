# std.Tz

`std.Tz` is the root alias for `std.tz.Tz`, a parser-owned representation of Time Zone Information Format data.

## Source Declaration

```zig
pub const Tz = tz.Tz;
```

## Backing Type

`std.Tz` is declared in `tz.zig` as:

```zig
pub const Tz = struct {
    allocator: Allocator,
    transitions: []const Transition,
    timetypes: []const Timetype,
    leapseconds: []const Leapsecond,
    footer: ?[]const u8,
};
```

## Companion Types

### `Transition`

```zig
pub const Transition = struct {
    ts: i64,
    timetype: *Timetype,
};
```

### `Timetype`

```zig
pub const Timetype = struct {
    offset: i32,
    flags: u8,
    name_data: [6:0]u8,
};
```

`Timetype` provides `name`, `isDst`, `standardTimeIndicator`, and `utIndicator`.

### `Leapsecond`

```zig
pub const Leapsecond = struct {
    occurrence: i48,
    correction: i16,
};
```

## Core Functions

### `pub fn parse(allocator: Allocator, reader: *Reader) !Tz`

Parses TZif data from a reader. Version 1 files are parsed directly; version 2 and 3 files skip the legacy block and parse the modern block.

The parser validates header magic, version, count consistency, transition indexes, time type designators, leap-second monotonicity, and footer framing.

### `pub fn deinit(self: *Tz) void`

Frees slices and optional footer memory allocated by `parse`.

## Parse Errors

The parser can return reader and allocator errors, plus validation errors such as:

- `error.BadHeader`
- `error.BadVersion`
- `error.Malformed`
- `error.OverlargeFooter`

## Notes

- Parsed arrays are owned by the returned `Tz` and must be released with `deinit`.
- Time type names are stored in fixed `[6:0]u8` buffers.
- Modern TZif footers are duplicated only when non-empty.

## See Also

- `std.tz`
- `std.Io.Reader`
