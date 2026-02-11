# std.debug.FormatStackTrace

## Overview

`std.debug.FormatStackTrace` is a small formatter object that renders a `StackTrace` through Zig's formatting/writer pipeline.

Use it when you want stack-trace output integrated into your own writer flow instead of directly printing to stderr.

### Fields

    stack_trace: StackTrace

    terminal_mode: Io.Terminal.Mode = .no_color

## Functions

`pub fn format(fst: FormatStackTrace, writer: *Writer) Writer.Error!void`  
Writes the formatted stack trace to `writer`, honoring `terminal_mode` for color behavior.

## Usage Notes

- This is useful for log sinks, test output buffers, and custom crash reporters.
- Set `terminal_mode` explicitly if your writer targets a terminal with color support.
- For direct stderr printing, `std.debug.dumpCurrentStackTrace` is simpler.
