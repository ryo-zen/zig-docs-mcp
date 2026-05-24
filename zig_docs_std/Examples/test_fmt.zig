const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const str = try std.fmt.allocPrintSentinel(allocator, "Hello {s}", .{"World"}, 0);
    defer allocator.free(str);

    std.debug.print("Str: {s}, len: {}, sentinel: {d}\n", .{str, str.len, str[str.len]});
}
