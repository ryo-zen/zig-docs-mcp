# std.Io.Select

## Parameters

    U: type

### Fields

    io: Io

    group: Group

    queue: Queue(U)

    outstanding: usize

## Types

- Field

## Values

|       |     |     |
|-------|-----|-----|
| Union |     |     |

## Functions

`pub fn async( s: *S, comptime field: Field, function: anytype, args: std.meta.ArgsTuple(@TypeOf(function)), ) void`  
Calls `function` with `args` asynchronously. The resource spawned is owned by the select.

`pub fn await(s: *S) Cancelable!U`  
Blocks until another task of the select finishes.

`pub fn cancel(s: *S) void`  
Equivalent to `wait` but requests cancelation on all remaining tasks owned by the select.

`pub fn init(io: Io, buffer: []U) S`  
