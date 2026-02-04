# std.mem.minMax

Finds the smallest and largest number in a slice. O(n). Returns an anonymous struct with the fields `min` and `max`. `slice` must not be empty.

## Parameters

    T: type

    slice: []const T

## Example Usage

```
test minMax {
    {
        const actual_min, const actual_max = minMax(u8, "abcdefg");
        try testing.expectEqual(@as(u8, 'a'), actual_min);
        try testing.expectEqual(@as(u8, 'g'), actual_max);
    }
    {
        const actual_min, const actual_max = minMax(u8, "bcdefga");
        try testing.expectEqual(@as(u8, 'a'), actual_min);
        try testing.expectEqual(@as(u8, 'g'), actual_max);
    }
    {
        const actual_min, const actual_max = minMax(u8, "a");
        try testing.expectEqual(@as(u8, 'a'), actual_min);
        try testing.expectEqual(@as(u8, 'a'), actual_max);
    }
}
```

## Source Code

```
pub fn minMax(comptime T: type, slice: []const T) struct { T, T } {
    assert(slice.len > 0);
    var running_minimum = slice[0];
    var running_maximum = slice[0];
    for (slice[1..]) |item| {
        running_minimum = @min(running_minimum, item);
        running_maximum = @max(running_maximum, item);
    }
    return .{ running_minimum, running_maximum };
}
```
