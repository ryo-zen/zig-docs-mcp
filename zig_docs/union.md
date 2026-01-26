# union §

A bare `union` defines a set of possible types that a value can be as a list of fields. Only one field can be active at a time. The in-memory representation of bare unions is not guaranteed. Bare unions cannot be used to reinterpret memory. For that, use @ptrCast, or use an extern union or a packed union which have guaranteed in-memory layout. Accessing the non-active field is safety-checked Illegal Behavior: 

test_wrong_union_access.zig

    ```zig
    const Payload = union {
        int: i64,
        float: f64,
        boolean: bool,
    };
    test "simple union" {
        var payload = Payload{ .int = 1234 };
        payload.float = 12.34;
    }
    ```

Shell

    ```zig
    $ zig test test_wrong_union_access.zig
    1/1 test_wrong_union_access.test.simple union...thread 210915 panic: access of union field 'float' while field 'int' is active
    /home/andy/dev/zig/doc/langref/test_wrong_union_access.zig:8:12: 0x1048a5f in test.simple union (test)
        payload.float = 12.34;
               ^
    /home/andy/dev/zig/lib/compiler/test_runner.zig:214:25: 0x10ef2e5 in mainTerminal (test)
            if (test_fn.func()) |_| {
                            ^
    /home/andy/dev/zig/lib/compiler/test_runner.zig:62:28: 0x10e76cd in main (test)
            return mainTerminal();
                               ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10e6b42 in posixCallMainAndExit (test)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10e671d in _start (test)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    error: the following test command crashed:
    /home/andy/dev/zig/.zig-cache/o/0e2ad1837ee3fe26786cd418343cba9e/test --seed=0xdea5f103
    
    ```

You can activate another field by assigning the entire union:

test_simple_union.zig

    ```zig
    const std = @import("std");
    const expect = std.testing.expect;
    
    const Payload = union {
        int: i64,
        float: f64,
        boolean: bool,
    };
    test "simple union" {
        var payload = Payload{ .int = 1234 };
        try expect(payload.int == 1234);
        payload = Payload{ .float = 12.34 };
        try expect(payload.float == 12.34);
    }
    ```

Shell

    ```
    $ zig test test_simple_union.zig
    1/1 test_simple_union.test.simple union...OK
    All 1 tests passed.
    
    ```

In order to use switch with a union, it must be a Tagged union. 

To initialize a union when the tag is a comptime-known name, see @unionInit. 

### Tagged union §

Unions can be declared with an enum tag type. This turns the union into a _tagged_ union, which makes it eligible to use with switch expressions. Tagged unions coerce to their tag type: Type Coercion: Unions and Enums. 

test_tagged_union.zig

    ```zig
    const std = @import("std");
    const expect = std.testing.expect;
    
    const ComplexTypeTag = enum {
        ok,
        not_ok,
    };
    const ComplexType = union(ComplexTypeTag) {
        ok: u8,
        not_ok: void,
    };
    
    test "switch on tagged union" {
        const c = ComplexType{ .ok = 42 };
        try expect(@as(ComplexTypeTag, c) == ComplexTypeTag.ok);
    
        switch (c) {
            .ok => |value| try expect(value == 42),
            .not_ok => unreachable,
        }
    }
    
    test "get tag type" {
        try expect(std.meta.Tag(ComplexType) == ComplexTypeTag);
    }
    ```

Shell

    ```
    $ zig test test_tagged_union.zig
    1/2 test_tagged_union.test.switch on tagged union...OK
    2/2 test_tagged_union.test.get tag type...OK
    All 2 tests passed.
    
    ```

In order to modify the payload of a tagged union in a switch expression, place a `*` before the variable name to make it a pointer: 

test_switch_modify_tagged_union.zig

    ```zig
    const std = @import("std");
    const expect = std.testing.expect;
    
    const ComplexTypeTag = enum {
        ok,
        not_ok,
    };
    const ComplexType = union(ComplexTypeTag) {
        ok: u8,
        not_ok: void,
    };
    
    test "modify tagged union in switch" {
        var c = ComplexType{ .ok = 42 };
    
        switch (c) {
            ComplexTypeTag.ok => |*value| value.* += 1,
            ComplexTypeTag.not_ok => unreachable,
        }
    
        try expect(c.ok == 43);
    }
    ```

Shell

    ```
    $ zig test test_switch_modify_tagged_union.zig
    1/1 test_switch_modify_tagged_union.test.modify tagged union in switch...OK
    All 1 tests passed.
    
    ```

Unions can be made to infer the enum tag type. Further, unions can have methods just like structs and enums. 

test_union_method.zig

    ```zig
    const std = @import("std");
    const expect = std.testing.expect;
    
    const Variant = union(enum) {
        int: i32,
        boolean: bool,
    
        // void can be omitted when inferring enum tag type.
        none,
    
        fn truthy(self: Variant) bool {
            return switch (self) {
                Variant.int => |x_int| x_int != 0,
                Variant.boolean => |x_bool| x_bool,
                Variant.none => false,
            };
        }
    };
    
    test "union method" {
        var v1: Variant = .{ .int = 1 };
        var v2: Variant = .{ .boolean = false };
        var v3: Variant = .none;
    
        try expect(v1.truthy());
        try expect(!v2.truthy());
        try expect(!v3.truthy());
    }
    ```

Shell

    ```
    $ zig test test_union_method.zig
    1/1 test_union_method.test.union method...OK
    All 1 tests passed.
    
    ```

@tagName can be used to return a comptime `[:0]const u8` value representing the field name: 

test_tagName.zig

    ```zig
    const std = @import("std");
    const expect = std.testing.expect;
    
    const Small2 = union(enum) {
        a: i32,
        b: bool,
        c: u8,
    };
    test "@tagName" {
        try expect(std.mem.eql(u8, @tagName(Small2.a), "a"));
    }
    ```

Shell

    ```
    $ zig test test_tagName.zig
    1/1 test_tagName.test.@tagName...OK
    All 1 tests passed.
    
    ```

### extern union §

An `extern union` has memory layout guaranteed to be compatible with the target C ABI. 

See also:

  * extern struct

### packed union §

A `packed union` has well-defined in-memory layout and is eligible to be in a packed struct.

### Anonymous Union Literals §

Anonymous Struct Literals syntax can be used to initialize unions without specifying the type:

test_anonymous_union.zig

    ```zig
    const std = @import("std");
    const expect = std.testing.expect;
    
    const Number = union {
        int: i32,
        float: f64,
    };
    
    test "anonymous union literal syntax" {
        const i: Number = .{ .int = 42 };
        const f = makeNumber();
        try expect(i.int == 42);
        try expect(f.float == 12.34);
    }
    
    fn makeNumber() Number {
        return .{ .float = 12.34 };
    }
    ```

Shell

    ```
    $ zig test test_anonymous_union.zig
    1/1 test_anonymous_union.test.anonymous union literal syntax...OK
    All 1 tests passed.
    
    ```