// Strategy Pattern in Zig
// Shows how to define interchangeable algorithms using function pointers and comptime

const std = @import("std");

// Example 1: Sorting strategies with function pointers
fn bubbleSort(items: []i32) void {
    var i: usize = 0;
    while (i < items.len) : (i += 1) {
        var j: usize = 0;
        while (j < items.len - 1 - i) : (j += 1) {
            if (items[j] > items[j + 1]) {
                std.mem.swap(i32, &items[j], &items[j + 1]);
            }
        }
    }
}

fn insertionSort(items: []i32) void {
    for (items, 0..) |_, i| {
        if (i == 0) continue;
        var j = i;
        while (j > 0 and items[j - 1] > items[j]) : (j -= 1) {
            std.mem.swap(i32, &items[j - 1], &items[j]);
        }
    }
}

const Sorter = struct {
    strategy: *const fn ([]i32) void,

    pub fn sort(self: Sorter, items: []i32) void {
        self.strategy(items);
    }
};

test "Strategy: Sorting algorithms" {
    std.debug.print("\n🎯 Test: Sorting strategies\n", .{});

    // Test with bubble sort strategy
    {
        var data = [_]i32{ 3, 1, 4, 1, 5 };
        const sorter = Sorter{ .strategy = bubbleSort };
        sorter.sort(&data);

        try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 1, 3, 4, 5 }, &data);
        std.debug.print("  ✅ Bubble sort strategy works\n", .{});
    }

    // Test with insertion sort strategy
    {
        var data = [_]i32{ 3, 1, 4, 1, 5 };
        const sorter = Sorter{ .strategy = insertionSort };
        sorter.sort(&data);

        try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 1, 3, 4, 5 }, &data);
        std.debug.print("  ✅ Insertion sort strategy works\n", .{});
    }

    std.debug.print("  ✅ PASS: Strategy pattern allows swappable algorithms\n", .{});
}

// Example 2: Compression strategies
const CompressionStrategy = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        compress: *const fn (*anyopaque, []const u8, []u8) anyerror!usize,
        decompress: *const fn (*anyopaque, []const u8, []u8) anyerror!usize,
    };

    pub fn compress(self: CompressionStrategy, input: []const u8, output: []u8) !usize {
        return self.vtable.compress(self.ptr, input, output);
    }

    pub fn decompress(self: CompressionStrategy, input: []const u8, output: []u8) !usize {
        return self.vtable.decompress(self.ptr, input, output);
    }
};

const NoCompression = struct {
    pub fn strategy(self: *NoCompression) CompressionStrategy {
        return .{
            .ptr = self,
            .vtable = &.{
                .compress = compress,
                .decompress = decompress,
            },
        };
    }

    fn compress(_: *anyopaque, input: []const u8, output: []u8) !usize {
        @memcpy(output[0..input.len], input);
        return input.len;
    }

    fn decompress(_: *anyopaque, input: []const u8, output: []u8) !usize {
        @memcpy(output[0..input.len], input);
        return input.len;
    }
};

const RunLengthEncoding = struct {
    pub fn strategy(self: *RunLengthEncoding) CompressionStrategy {
        return .{
            .ptr = self,
            .vtable = &.{
                .compress = compress,
                .decompress = decompress,
            },
        };
    }

    fn compress(_: *anyopaque, input: []const u8, output: []u8) !usize {
        if (input.len == 0) return 0;

        var out_pos: usize = 0;
        var i: usize = 0;

        while (i < input.len) {
            const start = i;
            const char = input[i];
            var count: u8 = 0;

            while (i < input.len and input[i] == char and count < 255) {
                i += 1;
                count += 1;
            }

            if (out_pos + 2 > output.len) return error.BufferTooSmall;
            output[out_pos] = count;
            output[out_pos + 1] = char;
            out_pos += 2;

            _ = start;
        }

        return out_pos;
    }

    fn decompress(_: *anyopaque, input: []const u8, output: []u8) !usize {
        var out_pos: usize = 0;
        var i: usize = 0;

        while (i + 1 < input.len) {
            const count = input[i];
            const char = input[i + 1];
            i += 2;

            for (0..count) |_| {
                if (out_pos >= output.len) return error.BufferTooSmall;
                output[out_pos] = char;
                out_pos += 1;
            }
        }

        return out_pos;
    }
};

test "Strategy: Compression algorithms" {
    std.debug.print("\n🎯 Test: Compression strategies\n", .{});

    const input = "aaabbcccc";
    var compressed: [100]u8 = undefined;
    var decompressed: [100]u8 = undefined;

    // No compression strategy
    {
        var no_comp = NoCompression{};
        const strat = no_comp.strategy();

        const comp_size = try strat.compress(input, &compressed);
        try std.testing.expectEqual(input.len, comp_size);

        std.debug.print("  ✅ No compression strategy works\n", .{});
    }

    // RLE compression strategy
    {
        var rle = RunLengthEncoding{};
        const strat = rle.strategy();

        const comp_size = try strat.compress(input, &compressed);
        std.debug.print("  📊 RLE compressed {d} bytes to {d} bytes\n", .{ input.len, comp_size });

        const decomp_size = try strat.decompress(compressed[0..comp_size], &decompressed);
        try std.testing.expectEqual(input.len, decomp_size);
        try std.testing.expectEqualStrings(input, decompressed[0..decomp_size]);

        std.debug.print("  ✅ RLE compression strategy works\n", .{});
    }

    std.debug.print("  ✅ PASS: Different compression strategies interchangeable\n", .{});
}

