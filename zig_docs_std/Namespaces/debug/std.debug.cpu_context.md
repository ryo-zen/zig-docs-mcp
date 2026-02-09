# std.debug.cpu_context

## Types

- Native

## Functions

`pub fn fromPosixSignalContext(ctx_ptr: ?*const anyopaque) ?Native`  

`pub fn fromWindowsContext(ctx: *const std.os.windows.CONTEXT) Native`  

## Error Sets

- DwarfRegisterError
