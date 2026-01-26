# std.Io.net.IncomingMessage

### Fields

    from: IpAddress

Populated by receive functions.

    data: []u8

Populated by receive functions, points into the caller-supplied buffer.

    control: []u8

Supplied by caller before calling receive functions; mutated by receive functions.

    flags: Flags

Populated by receive functions.

## Types

- Flags

## Values

|  |  |  |
|----|----|----|
| init | `IncomingMessage` | Useful for initializing before calling `receiveManyTimeout`. |
