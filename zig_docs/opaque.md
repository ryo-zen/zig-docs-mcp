# opaque §

`opaque {}` declares a new type with an unknown (but non-zero) size and alignment. It can contain declarations the same as structs, unions, and enums. 

This is typically used for type safety when interacting with C code that does not expose struct details. Example: 

test_opaque.zig

    ```zig
    const Derp = opaque {};
    const Wat = opaque {};
    
    extern fn bar(d: *Derp) void;
    fn foo(w: *Wat) callconv(.C) void {
        bar(w);
    }
    
    test "call foo" {
        foo(undefined);
    }
    ```

Shell

    ```zig
    $ zig test test_opaque.zig
    /home/andy/dev/zig/doc/langref/test_opaque.zig:6:9: error: expected type '*test_opaque.Derp', found '*test_opaque.Wat'
        bar(w);
            ^
    /home/andy/dev/zig/doc/langref/test_opaque.zig:6:9: note: pointer type child 'test_opaque.Wat' cannot cast into pointer type child 'test_opaque.Derp'
    /home/andy/dev/zig/doc/langref/test_opaque.zig:2:13: note: opaque declared here
    const Wat = opaque {};
                ^~~~~~~~~
    /home/andy/dev/zig/doc/langref/test_opaque.zig:1:14: note: opaque declared here
    const Derp = opaque {};
                 ^~~~~~~~~
    /home/andy/dev/zig/doc/langref/test_opaque.zig:4:18: note: parameter type declared here
    extern fn bar(d: *Derp) void;
                     ^~~~~
    referenced by:
        test.call foo: /home/andy/dev/zig/doc/langref/test_opaque.zig:10:8

    ```