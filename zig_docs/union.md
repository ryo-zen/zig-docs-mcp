# union

A bare `union` defines a set of possible types that a value
can be as a list of fields. Only one field can be active at a time.
The in-memory representation of bare unions is not guaranteed.
Bare unions cannot be used to reinterpret memory. For that, use [@ptrCast](#ptrCast),
or use an [extern union](#extern-union) or a [packed union](#packed-union) which have
guaranteed in-memory layout.
[Accessing the non-active field](#Wrong-Union-Field-Access) is
safety-checked [Illegal Behavior](#Illegal-Behavior):

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
Shell$ zig test test_wrong_union_access.zig
1/1 test_wrong_union_access.test.simple union...thread 3446733 panic: access of union field 'float' while field 'int' is active
/home/ci/zig-bootstrap/zig/doc/langref/test_wrong_union_access.zig:8:12: 0x103f042 in test.simple union (test_wrong_union_access.zig)
    payload.float = 12.34;
     ^
/home/ci/zig-bootstrap/out/host/lib/zig/compiler/test_runner.zig:255:25: 0x11d0e22 in mainTerminal (test_runner.zig)
  if (test_fn.func()) |_| {
                  ^
/home/ci/zig-bootstrap/out/host/lib/zig/compiler/test_runner.zig:70:28: 0x11cacd2 in main (test_runner.zig)
  return mainTerminal(init);
                     ^
/home/ci/zig-bootstrap/out/host/lib/zig/std/start.zig:680:88: 0x11c7347 in callMain (std.zig)
    if (fn_info.params[0].type.? == std.process.Init.Minimal) return wrapMain(root.main(.{
                                                                                 ^
/home/ci/zig-bootstrap/out/host/lib/zig/std/start.zig:190:5: 0x11c6d71 in _start (std.zig)
    asm volatile (switch (native_arch) {
    ^
error: the following test command terminated with signal ABRT:
/home/ci/zig-bootstrap/out/zig-local-cache/o/81a9b8d89aaa821b00a5ffb17b3ec9a2/test --seed=0xb72a27db

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
Shell$ zig test test_simple_union.zig
1/1 test_simple_union.test.simple union...OK
All 1 tests passed.

In order to use [switch](#switch) with a union, it must be a [Tagged union](#Tagged-union).

To initialize a union when the tag is a [comptime](#comptime)-known name, see [@unionInit](#unionInit).

## [Tagged union](#toc-Tagged-union) §

Unions can be declared with an enum tag type.
This turns the union into a *tagged* union, which makes it eligible
to use with [switch](#switch) expressions. When switching on tagged unions,
the tag value can be obtained using an additional capture.
Tagged unions coerce to their tag type: [Type Coercion: Unions and Enums](#Type-Coercion-Unions-and-Enums).

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

    switch (c) {
  .ok => |_, tag| {
      // Because we're in the '.ok' prong, 'tag' is compile-time known to be '.ok':
      comptime std.debug.assert(tag == .ok);
  },
  .not_ok => unreachable,
    }
}

test "get tag type" {
    try expect(std.meta.Tag(ComplexType) == ComplexTypeTag);
}
```
Shell$ zig test test_tagged_union.zig
1/2 test_tagged_union.test.switch on tagged union...OK
2/2 test_tagged_union.test.get tag type...OK
All 2 tests passed.

In order to modify the payload of a tagged union in a switch expression,
place a `*` before the variable name to make it a pointer:

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
Shell$ zig test test_switch_modify_tagged_union.zig
1/1 test_switch_modify_tagged_union.test.modify tagged union in switch...OK
All 1 tests passed.

Unions can be made to infer the enum tag type.
Further, unions can have methods just like structs and enums.

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
Shell$ zig test test_union_method.zig
1/1 test_union_method.test.union method...OK
All 1 tests passed.

Unions with inferred enum tag types can also assign ordinal values to their inferred tag.
This requires the tag to specify an explicit integer type.
[@intFromEnum](#intFromEnum) can be used to access the ordinal value corresponding to the active field.

test_tagged_union_with_tag_values.zig
```zig
const std = @import("std");
const expect = std.testing.expect;

const Tagged = union(enum(u32)) {
    int: i64 = 123,
    boolean: bool = 67,
};

test "tag values" {
    const int: Tagged = .{ .int = -40 };
    try expect(@intFromEnum(int) == 123);

    const boolean: Tagged = .{ .boolean = false };
    try expect(@intFromEnum(boolean) == 67);
}
```
Shell$ zig test test_tagged_union_with_tag_values.zig
1/1 test_tagged_union_with_tag_values.test.tag values...OK
All 1 tests passed.

[@tagName](#tagName) can be used to return a [comptime](#comptime)
`[:0]const u8` value representing the field name:

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
Shell$ zig test test_tagName.zig
1/1 test_tagName.test.@tagName...OK
All 1 tests passed.

## [extern union](#toc-extern-union) §

An `extern union` has memory layout guaranteed to be compatible with
the target C ABI.

See also:

- [extern struct](#extern-struct)

## [packed union](#toc-packed-union) §

A `packed union` has well-defined in-memory layout and is eligible
    to be in a [packed struct](#packed-struct).

All fields in a packed union must have the same [@bitSizeOf](#bitSizeOf).

## [Anonymous Union Literals](#toc-Anonymous-Union-Literals) §

[Anonymous Struct Literals](#Anonymous-Struct-Literals) syntax can be used to initialize unions without specifying
the type:

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
Shell$ zig test test_anonymous_union.zig
1/1 test_anonymous_union.test.anonymous union literal syntax...OK
All 1 tests passed.
