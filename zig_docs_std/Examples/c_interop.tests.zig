const std = @import("std");

// ============================================================================
// C ABI Type Validation
// ============================================================================

const CPoint = extern struct {
    x: c_int,
    y: c_int,
};

const CRect = extern struct {
    top: c_int,
    left: c_int,
    bottom: c_int,
    right: c_int,
};

test "extern struct layout validation" {
    // Validate CPoint
    try std.testing.expectEqual(@sizeOf(c_int) * 2, @sizeOf(CPoint));
    try std.testing.expectEqual(@alignOf(c_int), @alignOf(CPoint));
    try std.testing.expectEqual(0, @offsetOf(CPoint, "x"));
    try std.testing.expectEqual(@sizeOf(c_int), @offsetOf(CPoint, "y"));

    // Validate CRect
    try std.testing.expectEqual(@sizeOf(c_int) * 4, @sizeOf(CRect));
    try std.testing.expectEqual(0, @offsetOf(CRect, "top"));
    try std.testing.expectEqual(@sizeOf(c_int) * 3, @offsetOf(CRect, "right"));
}

test "C type primitive sizes" {
    // These should compile on all platforms
    _ = @sizeOf(c_char);
    _ = @sizeOf(c_short);
    _ = @sizeOf(c_int);
    _ = @sizeOf(c_long);
    _ = @sizeOf(c_longlong);

    // c_long width varies by platform
    const is_64bit = @sizeOf(usize) == 8;
    if (is_64bit) {
        try std.testing.expect(@sizeOf(c_long) >= 4);
    }
}

// ============================================================================
// Null-Terminated String Handling
// ============================================================================

test "string literal is already null-terminated" {
    const str: [:0]const u8 = "hello";

    try std.testing.expectEqual(@as(usize, 5), str.len);
    try std.testing.expectEqual(@as(u8, 0), str[str.len]); // Verify null terminator
}

test "dynamic string with allocPrint + dupeZ" {
    const allocator = std.testing.allocator;

    // Step 1: Create string
    const str = try std.fmt.allocPrint(allocator, "value: {}", .{42});
    defer allocator.free(str);

    // Step 2: Add null terminator
    const str_z = try allocator.dupeZ(u8, str);
    defer allocator.free(str_z);

    // Verify
    try std.testing.expectEqualStrings("value: 42", str_z);
    try std.testing.expectEqual(@as(u8, 0), str_z[str_z.len]); // Null terminator present
}

test "fixed-size buffer with sentinel" {
    var buffer: [256:0]u8 = undefined;
    const str = try std.fmt.bufPrint(&buffer, "value: {}", .{42});
    buffer[str.len] = 0; // Add null terminator

    try std.testing.expectEqualStrings("value: 42", str);
    try std.testing.expectEqual(@as(u8, 0), buffer[str.len]);
}

test "slice to sentinel-terminated with dupeZ" {
    const allocator = std.testing.allocator;

    const slice: []const u8 = "test data";
    const terminated: [:0]const u8 = try allocator.dupeZ(u8, slice);
    defer allocator.free(terminated);

    try std.testing.expectEqualStrings("test data", terminated);
    try std.testing.expectEqual(@as(u8, 0), terminated[terminated.len]);
}

test "sentinel-terminated array literal" {
    const arr: [5:0]u8 = [_:0]u8{ 'h', 'e', 'l', 'l', 'o' };
    const as_slice: [:0]const u8 = &arr;

    try std.testing.expectEqual(@as(usize, 5), as_slice.len);
    try std.testing.expectEqual(@as(u8, 0), as_slice[5]);
}

// ============================================================================
// C Pointer Types ([*c]T)
// ============================================================================

test "[*c]T basic usage and null handling" {
    var value: c_int = 42;
    const c_ptr: [*c]c_int = &value;

    // Can dereference like single-item pointer
    try std.testing.expectEqual(@as(c_int, 42), c_ptr.*);

    // Null C pointer
    const null_ptr: [*c]c_int = null;
    try std.testing.expect(null_ptr == null);
}

test "[*c]T coerces to single-item pointer" {
    var value: c_int = 100;
    const c_ptr: [*c]c_int = &value;

    // Coerce to single-item pointer
    const single_ptr: *c_int = c_ptr;
    try std.testing.expectEqual(@as(c_int, 100), single_ptr.*);
}

test "[*c]T coerces to many-item pointer" {
    var arr = [_]c_int{ 1, 2, 3, 4, 5 };
    const c_ptr: [*c]c_int = &arr;

    // Coerce to many-item pointer
    const many_ptr: [*]c_int = c_ptr;
    try std.testing.expectEqual(@as(c_int, 1), many_ptr[0]);
    try std.testing.expectEqual(@as(c_int, 3), many_ptr[2]);
}

