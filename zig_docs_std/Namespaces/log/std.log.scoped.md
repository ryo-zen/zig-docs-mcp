# std.log.scoped

Returns a scoped logging namespace that logs all messages using the scope provided here.

## Parameters

    scope: @EnumLiteral()

## Functions

`pub fn debug( comptime format: []const u8, args: anytype, ) void`  
Log a debug message. This log level is intended to be used for messages which are only useful for debugging.

`pub fn err( comptime format: []const u8, args: anytype, ) void`  
Log an error message. This log level is intended to be used when something has gone wrong. This might be recoverable or might be followed by the program exiting.

`pub fn info( comptime format: []const u8, args: anytype, ) void`  
Log an info message. This log level is intended to be used for general messages about the state of the program.

`pub fn warn( comptime format: []const u8, args: anytype, ) void`  
Log a warning message. This log level is intended to be used if it is uncertain whether something has gone wrong or not, but the circumstances would be worth investigating.
