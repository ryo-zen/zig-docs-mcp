# std Types Documentation Status

Last updated: 2026-02-14

## Coverage Summary

Type docs under `zig_docs_std/Types/` are partially complete with strong coverage for commonly used containers and I/O types.

## Status

| Type Group | Examples | Status |
|---|---|---|
| Collections | `ArrayList`, `ArrayHashMap`, `AutoHashMap` | ✅ Documented |
| Utility types | `BufMap`, `BufSet`, `BitStack` | ✅ Documented |
| Build and runtime | `std.Build`, `std.Io` families | ✅ Documented |
| Long-tail types/subtypes | less-used or generated pages | 🔄 In progress |

## Next Pass

1. Improve consistency in overview/quick-start/gotchas sections for long-tail type docs.
2. Add/verify runnable example links for high-traffic type docs.
3. Continue replacing fragile intra-doc anchors with local file links where needed.
