# std.log.Level

## Overview

`std.log.Level` defines log severity and filtering priority.

Higher-priority levels are always included when a lower-priority threshold is selected (for example, `.info` includes `.warn` and `.err`).

### Fields

    err

Error: something has gone wrong. This might be recoverable or might be followed by the program exiting.

    warn

Warning: it is uncertain if something has gone wrong or not, but the circumstances would be worth investigating.

    info

Info: general messages about the state of the program.

    debug

Debug: messages only useful for debugging.

## Functions

`pub fn asText(comptime self: Level) []const u8`  
Returns a string literal of the given level in full text form.

## Usage Notes

- Typical ordering is `.err` > `.warn` > `.info` > `.debug`.
- Used by `std.log.logEnabled` and custom `logFn` implementations.
