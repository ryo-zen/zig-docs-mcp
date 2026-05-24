const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(allocator);

    try list.appendSlice(allocator, &[_]i32{ 10, 20, 30, 40, 50 });
    std.debug.print("Initial: {any}\n", .{list.items});

    // Pop last element
    const last = list.pop();
    std.debug.print("Popped: {?}, Remaining: {any}\n", .{ last, list.items });

    // Ordered remove (maintains order, O(N))
    const removed1 = list.orderedRemove(1);
    std.debug.print("orderedRemove(1) returned {}, List: {any}\n", .{ removed1, list.items });

    // Swap remove (faster, O(1), doesn't maintain order)
    const removed2 = list.swapRemove(1);
    std.debug.print("swapRemove(1) returned {}, List: {any}\n", .{ removed2, list.items });

    // Get last without removing
    const peek = list.getLast();
    std.debug.print("getLast: {}, List still has: {any}\n", .{ peek, list.items });
}
