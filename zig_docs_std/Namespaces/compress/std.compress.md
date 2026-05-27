# std.compress

## Overview

`std.compress` groups compression and decompression namespaces.

Source: `/path/to/zig-0.16.0/lib/std/compress.zig`

## Public API

- `std.compress.flate` - DEFLATE compression and decompression support.
- `std.compress.lzma` - LZMA support.
- `std.compress.lzma2` - LZMA2 support.
- `std.compress.xz` - XZ container support.
- `std.compress.zstd` - Zstandard support.

## Notes

This root page documents the top-level namespace exports. Algorithm-specific APIs live in the child namespaces imported above.
