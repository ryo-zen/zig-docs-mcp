const std = @import("std");
const JsonParser = @import("test_json_parser_impl.zig").JsonParser;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Setup Io (required for 0.16 filesystem)
    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    // Open the sample JSON file
    const dir = std.Io.Dir.cwd();
    const file = try dir.openFile(io, "tests_dev/v016_Tests/data/sample.json", .{});
    defer file.close(io);

    // Parse the file contents into a generic JSON value
    const parsed = try JsonParser.parseFromFile(std.json.Value, allocator, io, file);
    defer parsed.deinit();

    // Expect an object with specific fields
    const value = parsed.value;
    const obj = value.object;
    // Validate top-level fields
    const version = obj.get("version").?.float;
    if (version != 1.2) return error.TestFailed;

    // Validate nested user object
    const user = obj.get("user").?.object;
    const user_id = user.get("id").?.integer;
    const user_name = user.get("name").?.string;
    if (user_id != 42) return error.TestFailed;
    if (!std.mem.eql(u8, user_name, "Alice")) return error.TestFailed;

    // Roles array
    const roles = user.get("roles").?.array;
    if (roles.items.len != 2) return error.TestFailed;
    if (!std.mem.eql(u8, roles.items[0].string, "admin")) return error.TestFailed;
    if (!std.mem.eql(u8, roles.items[1].string, "editor")) return error.TestFailed;

    // Meta object
    const meta = user.get("meta").?.object;
    const active = meta.get("active").?.bool;
    const last_login = meta.get("last_login").?.string;
    if (active != true) return error.TestFailed;
    if (!std.mem.eql(u8, last_login, "2025-12-31T23:59:59Z")) return error.TestFailed;

    // Transactions array
    const transactions = obj.get("transactions").?.array;
    if (transactions.items.len != 2) return error.TestFailed;
    const tx0 = transactions.items[0].object;
    const txid0 = tx0.get("txid").?.string;
    const amount0 = tx0.get("amount").?.float;
    if (!std.mem.eql(u8, txid0, "a1b2c3")) return error.TestFailed;
    if (amount0 != 123.45) return error.TestFailed;

    // Features should be null
    const features = obj.get("features").?;
    if (features != .null) return error.TestFailed;

    // Tags should be empty array
    const tags = obj.get("tags").?.array;
    if (tags.items.len != 0) return error.TestFailed;

    std.debug.print("✅ Complex file JSON parser test passed\n", .{});
}
