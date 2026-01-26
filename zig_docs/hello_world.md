# Hello World §

hello.zig

    ```zig
    const std = @import("std");
    
    pub fn main() !void {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("Hello, {s}!\n", .{"world"});
    }
    ```

Shell

    ```
    $ zig build-exe hello.zig
    $ ./hello
    Hello, world!
    
    ```

Most of the time, it is more appropriate to write to stderr rather than stdout, and whether or not the message is successfully written to the stream is irrelevant. For this common case, there is a simpler API: 

hello_again.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        std.debug.print("Hello, world!\n", .{});
    }
    ```

Shell

    ```
    $ zig build-exe hello_again.zig
    $ ./hello_again
    Hello, world!
    
    ```

In this case, the `!` may be omitted from the return type of `main` because no errors are returned from the function. 

See also:

  * Values
  * Tuples
  * @import
  * Errors
  * Entry Point
  * Source Encoding
  * try