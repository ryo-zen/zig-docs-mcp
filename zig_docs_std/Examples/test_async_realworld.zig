const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

fn juicyMain(gpa: Allocator, io: Io) !void {
    std.debug.print("Simulating real-world async API calls...\n\n", .{});

    // Simulate fetching data from multiple sources concurrently
    var fetch_user = io.async(fetchUserData, .{ gpa, io, 1 });
    defer if (fetch_user.cancel(io)) |data| gpa.free(data) else |_| {};

    var fetch_posts = io.async(fetchUserPosts, .{ gpa, io, 1 });
    defer if (fetch_posts.cancel(io)) |data| gpa.free(data) else |_| {};

    var fetch_comments = io.async(fetchUserComments, .{ gpa, io, 1 });
    defer if (fetch_comments.cancel(io)) |data| gpa.free(data) else |_| {};

    // Wait for all results
    const user = try fetch_user.await(io);
    const posts = try fetch_posts.await(io);
    const comments = try fetch_comments.await(io);

    std.debug.print("\n=== Results ===\n", .{});
    std.debug.print("User:     {s}\n", .{user});
    std.debug.print("Posts:    {s}\n", .{posts});
    std.debug.print("Comments: {s}\n", .{comments});
    std.debug.print("\n✅ All data fetched concurrently in ~1 second!\n", .{});
    std.debug.print("   (Sequential would take ~3 seconds)\n", .{});
}

fn fetchUserData(gpa: Allocator, io: Io, user_id: u32) ![]u8 {
    std.debug.print("Fetching user {}...\n", .{user_id});
    io.sleep(.fromSeconds(1), .awake) catch {};
    return try std.fmt.allocPrint(gpa, "{{\"id\":{},\"name\":\"Alice\"}}", .{user_id});
}

fn fetchUserPosts(gpa: Allocator, io: Io, user_id: u32) ![]u8 {
    std.debug.print("Fetching posts for user {}...\n", .{user_id});
    io.sleep(.fromSeconds(1), .awake) catch {};
    return try std.fmt.allocPrint(gpa, "[{{\"id\":1,\"title\":\"Post by user {}\"}}]", .{user_id});
}

fn fetchUserComments(gpa: Allocator, io: Io, user_id: u32) ![]u8 {
    std.debug.print("Fetching comments for user {}...\n", .{user_id});
    io.sleep(.fromSeconds(1), .awake) catch {};
    return try std.fmt.allocPrint(gpa, "[{{\"comment\":\"Great post!\",\"user\":{}}}]", .{user_id});
}

pub fn main() !void {
    // Set up allocator with leak detection
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer assert(debug_allocator.deinit() == .ok);
    const gpa = debug_allocator.allocator();

    // Set up our I/O implementation
    var threaded = std.Io.Threaded.init(gpa, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    return juicyMain(gpa, io);
}
