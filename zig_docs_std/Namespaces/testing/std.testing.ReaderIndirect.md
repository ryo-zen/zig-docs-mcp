# std.testing.ReaderIndirect

A `Io.Reader` that gets its data from another `Io.Reader`, and always writes to its own buffer (and returns 0) during `stream` and `readVec`.

### Fields

    in: *Io.Reader

    interface: Io.Reader

## Functions

`pub fn init(in: *Io.Reader, buffer: []u8) ReaderIndirect`  
