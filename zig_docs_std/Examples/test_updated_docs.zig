const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Testing Updated Documentation Examples ===\n\n", .{});

    // Test Example 3: ArrayList with Allocating writer
    std.debug.print("Test: ArrayList with Allocating Writer\n", .{});
    {
        var list: std.ArrayList(u8) = .empty;

        // Use Writer.Allocating for dynamic growth
        var allocating_writer = std.Io.Writer.Allocating.fromArrayList(allocator, &list);

        try allocating_writer.writer.print("Formatted: {d:0>4}\n", .{42});
        try allocating_writer.writer.writeAll("More data\n");
        try allocating_writer.writer.flush();

        // Convert back to ArrayList when done
        var result = allocating_writer.writer.toArrayList();
        defer result.deinit(allocator);

        std.debug.print("ArrayList contents:\n{s}", .{result.items});
        std.debug.print("✅ PASS\n\n", .{});
    }

    // Test Pattern 2: Building strings dynamically
    std.debug.print("Test: Pattern 2 - Building strings dynamically\n", .{});
    {
        var list: std.ArrayList(u8) = .empty;

        // Use Allocating writer for dynamic growth
        var allocating_writer = std.Io.Writer.Allocating.fromArrayList(allocator, &list);
        try allocating_writer.writer.print("Line {}\n", .{1});
        try allocating_writer.writer.print("Line {}\n", .{2});
        try allocating_writer.writer.flush();

        // Convert back to ArrayList
        var result = allocating_writer.writer.toArrayList();
        defer result.deinit(allocator);

        std.debug.print("Dynamic string:\n{s}", .{result.items});

        // Or use the simpler std.fmt.allocPrint for single-shot formatting
        const simple = try std.fmt.allocPrint(allocator, "Line {}\nLine {}\n", .{1, 2});
        defer allocator.free(simple);

        std.debug.print("Using allocPrint:\n{s}", .{simple});
        std.debug.print("✅ PASS\n\n", .{});
    }

    // Test fromArrayList (fixed buffer behavior)
    std.debug.print("Test: fromArrayList (fixed buffer - takes ownership)\n", .{});
    {
        var list: std.ArrayList(u8) = .empty;
        try list.ensureTotalCapacity(allocator, 1024);  // Pre-allocate

        std.debug.print("List capacity before: {}\n", .{list.capacity});
        var writer = std.Io.Writer.fromArrayList(&list);  // list is now empty
        std.debug.print("List capacity after fromArrayList: {}\n", .{list.capacity});
        std.debug.print("Writer buffer len: {}\n", .{writer.buffer.len});

        // Can only write up to pre-allocated size
        try writer.writeAll("Fixed buffer data\n");
        try writer.flush();

        std.debug.print("Written to fixed buffer: {s}", .{writer.buffered()});

        // Convert back to ArrayList
        var result = writer.toArrayList();
        defer result.deinit(allocator);

        std.debug.print("✅ PASS\n\n", .{});
    }

    std.debug.print("=== All Updated Documentation Examples Work! ===\n", .{});
}