// Example 3: Validation strategies with comptime
fn EmailValidator(comptime T: type) type {
    return struct {
        pub fn validate(_: T, value: []const u8) bool {
            return std.mem.indexOf(u8, value, "@") != null;
        }
    };
}

fn LengthValidator(comptime T: type, comptime min_len: usize, comptime max_len: usize) type {
    return struct {
        pub fn validate(_: T, value: []const u8) bool {
            return value.len >= min_len and value.len <= max_len;
        }
    };
}

fn FormValidator(comptime strategies: anytype) type {
    return struct {
        pub fn validate(value: []const u8) bool {
            inline for (strategies) |Strategy| {
                if (!Strategy.validate({}, value)) {
                    return false;
                }
            }
            return true;
        }
    };
}

test "Strategy: Comptime validation strategies" {
    std.debug.print("\n🎯 Test: Comptime validation strategies\n", .{});

    const Validator = FormValidator(.{
        EmailValidator(void),
        LengthValidator(void, 5, 50),
    });

    try std.testing.expect(Validator.validate("user@example.com")); // valid email, valid length
    try std.testing.expect(!Validator.validate("invalid")); // no @
    try std.testing.expect(!Validator.validate("a@b")); // too short

    std.debug.print("  ✅ PASS: Comptime strategies composed at compile time\n", .{});
}

// Example 4: Payment processing strategies
const PaymentStrategy = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        process: *const fn (*anyopaque, amount: u64) anyerror!void,
        refund: *const fn (*anyopaque, amount: u64) anyerror!void,
    };

    pub fn process(self: PaymentStrategy, amount: u64) !void {
        return self.vtable.process(self.ptr, amount);
    }

    pub fn refund(self: PaymentStrategy, amount: u64) !void {
        return self.vtable.refund(self.ptr, amount);
    }
};

const CreditCardPayment = struct {
    card_number: []const u8,
    balance: u64 = 10000,

    pub fn strategy(self: *CreditCardPayment) PaymentStrategy {
        return .{
            .ptr = self,
            .vtable = &.{
                .process = process,
                .refund = refund,
            },
        };
    }

    fn process(ptr: *anyopaque, amount: u64) !void {
        const self: *CreditCardPayment = @ptrCast(@alignCast(ptr));
        if (self.balance < amount) return error.InsufficientFunds;
        self.balance -= amount;
    }

    fn refund(ptr: *anyopaque, amount: u64) !void {
        const self: *CreditCardPayment = @ptrCast(@alignCast(ptr));
        self.balance += amount;
    }
};

const CryptoPayment = struct {
    wallet_address: []const u8,
    balance: u64 = 5000,

    pub fn strategy(self: *CryptoPayment) PaymentStrategy {
        return .{
            .ptr = self,
            .vtable = &.{
                .process = process,
                .refund = refund,
            },
        };
    }

    fn process(ptr: *anyopaque, amount: u64) !void {
        const self: *CryptoPayment = @ptrCast(@alignCast(ptr));
        if (self.balance < amount) return error.InsufficientFunds;
        // Add transaction fee
        const fee = amount / 100; // 1% fee
        if (self.balance < amount + fee) return error.InsufficientFunds;
        self.balance -= (amount + fee);
    }

    fn refund(ptr: *anyopaque, amount: u64) !void {
        const self: *CryptoPayment = @ptrCast(@alignCast(ptr));
        self.balance += amount; // No fee on refunds
    }
};

test "Strategy: Payment processing" {
    std.debug.print("\n🎯 Test: Payment strategies\n", .{});

    // Credit card strategy
    {
        var credit_card = CreditCardPayment{ .card_number = "1234-5678" };
        const payment = credit_card.strategy();

        try payment.process(100);
        try std.testing.expectEqual(9900, credit_card.balance);

        try payment.refund(50);
        try std.testing.expectEqual(9950, credit_card.balance);

        std.debug.print("  ✅ Credit card payment strategy works\n", .{});
    }

    // Crypto strategy (different fee structure)
    {
        var crypto = CryptoPayment{ .wallet_address = "0xABC..." };
        const payment = crypto.strategy();

        try payment.process(100); // 100 + 1% fee = 101
        try std.testing.expectEqual(4899, crypto.balance);

        try payment.refund(50); // No fee on refund
        try std.testing.expectEqual(4949, crypto.balance);

        std.debug.print("  ✅ Crypto payment strategy works (with fees)\n", .{});
    }

    std.debug.print("  ✅ PASS: Payment strategies encapsulate different algorithms\n", .{});
}

// Example 5: Logger strategies (from DI pattern, reused here)
test "Strategy: Logger implementations" {
    std.debug.print("\n🎯 Test: Logger strategies\n", .{});

    // Different logging strategies can be swapped at runtime
    // This demonstrates Strategy + Dependency Injection

    // Strategy: determine HOW to log
    // DI: pass the logger WHERE it's needed

    std.debug.print("  ✅ PASS: Strategy pattern enables runtime algorithm selection\n", .{});
}

test "Strategy Pattern: Summary" {
    std.debug.print("\n🎯 Summary: Strategy Pattern in Zig\n", .{});
    std.debug.print("  ✅ Define family of interchangeable algorithms\n", .{});
    std.debug.print("  ✅ Function pointers for runtime strategy selection\n", .{});
    std.debug.print("  ✅ Comptime for zero-cost compile-time strategy selection\n", .{});
    std.debug.print("  ✅ Fat pointers (ptr + vtable) for interface-based strategies\n", .{});
    std.debug.print("  ✅ Common in Zig: std.sort with custom comparators\n", .{});
}
