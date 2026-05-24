const std = @import("std");
const expect = std.testing.expect;

// 1. Null Safety
// Zig doesn't allow standard pointers (*T) to be null.
// You must use optional pointers (?*T) and explicit handling.
test "null safety: explicit unwrapping" {
    // A pointer that is ALLOWED to be null
    var optional_ptr: ?*const i32 = null;

    // 1. Safe Check: "if (optional_ptr) |value| ..."
    // This is the only way to get the value safely.
    if (optional_ptr) |_| {
        // This block will NOT run because it is null.
        unreachable; 
    } else {
        // This block runs.
        try expect(true);
    }

    // 2. Assigning a value
    const val: i32 = 42;
    optional_ptr = &val;

    // Now the unwrap works
    if (optional_ptr) |ptr| {
        try expect(ptr.* == 42);
    } else {
        unreachable;
    }
}

// 2. Memory Leak Safety
// The DebugAllocator (GPA) tracks allocations.
// If you forget to free, the TEST ITSELF fails.
test "GPA safety: leak detection" {
    // std.testing.allocator is a GPA variant that runs leak checks at the end of the test.
    const allocator = std.testing.allocator;

    // Allocate memory
    const ptr = try allocator.create(i32);
    ptr.* = 100;

    // SAFETY CHECK:
    // If you comment out the next line, running `zig test` will fail with:
    // "error: memory leaked"
    allocator.destroy(ptr);
}

// 3. Bounds Safety
// In Debug/ReleaseSafe, Zig adds runtime checks for slice access.
// While we can't "test" a crash, we can show how to access safely.
test "bounds safety: preventing overflows" {
    var buffer = [_]u8{ 1, 2, 3, 4, 5 }; // len = 5
    const slice: []u8 = &buffer;
    const dangerous_index = 10;

    // Zig's philosophy: "It is better to crash than to read garbage memory."
    // But as a programmer, you should check bounds:
    
    if (dangerous_index < slice.len) {
        // This is safe
        _ = slice[dangerous_index];
    } else {
        // We caught the out-of-bounds access safely!
        try expect(true);
    }
}

// 4. Undefined Memory Safety
// In Debug mode, 'undefined' bytes are often set to 0xaa (10101010).
// This helps catch logic bugs where you use uninitialized memory.
test "undefined safety: distinct patterns" {
    // In Debug mode only
    if (std.debug.runtime_safety) {
        var x: u8 = undefined;
        // The compiler/runtime sets this to 0xaa to signal "garbage data"
        // This isn't a guarantee in the spec, but a common debug feature.
        // We force a runtime check to avoid the compiler optimizing it away.
        const volatile_x = @as(*volatile u8, &x).*;
        
        // This test passes in standard Debug builds, proving the safety fill.
        try expect(volatile_x == 0xaa);
    }
}
