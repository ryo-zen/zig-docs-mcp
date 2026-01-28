const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("🔍 Testing SINGLE LINE spinner... (Press Ctrl+C to stop)\n", .{});

    // Full 20-frame animation for smooth motion
    const blockchain_frames = [_][]const u8{
        "░░░░░░░░░▓",
        "░░░░░░░░▓░",
        "░░░░░░░▓░░",
        "░░░░░░▓░░░",
        "░░░░░▓░░░░",
        "░░░░▓░░░░░",
        "░░░▓░░░░░░",
        "░░▓░░░░░░░",
        "░▓░░░░░░░░",
        "▓░░░░░░░░░",
        "▓░░░░░░░░░",
        "░▓░░░░░░░░",
        "░░▓░░░░░░░",
        "░░░▓░░░░░░",
        "░░░░▓░░░░░",
        "░░░░░▓░░░░",
        "░░░░░░▓░░░",
        "░░░░░░░▓░░",
        "░░░░░░░░▓░",
        "░░░░░░░░░▓",
    };

    var frame_counter: u32 = 0;
    var height: u32 = 25;
    const peers: u32 = 1;
    var mempool: u32 = 1;
    var hashrate: f64 = 150.5;

    while (true) {
        const frame = blockchain_frames[frame_counter % blockchain_frames.len];

        // Simulate dynamic values changing
        if (frame_counter % 20 == 0) height += 1;  // New block every 20 frames (4 seconds)
        if (frame_counter % 5 == 0) mempool = (mempool + 1) % 100;  // Mempool changes frequently

        // Simulate slight hashrate fluctuation for realism
        const hashrate_variation = @as(f64, @floatFromInt((frame_counter % 10))) * 0.3 - 1.5;
        hashrate = 150.5 + hashrate_variation;

        // Single line: spinner + status on same line
        if (frame_counter == 0) {
            // First time: just print
            try stdout.print("{s} Block: {d: >3} | Peers: {d: >2} | Mempool: {d: >3} | Hash: {d: >5.1} H/s", .{ frame, height, peers, mempool, hashrate });
        } else {
            // Update: carriage return, clear entire line FIRST, then print (prevents white streak)
            try stdout.print("\r\x1b[2K{s} Block: {d: >3} | Peers: {d: >2} | Mempool: {d: >3} | Hash: {d: >5.1} H/s", .{ frame, height, peers, mempool, hashrate });
        }

        frame_counter += 1;
        std.time.sleep(100 * std.time.ns_per_ms);  // 100ms = 10 FPS for smoother animation
    }
}
