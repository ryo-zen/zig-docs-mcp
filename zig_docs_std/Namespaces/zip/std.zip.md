# std.zip

## Overview

`std.zip` contains ZIP file format structures, signature constants, decompression support, iteration, diagnostics, and extraction helpers.

Source: `/path/to/zig-0.16.0/lib/std/zip.zig`

## Public API

### Compression and Extra Headers

- `std.zip.CompressionMethod` - ZIP compression method enum. Known values include `.store` and `.deflate`.
- `std.zip.ExtraHeader` - ZIP extra-header enum. Known value `.zip64_info`.
- `std.zip.Decompress` - reader wrapper for stored or deflated file data.

### Signatures

- `std.zip.central_file_header_sig`
- `std.zip.local_file_header_sig`
- `std.zip.end_record_sig`
- `std.zip.end_record64_sig`
- `std.zip.end_locator64_sig`

### Format Structures

- `std.zip.LocalFileHeader`
- `std.zip.CentralDirectoryFileHeader`
- `std.zip.EndRecord64`
- `std.zip.EndLocator64`
- `std.zip.EndRecord`

### Archive Processing

- `std.zip.Iterator` - iterates ZIP entries.
- `std.zip.Diagnostics` - optional diagnostics collector.
- `std.zip.ExtractOptions` - extraction options.
- `std.zip.extract(dest, fr, options)` - extracts entries from a ZIP file reader into a destination directory.

## Notes

The implementation follows the ZIP file format specification and uses `std.compress.flate` for deflate-compressed entries.
