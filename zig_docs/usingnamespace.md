# usingnamespace §

`usingnamespace` is a declaration that mixes all the public declarations of the operand, which must be a struct, union, enum, or opaque, into the namespace:   
  
test_usingnamespace.zig

    ```zig
    test "using std namespace" {
        const S = struct {
            usingnamespace @import("std");
        };
        try S.testing.expect(true);
    }
    ```

Shell

    ```
    $ zig test test_usingnamespace.zig
    1/1 test_usingnamespace.test.using std namespace...OK
    All 1 tests passed.
    
    ```

`usingnamespace` has an important use case when organizing the public API of a file or package. For example, one might have `c.zig` with all of the C imports: 

c.zig

    ```zig
    pub usingnamespace @cImport({
        @cInclude("epoxy/gl.h");
        @cInclude("GLFW/glfw3.h");
        @cDefine("STBI_ONLY_PNG", "");
        @cDefine("STBI_NO_STDIO", "");
        @cInclude("stb_image.h");
    });
    ```

The above example demonstrates using `pub` to qualify the `usingnamespace` additionally makes the imported declarations `pub`. This can be used to forward declarations, giving precise control over what declarations a given file exposes.