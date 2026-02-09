# std.math.Min

Given two types, returns the smallest one which is capable of holding the full range of the minimum value.

## Parameters

    A: type

    B: type

## Source Code

```
pub fn Min(comptime A: type, comptime B: type) type {
    switch (@typeInfo(A)) {
        .int => |a_info| switch (@typeInfo(B)) {
            .int => |b_info| if (a_info.signedness == .unsigned and b_info.signedness == .unsigned) {
                if (a_info.bits < b_info.bits) {
                    return A;
                } else {
                    return B;
                }
            },
            else => {},
        },
        else => {},
    }
    return @TypeOf(@as(A, 0) + @as(B, 0));
}
```
