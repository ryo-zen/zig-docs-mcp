# std.array_list.AlignedManaged.SentinelSlice

## Parameters

    s: T

## Source Code

```
39
40
41
```

```
pub fn SentinelSlice(comptime s: T) type {
    return if (alignment) |a| ([:s]align(a.toByteUnits()) T) else [:s]T;
}
```
