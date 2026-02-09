# std.math.big.int.Managed.toFloat

Convert `self` to `Float`.

## Parameters

    self: Managed

    Float: type

    round: Round

## Source Code

```
pub fn toFloat(self: Managed, comptime Float: type, round: Round) struct { Float, Exactness } {
    return self.toConst().toFloat(Float, round);
}
```
