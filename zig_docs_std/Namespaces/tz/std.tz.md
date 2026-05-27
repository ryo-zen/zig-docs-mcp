# std.tz

## Overview

`std.tz` parses Time Zone Information Format files, also known as TZif.

Source: `/path/to/zig-0.16.0/lib/std/tz.zig`

## Public API

- `std.tz.Transition` - transition timestamp and pointer to its time type.
- `std.tz.Timetype` - UTC offset, flags, and time-zone abbreviation storage.
- `std.tz.Leapsecond` - leap-second occurrence and correction.
- `std.tz.Tz` - parsed TZif data with transitions, time types, leap seconds, and optional footer.

## Tz Methods

- `std.tz.Tz.parse(allocator, reader)` - parses TZif data from an `std.Io.Reader`.
- `deinit()` - releases allocations owned by the parsed time-zone value.

## Notes

The parser validates RFC 8536 structure such as the `TZif` magic, version, count consistency, and time-type indexes.