test "[*c]T can be indexed like array" {
    var arr = [_]c_int{ 10, 20, 30 };
    const c_ptr: [*c]c_int = &arr;

    try std.testing.expectEqual(@as(c_int, 10), c_ptr[0]);
    try std.testing.expectEqual(@as(c_int, 20), c_ptr[1]);
    try std.testing.expectEqual(@as(c_int, 30), c_ptr[2]);
}

// ============================================================================
// Error Translation
// ============================================================================

const CError = error{ InvalidInput, Busy, NotFound, Unknown };

fn translateErrno(code: c_int) CError!void {
    return switch (code) {
        0 => {},
        22 => error.InvalidInput,  // EINVAL
        16 => error.Busy,           // EBUSY
        2 => error.NotFound,        // ENOENT
        else => error.Unknown,
    };
}

test "C errno to Zig error set translation" {
    try translateErrno(0); // Success
    try std.testing.expectError(error.InvalidInput, translateErrno(22));
    try std.testing.expectError(error.Busy, translateErrno(16));
    try std.testing.expectError(error.NotFound, translateErrno(2));
    try std.testing.expectError(error.Unknown, translateErrno(999));
}

const FileError = error{ AccessDenied, FileNotFound, OutOfMemory };

fn translateFileError(code: c_int) FileError!void {
    return switch (code) {
        0 => {},
        13 => error.AccessDenied,    // EACCES
        2 => error.FileNotFound,     // ENOENT
        12 => error.OutOfMemory,     // ENOMEM
        else => error.OutOfMemory,   // Default to OOM for unknown
    };
}

test "specialized error set for file operations" {
    try translateFileError(0);
    try std.testing.expectError(error.AccessDenied, translateFileError(13));
    try std.testing.expectError(error.FileNotFound, translateFileError(2));
    try std.testing.expectError(error.OutOfMemory, translateFileError(12));
}

// ============================================================================
// Ownership Transfer Patterns
// ============================================================================

fn allocateForCaller(allocator: std.mem.Allocator, size: usize) ![]u8 {
    // Zig allocates, caller owns and must free
    const buf = try allocator.alloc(u8, size);
    @memset(buf, 0xAA);
    return buf;
}

test "ownership: Zig allocates, caller frees" {
    const allocator = std.testing.allocator;

    const buf = try allocateForCaller(allocator, 64);
    defer allocator.free(buf); // Caller owns this

    try std.testing.expectEqual(@as(usize, 64), buf.len);
    try std.testing.expectEqual(@as(u8, 0xAA), buf[0]);
}

const OwnedData = struct {
    buffer: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: usize) !OwnedData {
        return .{
            .buffer = try allocator.alloc(u8, size),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *OwnedData) void {
        self.allocator.free(self.buffer);
    }
};

test "ownership: struct owns allocation" {
    var data = try OwnedData.init(std.testing.allocator, 128);
    defer data.deinit();

    try std.testing.expectEqual(@as(usize, 128), data.buffer.len);
}

test "ownership: error during partial initialization" {
    const allocator = std.testing.allocator;

    const S = struct {
        fn partialInit(alloc: std.mem.Allocator) !struct { a: []u8, b: []u8 } {
            const a = try alloc.alloc(u8, 32);
            errdefer alloc.free(a); // Free on error!

            // Simulate failure
            if (true) return error.SimulatedFailure;

            const b = try alloc.alloc(u8, 64);
            return .{ .a = a, .b = b };
        }
    };

    try std.testing.expectError(error.SimulatedFailure, S.partialInit(allocator));
    // No leak - errdefer cleaned up
}

// ============================================================================
// anyopaque (C void)
// ============================================================================

test "anyopaque as C void replacement" {
    var value: c_int = 42;
    const opaque_ptr: *anyopaque = @ptrCast(&value);

    // Can't dereference directly, must cast back
    const typed_ptr: *c_int = @ptrCast(@alignCast(opaque_ptr));
    try std.testing.expectEqual(@as(c_int, 42), typed_ptr.*);
}

// ============================================================================
// Export and ABI
// ============================================================================

export fn zigExportedAdd(a: c_int, b: c_int) c_int {
    return a + b;
}

test "export function for C ABI" {
    const result = zigExportedAdd(10, 32);
    try std.testing.expectEqual(@as(c_int, 42), result);
}

const ExportedStruct = extern struct {
    value: c_int,

    export fn create(val: c_int) ExportedStruct {
        return .{ .value = val };
    }
};

test "export struct and function" {
    const s = ExportedStruct.create(100);
    try std.testing.expectEqual(@as(c_int, 100), s.value);
}
