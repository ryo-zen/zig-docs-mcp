# std.array_list.Aligned.Slice

## Source Code

```
596
```

```
pub const Slice = if (alignment) |a| ([]align(a.toByteUnits()) T) else []T
```
