# std.mem.findMinMax

Finds the indices of the smallest and largest number in a slice. O(n). Returns the indices of the smallest and largest numbers in that order. `slice` must not be empty.

## Parameters

    T: type

    slice: []const T

## Example Usage

```
test findMinMax {
    try testing.expectEqual(.{ 0, 6 }, findMinMax(u8, "abcdefg"));
    try testing.expectEqual(.{ 1, 0 }, findMinMax(u8, "gabcdef"));
    try testing.expectEqual(.{ 0, 0 }, findMinMax(u8, "a"));
}
```

## Source Code

```
pub fn findMinMax(comptime T: type, slice: []const T) struct { usize, usize } {
    assert(slice.len > 0);
    var minVal = slice[0];
    var maxVal = slice[0];
    var minIdx: usize = 0;
    var maxIdx: usize = 0;
    for (slice[1..], 0..) |item, i| {
        if (item < minVal) {
            minVal = item;
            minIdx = i + 1;
        }
        if (item > maxVal) {
            maxVal = item;
            maxIdx = i + 1;
        }
    }
    return .{ minIdx, maxIdx };
}
```
