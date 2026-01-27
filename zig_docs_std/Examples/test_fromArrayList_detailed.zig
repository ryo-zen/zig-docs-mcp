const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(u8) = .{};
    defer list.deinit(allocator);

    std.debug.print("Creating writer from ArrayList...\n", .{});
    var writer = std.Io.Writer.fromArrayList(&list);
    
    std.debug.print("Writer created. Buffer len: {}\n", .{writer.buffer.len});
    std.debug.print("Trying to write...\n", .{});
    
    // Try a simple write
    writer.writeAll("Hello") catch |err| {
        std.debug.print("Error writing: {}\n", .{err});
        return err;
    };
    
    std.debug.print("Write succeeded! Flushing...\n", .{});
    writer.flush() catch |err| {
        std.debug.print("Error flushing: {}\n", .{err});
        return err;
    };
    
    std.debug.print("Flush succeeded! ArrayList items: {s}\n", .{list.items});
}
