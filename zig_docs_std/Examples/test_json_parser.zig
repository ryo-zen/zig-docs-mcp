const std = @import("std");
const JsonParser = @import("test_json_parser_impl.zig").JsonParser;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Simple JSON string
    const json_str = "{\"name\": \"Zei\", \"age\": 42, \"active\": true}";

    // Test 1: Parse from slice into a struct
    const Person = struct {
        name: []const u8,
        age: u32,
        active: bool,
    };
    const parsed_person = try JsonParser.parseFromSlice(Person, allocator, json_str);
    defer parsed_person.deinit();
    const person = parsed_person.value;
    std.debug.print("Parsed person: name={s}, age={}, active={}\n", .{ person.name, person.age, person.active });

    // Test 2: Parse into std.json.Value (dynamic)
    const parsed_value = try JsonParser.parseFromSlice(std.json.Value, allocator, json_str);
    defer parsed_value.deinit();
    const value = parsed_value.value;

    // Verify value is object and contains expected fields
    const obj = value.object;
    // Access fields safely
    const name_val = obj.get("name").?;
    const age_val = obj.get("age").?;
    const active_val = obj.get("active").?;

    // Simple assertions
    if (!std.mem.eql(u8, name_val.string, "Zei")) return error.TestFailed;
    if (age_val.integer != 42) return error.TestFailed;
    if (active_val.bool != true) return error.TestFailed;

    // Test 3: Stringify a struct back to JSON
    const Place = struct {
        lat: f32,
        long: f32,
    };
    const place: Place = .{
        .lat = 51.997664,
        .long = -0.740687,
    };
    const json_output = try JsonParser.stringify(place, allocator);
    defer allocator.free(json_output);
    std.debug.print("Stringified JSON: {s}\n", .{json_output});

    // Verify it's valid JSON by parsing it back
    const reparsed = try JsonParser.parseFromSlice(Place, allocator, json_output);
    defer reparsed.deinit();
    if (reparsed.value.lat != place.lat) return error.TestFailed;
    if (reparsed.value.long != place.long) return error.TestFailed;

    // All good
    std.debug.print("✅ JSON parser test passed (parse + stringify)\n", .{});
}
