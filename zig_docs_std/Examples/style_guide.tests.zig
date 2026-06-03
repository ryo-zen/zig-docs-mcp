// Representative tests for zig_docs/style_guide.md examples.
// Run with:
//   zig test zig_docs_std/Examples/style_guide.tests.zig

const std = @import("std");
const testing = std.testing;

pub const json = struct {
    pub const JsonValue = union(enum) {
        number: f64,
        boolean: bool,
    };
};

test "fully qualified name includes redundant namespace segment" {
    try testing.expectEqualStrings(
        "style_guide.tests.json.JsonValue",
        @typeName(json.JsonValue),
    );
}

const TypeName = struct {};
const PrimitiveTypeAlias = f32;
const StructName = struct {
    field: i32,
};
const StructAlias = StructName;
const functionAlias = functionName;

fn functionName(param_name: TypeName) void {
    _ = param_name;
}

fn List(comptime ChildType: type, comptime fixed_size: usize) type {
    return struct {
        items: [fixed_size]ChildType,
    };
}

fn ListTemplateFunction(comptime ChildType: type, comptime fixed_size: usize) type {
    return List(ChildType, fixed_size);
}

fn ShortList(comptime T: type, comptime n: usize) type {
    return struct {
        field_name: [n]T,
        fn methodName() void {}
    };
}

const xml_document =
    \\<?xml version="1.0" encoding="UTF-8"?>
    \\<document>
    \\</document>
;

const XmlParser = struct {
    field: i32,
};

fn readU32Be() u32 {
    return 0x12345678;
}

test "style guide naming examples compile and preserve expected types" {
    const const_name = 42;
    var global_var: i32 = undefined;
    global_var = const_name;

    try testing.expectEqual(@as(i32, 42), global_var);
    try testing.expectEqual(f32, PrimitiveTypeAlias);
    try testing.expectEqual(StructName, StructAlias);

    functionAlias(.{});

    const ListType = ListTemplateFunction(u8, 3);
    const list = ListType{ .items = .{ 1, 2, 3 } };
    try testing.expectEqual([3]u8{ 1, 2, 3 }, list.items);

    const Short = ShortList(u16, 2);
    const short = Short{ .field_name = .{ 5, 8 } };
    Short.methodName();
    try testing.expectEqual([2]u16{ 5, 8 }, short.field_name);

    const parser = XmlParser{ .field = 7 };
    try testing.expectEqual(@as(i32, 7), parser.field);
    try testing.expect(std.mem.startsWith(u8, xml_document, "<?xml"));
    try testing.expect(std.mem.endsWith(u8, xml_document, "</document>"));
    try testing.expectEqual(@as(u32, 0x12345678), readU32Be());
}
