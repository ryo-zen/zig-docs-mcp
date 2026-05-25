# std.SemanticVersion

`std.SemanticVersion` is the root import of `SemanticVersion.zig`, a small value type for Semantic Versioning 2.0.0 strings.

## Source Declaration

```zig
pub const SemanticVersion = @import("SemanticVersion.zig");
```

## Data Fields

- `major: usize`
- `minor: usize`
- `patch: usize`
- `pre: ?[]const u8 = null`
- `build: ?[]const u8 = null`

The optional `pre` and `build` slices point into caller-owned memory. `parse` returns slices into the input text.

## Nested Types

### `Range`

```zig
pub const Range = struct {
    min: Version,
    max: Version,
};
```

`Range` describes an inclusive minimum and maximum semantic version. It provides `includesVersion` and `isAtLeast` helpers.

## Core Functions

### `pub fn parse(text: []const u8) !Version`

Parses a semantic version string and validates required numeric fields, optional pre-release identifiers, and optional build metadata identifiers.

Returns `error.InvalidVersion` for malformed text and `error.Overflow` when a numeric field does not fit in `usize`.

### `pub fn order(lhs: Version, rhs: Version) std.math.Order`

Compares two versions using semantic version precedence rules. Build metadata does not affect ordering.

### `pub fn format(self: Version, w: *std.Io.Writer) std.Io.Writer.Error!void`

Writes the canonical semantic version text, including pre-release and build metadata when present.

## Notes

- Numeric identifiers must not contain leading zeroes.
- Pre-release identifiers are compared before release versions.
- Numeric pre-release identifiers have lower precedence than non-numeric identifiers.
- Build metadata is preserved for formatting but ignored by `order`.

## See Also

- `std.Target.Os.VersionRange`
- `std.Target.Os.TaggedVersionRange`
