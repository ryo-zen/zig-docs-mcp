# std.tar

## Overview

`std.tar` reads and writes tar archives for the subset of tar functionality needed by the Zig package manager: regular files, directories, symbolic links, names, sizes, permissions, and common GNU/POSIX pax extensions for long names and metadata.

Source: `/path/to/zig-0.16.0/lib/std/tar.zig`

## Public API

### Writing

- `std.tar.Writer` - tar writer imported from `tar/Writer.zig`.

### Extraction

- `std.tar.extract(io, dir, reader, options)` - extracts a tar stream into a directory.
- `std.tar.pipeToFileSystem` - deprecated alias for `extract`.
- `std.tar.ExtractOptions` - extraction options.
- `std.tar.PipeOptions` - deprecated alias for `ExtractOptions`.

### Iteration and Parsing

- `std.tar.Iterator` - tar entry iterator.
- `std.tar.PaxIterator` - iterator for pax extended-header attributes.
- `std.tar.FileKind` - file kind enum with `.directory`, `.file`, and `.sym_link`.
- `std.tar.Diagnostics` - optional detailed extraction diagnostics.

## ExtractOptions

`ExtractOptions` contains:

- `strip_components` - number of leading path components to skip.
- `mode_mode` - how to apply mode bits from archive entries.
- `exclude_empty_directories` - whether to skip creating empty directories.
- `diagnostics` - optional pointer to a diagnostics collector.

`mode_mode` can be:

- `.ignore` - ignore archive mode values.
- `.executable_bit_only` - copy only the owner executable bit to group and other executable bits.

## Notes

This is not a comprehensive tar implementation. It intentionally focuses on the archive features used by Zig package workflows.
