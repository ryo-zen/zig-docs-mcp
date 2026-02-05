// Adapter Pattern in Zig
// Shows how to wrap incompatible interfaces to work together

const std = @import("std");

// Example 1: Allocator Adapter (most common in Zig)
// Wrap a general allocator with validation

test "Adapter: Allocator wrapper" {
    std.debug.print("\n🔌 Test: Allocator adapter\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Original allocator
    const base_allocator = gpa.allocator();

    // Adapted allocator with validation
    var validating = std.mem.validationWrap(base_allocator);
    const adapted_allocator = validating.allocator();

    // Same interface, enhanced behavior
    const buffer = try adapted_allocator.alloc(u8, 100);
    defer adapted_allocator.free(buffer);

    try std.testing.expectEqual(100, buffer.len);

    std.debug.print("  ✅ PASS: Allocator adapter adds validation without changing interface\n", .{});
}

// Example 2: Reader Adapter
// Adapt a byte slice to the Reader interface

const SliceReader = struct {
    data: []const u8,
    pos: usize = 0,

    pub fn read(self: *SliceReader, buffer: []u8) !usize {
        const available = self.data.len - self.pos;
        const to_read = @min(buffer.len, available);

        if (to_read == 0) return 0;

        @memcpy(buffer[0..to_read], self.data[self.pos..][0..to_read]);
        self.pos += to_read;

        return to_read;
    }

    // Adapter method: make it compatible with std.io.Reader-like interface
    pub fn reader(self: *SliceReader) Reader {
        return .{
            .context = self,
        };
    }

    const Reader = struct {
        context: *SliceReader,

        pub fn read(self: Reader, buffer: []u8) !usize {
            return self.context.read(buffer);
        }
    };
};

test "Adapter: Byte slice to Reader" {
    std.debug.print("\n🔌 Test: Slice to Reader adapter\n", .{});

    const data = "Hello, World!";
    var slice_reader = SliceReader{ .data = data };

    // Adapt slice to reader interface
    var reader = slice_reader.reader();

    // Use the adapted interface
    var buffer: [5]u8 = undefined;
    const n = try reader.read(&buffer);

    try std.testing.expectEqual(5, n);
    try std.testing.expectEqualStrings("Hello", &buffer);

    std.debug.print("  ✅ PASS: Slice adapted to Reader interface\n", .{});
}

// Example 3: Writer Adapter
// Adapt ArrayList to Writer interface

const ArrayListWriter = struct {
    list: *std.ArrayList(u8),
    allocator: std.mem.Allocator,

    pub fn write(self: ArrayListWriter, bytes: []const u8) !usize {
        try self.list.appendSlice(self.allocator, bytes);
        return bytes.len;
    }

    pub fn writer(self: ArrayListWriter) Writer {
        return .{ .context = self };
    }

    const Writer = struct {
        context: ArrayListWriter,

        pub fn write(self: Writer, bytes: []const u8) !usize {
            return self.context.write(bytes);
        }

        pub fn writeAll(self: Writer, bytes: []const u8) !void {
            _ = try self.write(bytes);
        }

        pub fn print(self: Writer, comptime format: []const u8, args: anytype) !void {
            var buf: [1024]u8 = undefined;
            const result = try std.fmt.bufPrint(&buf, format, args);
            try self.writeAll(result);
        }
    };
};

test "Adapter: ArrayList to Writer" {
    std.debug.print("\n🔌 Test: ArrayList to Writer adapter\n", .{});

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(std.testing.allocator);

    // Adapt ArrayList to Writer interface
    const adapter = ArrayListWriter{
        .list = &list,
        .allocator = std.testing.allocator,
    };
    const writer = adapter.writer();

    // Use writer interface
    try writer.writeAll("Value: ");
    try writer.print("{d}", .{42});

    try std.testing.expectEqualStrings("Value: 42", list.items);

    std.debug.print("  ✅ PASS: ArrayList adapted to Writer interface\n", .{});
}

// Example 4: Legacy API Adapter
// Adapt old C-style API to modern Zig interface

const LegacyProcessor = struct {
    // Old C-style API: error codes, out parameters
    pub fn processData(input: [*c]const u8, input_len: usize, output: [*c]u8, output_size: *usize) c_int {
        if (input_len == 0) return -1;

        // Simple processing: copy and uppercase
        for (0..input_len) |i| {
            output[i] = std.ascii.toUpper(input[i]);
        }
        output_size.* = input_len;

        return 0; // success
    }
};

const ModernProcessor = struct {
    // Modern Zig API: errors, slices
    pub fn process(input: []const u8, output: []u8) ![]u8 {
        if (input.len == 0) return error.EmptyInput;
        if (output.len < input.len) return error.BufferTooSmall;

        // Adapt to legacy API
        var output_size: usize = 0;
        const result = LegacyProcessor.processData(
            input.ptr,
            input.len,
            output.ptr,
            &output_size,
        );

        if (result != 0) return error.ProcessingFailed;

        return output[0..output_size];
    }
};

test "Adapter: Legacy C API to modern Zig" {
    std.debug.print("\n🔌 Test: Legacy API adapter\n", .{});

    var output: [100]u8 = undefined;

    // Use modern interface that adapts legacy API
    const result = try ModernProcessor.process("hello", &output);

    try std.testing.expectEqualStrings("HELLO", result);

    std.debug.print("  ✅ PASS: Legacy C API adapted to idiomatic Zig\n", .{});
}

// Example 5: Interface Adapter with comptime
// Adapt any type with a read() method to a common interface

fn GenericReader(comptime T: type) type {
    return struct {
        context: *T,

        const Self = @This();

        pub fn read(self: Self, buffer: []u8) !usize {
            return self.context.read(buffer);
        }

        pub fn readByte(self: Self) !u8 {
            var byte: [1]u8 = undefined;
            const n = try self.read(&byte);
            if (n == 0) return error.EndOfStream;
            return byte[0];
        }

        pub fn readAll(self: Self, buffer: []u8) !usize {
            var total: usize = 0;
            while (total < buffer.len) {
                const n = try self.read(buffer[total..]);
                if (n == 0) break;
                total += n;
            }
            return total;
        }
    };
}

const SimpleReader = struct {
    data: []const u8,
    pos: usize = 0,

    pub fn read(self: *SimpleReader, buffer: []u8) !usize {
        const available = self.data.len - self.pos;
        const to_read = @min(buffer.len, available);
        if (to_read == 0) return 0;

        @memcpy(buffer[0..to_read], self.data[self.pos..][0..to_read]);
        self.pos += to_read;
        return to_read;
    }
};

test "Adapter: Generic reader adapter with comptime" {
    std.debug.print("\n🔌 Test: Comptime generic adapter\n", .{});

    var simple = SimpleReader{ .data = "test data" };

    // Adapt to generic reader interface
    const reader = GenericReader(SimpleReader){ .context = &simple };

    // Use enhanced interface
    const first_byte = try reader.readByte();
    try std.testing.expectEqual('t', first_byte);

    var buffer: [8]u8 = undefined;
    const n = try reader.readAll(&buffer);
    try std.testing.expectEqual(8, n);
    try std.testing.expectEqualStrings("est data", &buffer);

    std.debug.print("  ✅ PASS: Comptime adapter adds functionality to any reader-like type\n", .{});
}

// Example 6: Multiple Adapter Layers
test "Adapter: Stacking adapters" {
    std.debug.print("\n🔌 Test: Multiple adapter layers\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Layer 1: Base allocator
    const base = gpa.allocator();

    // Layer 2: Add validation
    var validating = std.mem.validationWrap(base);
    const validated = validating.allocator();

    // Layer 3: Could add logging, metrics, etc.
    // Each adapter wraps the previous one

    const buffer = try validated.alloc(u8, 50);
    defer validated.free(buffer);

    try std.testing.expectEqual(50, buffer.len);

    std.debug.print("  ✅ PASS: Adapters can be stacked/composed\n", .{});
}

test "Adapter Pattern: Summary" {
    std.debug.print("\n🔌 Summary: Adapter Pattern in Zig\n", .{});
    std.debug.print("  ✅ Wraps incompatible interfaces to work together\n", .{});
    std.debug.print("  ✅ Very common: allocator wrapping, reader/writer adapters\n", .{});
    std.debug.print("  ✅ Use comptime for zero-cost generic adapters\n", .{});
    std.debug.print("  ✅ Adapters can be stacked for layered functionality\n", .{});
    std.debug.print("  ✅ Useful for legacy API integration\n", .{});
}
