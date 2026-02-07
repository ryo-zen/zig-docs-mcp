# std.log.Level

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
