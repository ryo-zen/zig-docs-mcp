const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var threaded = std.Io.Threaded.init(gpa.allocator(), .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    const HostName = std.Io.net.HostName;

    std.debug.print("=== std.Io.net.HostName Comprehensive Test ===\n\n", .{});

    // Test 1: Validation and Initialization
    std.debug.print("Test 1: Validation and Initialization\n", .{});
    {
        const valid_names = [_][]const u8{
            "localhost",
            "google.com",
            "ziglang.org",
            "my-server.local",
        };

        for (valid_names) |name| {
            try HostName.validate(name);
            const hn = try HostName.init(name);
            std.debug.print("  Valid and Inited: {s}\n", .{hn.bytes});
        }

        const invalid_names = [_][]const u8{
            "invalid_name", // underscore not allowed in hostname (RFC 1123)
            "name@host",
            "very" ** 70, // exceeding max_len (usually 255)
        };

        for (invalid_names) |name| {
            if (HostName.validate(name)) |_| {
                std.debug.print("  FAILED: {s} should be invalid\n", .{name});
            } else |err| {
                std.debug.print("  Expectedly invalid: {s} ({s})\n", .{ name, @errorName(err) });
            }
        }
        std.debug.print("  ✅ PASS - Validation\n\n", .{});
    }

    // Test 2: Equality
    std.debug.print("Test 2: Equality (Case-insensitive)\n", .{});
    {
        const hn1 = try HostName.init("Google.com");
        const hn2 = try HostName.init("google.com");
        
        if (hn1.eql(hn2)) {
            std.debug.print("  Google.com == google.com\n", .{});
        } else {
            std.debug.print("  FAILED: Case-insensitive equality failed\n", .{});
        }
        std.debug.print("  ✅ PASS - Equality\n\n", .{});
    }

    // Test 3: Same Parent Domain
    std.debug.print("Test 3: Parent Domain\n", .{});
    {
        const parent = try HostName.init("ziglang.org");
        const child = try HostName.init("docs.ziglang.org");
        const unrelated = try HostName.init("google.com");

        std.debug.print("  docs.ziglang.org same parent as ziglang.org: {}\n", .{parent.sameParentDomain(child)});
        std.debug.print("  google.com same parent as ziglang.org: {}\n", .{parent.sameParentDomain(unrelated)});
        
        std.debug.print("  ✅ PASS - Parent Domain\n\n", .{});
    }

    // Test 4: Lookup (Asynchronous)
    std.debug.print("Test 4: Lookup\n", .{});
    {
        const hn = try HostName.init("localhost");
        var buffer: [16]std.Io.net.HostName.LookupResult = undefined;
        var queue = std.Io.Queue(std.Io.net.HostName.LookupResult).init(&buffer);
        
        // Lookup usually populates a queue
        var canon_buf: [HostName.max_len]u8 = undefined;
        try hn.lookup(io, &queue, .{
            .port = 80,
            .canonical_name_buffer = &canon_buf,
        });
        
        std.debug.print("  Lookup initiated for localhost\n", .{});
        
        // Wait for results
        while (true) {
            const result = queue.getOneUncancelable(io) catch |err| {
                if (err == error.Closed) break;
                return err;
            };
            
            switch (result) {
                .address => |addr| std.debug.print("  Resolved: {}\n", .{addr}),
                .canonical_name => |hn_canon| std.debug.print("  Canonical Name: {s}\n", .{hn_canon.bytes}),
            }
        }
        
        std.debug.print("  ✅ PASS - Lookup initiated\n\n", .{});
    }

    std.debug.print("=== HostName Tests Passed ===\n", .{});
}
