const std = @import("std");

// Test 1: Source file as struct - demonstrate that files can have fields
test "source file can be instantiated as struct" {
    const TopLevelFields = struct {
        foo: u32,
        bar: u64,

        pub fn init(val: u32) @This() {
            return .{
                .foo = val,
                .bar = val * 10,
            };
        }
    };

    const instance = TopLevelFields.init(42);
    try std.testing.expectEqual(@as(u32, 42), instance.foo);
    try std.testing.expectEqual(@as(u64, 420), instance.bar);
}

// Test 2: Demonstrate @This() usage in file context
test "@This() refers to the file's root struct" {
    const FileStruct = struct {
        value: i32,

        const Self = @This();

        pub fn double(self: Self) i32 {
            return self.value * 2;
        }
    };

    const instance: FileStruct = .{ .value = 21 };
    try std.testing.expectEqual(@as(i32, 42), instance.double());
}

// Test 3: Force discovery pattern - imports within comptime blocks
test "comptime block ensures file discovery" {
    // This pattern guarantees that helper code is analyzed
    comptime {
        // In a real project, this would import actual helper files
        // _ = @import("api.zig");

        // For this test, we just verify the pattern compiles
        const discovered = true;
        if (!discovered) @compileError("discovery failed");
    }
}

// Test 4: Conditional platform imports
test "conditional imports based on platform" {
    const builtin = @import("builtin");

    comptime {
        // Platform-specific code discovery pattern
        if (builtin.os.tag == .linux) {
            // Would import linux-specific code
            const linux_available = true;
            _ = linux_available;
        }

        if (builtin.os.tag == .windows) {
            // Would import windows-specific code
            const windows_available = true;
            _ = windows_available;
        }
    }

    // The test verifies that conditional compilation works
    try std.testing.expect(true);
}

// Test 5: Test discovery in root module
test "test blocks force test file discovery" {
    // This demonstrates the pattern for ensuring test files are analyzed
    // In real code: test { _ = @import("tests.zig"); }

    // For this example, we create an inline "test module"
    const TestModule = struct {
        test "discovered test" {
            try std.testing.expect(true);
        }
    };

    // Reference it to force analysis
    _ = TestModule;
}

// Test 6: Export declarations are always analyzed
test "export declarations are discovered automatically" {
    // Export declarations are always analyzed when their containing
    // type is analyzed, regardless of whether they're referenced

    const API = struct {
        export fn exportedFunction() void {
            // This would be available to C code
        }

        fn internalFunction() void {
            // This is only analyzed if referenced
        }
    };

    // Reference the struct to analyze it
    _ = API;

    try std.testing.expect(true);
}

// Test 7: Order-independent declaration references
test "declarations are order-independent" {
    // Can reference before declaration
    const result = helperFunction(21);
    try std.testing.expectEqual(@as(i32, 42), result);
}

fn helperFunction(x: i32) i32 {
    return x * 2;
}

// Test 8: Demonstrate module boundary concepts
test "module concepts: root vs std imports" {
    // Every module implicitly depends on std
    const std_available = @import("std");
    _ = std_available;

    // Root module is available via @import("root")
    // (In this test file context, we can't actually import root,
    // but we demonstrate the concept)

    try std.testing.expect(true);
}

// Test 9: Missing discovery problem demonstration
test "demonstrate why explicit imports matter" {
    // PROBLEM: If you have a helper_tests.zig file that's never
    // imported, its tests won't run even though it's in your codebase.

    // SOLUTION: Force discovery with explicit import:
    // test {
    //     _ = @import("helper_tests.zig");
    // }

    // This test verifies understanding of the discovery model
    const discovery_matters = true;
    try std.testing.expect(discovery_matters);
}

// Test 10: Comptime declarations are always analyzed
test "comptime declarations in analyzed types are guaranteed to run" {
    const TypeWithComptimeInit = struct {
        comptime {
            // This runs at compile time when the type is analyzed
            const validated = true;
            if (!validated) @compileError("validation failed");
        }

        value: u32 = 42,
    };

    const instance: TypeWithComptimeInit = .{};
    try std.testing.expectEqual(@as(u32, 42), instance.value);
}
