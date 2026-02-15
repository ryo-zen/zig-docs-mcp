# std.array_list.AlignedManaged.Slice

## Source Code

```
37
```

```
pub const Slice = if (alignment) |a| ([]align(a.toByteUnits()) T) else []T
```
