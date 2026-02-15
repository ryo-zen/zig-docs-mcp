# std.array_list.Aligned.SentinelSlice

## Parameters

    s: T

## Source Code

```
598
599
600
```

```
pub fn SentinelSlice(comptime s: T) type {
    return if (alignment) |a| ([:s]align(a.toByteUnits()) T) else [:s]T;
}
```
