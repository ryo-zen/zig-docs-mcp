const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Performance tip: Pre-allocate and use AssumeCapacity variants
    const num_items = 10000;

    var list = try std.ArrayList(i32).initCapacity(allocator, num_items);
    defer list.deinit(allocator);

    std.debug.print("Pre-allocated capacity for {} items\n", .{num_items});

    // Fast path: No error handling or capacity checks
    var i: i32 = 0;
    while (i < num_items) : (i += 1) {
        list.appendAssumeCapacity(i);
    }

    std.debug.print("Appended {} items without reallocation\n", .{list.items.len});

    // Performance tip: swapRemove is O(1) vs orderedRemove O(N)
    // Remove every other element using swapRemove (order doesn't matter)
    var idx: usize = 0;
    const initial_len = list.items.len;
    while (idx < list.items.len) {
        _ = list.swapRemove(idx);
        idx += 1;
    }

    std.debug.print("Removed {} items using swapRemove (O(1) per remove)\n", .{initial_len / 2});
    std.debug.print("Remaining items: {}\n", .{list.items.len});

    // Performance tip: clearRetainingCapacity to reuse allocation
    list.clearRetainingCapacity();
    std.debug.print("Cleared list but kept capacity: {}\n", .{list.capacity});

    // Reuse the allocation
    for (0..100) |j| {
        list.appendAssumeCapacity(@intCast(j));
    }
    std.debug.print("Reused allocation for {} new items\n", .{list.items.len});
}
