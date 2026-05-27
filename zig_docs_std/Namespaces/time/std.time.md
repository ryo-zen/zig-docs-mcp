# std.time

## Overview

`std.time` contains time-unit conversion constants and the `std.time.epoch` namespace.

Source: `/path/to/zig-0.16.0/lib/std/time.zig`

## Public API

### Epoch Namespace

- `std.time.epoch` - calendar and epoch utilities imported from `time/epoch.zig`.

### Nanosecond Constants

- `std.time.ns_per_us`
- `std.time.ns_per_ms`
- `std.time.ns_per_s`
- `std.time.ns_per_min`
- `std.time.ns_per_hour`
- `std.time.ns_per_day`
- `std.time.ns_per_week`

### Microsecond Constants

- `std.time.us_per_ms`
- `std.time.us_per_s`
- `std.time.us_per_min`
- `std.time.us_per_hour`
- `std.time.us_per_day`
- `std.time.us_per_week`

### Millisecond Constants

- `std.time.ms_per_s`
- `std.time.ms_per_min`
- `std.time.ms_per_hour`
- `std.time.ms_per_day`
- `std.time.ms_per_week`

### Second Constants

- `std.time.s_per_min`
- `std.time.s_per_hour`
- `std.time.s_per_day`
- `std.time.s_per_week`

## Notes

In the locked Zig 0.16 stdlib source for this repository, root `std.time` is a constants-and-epoch namespace. Do not assume older root APIs such as timers or clock reads are present here without checking the local source.
