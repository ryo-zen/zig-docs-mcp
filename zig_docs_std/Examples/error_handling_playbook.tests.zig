const std = @import("std");

const ServiceError = error{
    TemporaryUnavailable,
    InvalidPayload,
    OutOfMemory,
};

const AttemptPlan = struct {
    fails_before_success: u8,
    call_count: u8 = 0,
};

fn simulatedCall(plan: *AttemptPlan) ServiceError!u16 {
    plan.call_count += 1;
    if (plan.call_count <= plan.fails_before_success) return error.TemporaryUnavailable;
    return 200;
}

fn retryWithBackoff(plan: *AttemptPlan, max_attempts: u8, backoff_log: *std.ArrayList(u16), allocator: std.mem.Allocator) ServiceError!u16 {
    var attempt: u8 = 0;
    while (attempt < max_attempts) : (attempt += 1) {
        const result = simulatedCall(plan) catch |err| switch (err) {
            error.TemporaryUnavailable => {
                var delay_ms: u16 = 10;
                var i: u8 = 0;
                while (i < attempt) : (i += 1) delay_ms *= 2;
                try backoff_log.append(allocator, delay_ms);
                continue;
            },
            else => return err,
        };
        return result;
    }
    return error.TemporaryUnavailable;
}

fn classify(err: ServiceError) enum { retryable, fatal } {
    return switch (err) {
        error.TemporaryUnavailable => .retryable,
        error.InvalidPayload, error.OutOfMemory => .fatal,
    };
}

fn parsePositiveU16(text: []const u8) ServiceError!u16 {
    const value = std.fmt.parseInt(i32, text, 10) catch return error.InvalidPayload;
    if (value < 0 or value > std.math.maxInt(u16)) return error.InvalidPayload;
    return @intCast(value);
}

fn loadUserPort(text: []const u8) ServiceError!u16 {
    return parsePositiveU16(text) catch {
        // Context attachment boundary: here we'd log subsystem + operation.
        return error.InvalidPayload;
    };
}

test "policy: retry transient failure with bounded exponential backoff" {
    var plan = AttemptPlan{ .fails_before_success = 2 };
    var backoff_log: std.ArrayList(u16) = .empty;
    defer backoff_log.deinit(std.testing.allocator);

    const status = try retryWithBackoff(&plan, 5, &backoff_log, std.testing.allocator);
    try std.testing.expectEqual(@as(u16, 200), status);
    try std.testing.expectEqual(@as(usize, 2), backoff_log.items.len);
    try std.testing.expectEqual(@as(u16, 10), backoff_log.items[0]);
    try std.testing.expectEqual(@as(u16, 20), backoff_log.items[1]);
}

test "policy: retries stop at max attempts" {
    var plan = AttemptPlan{ .fails_before_success = 5 };
    var backoff_log: std.ArrayList(u16) = .empty;
    defer backoff_log.deinit(std.testing.allocator);

    try std.testing.expectError(
        error.TemporaryUnavailable,
        retryWithBackoff(&plan, 3, &backoff_log, std.testing.allocator),
    );
    try std.testing.expectEqual(@as(usize, 3), backoff_log.items.len);
}

test "policy: classify recoverable vs fatal" {
    try std.testing.expectEqual(.retryable, classify(error.TemporaryUnavailable));
    try std.testing.expectEqual(.fatal, classify(error.InvalidPayload));
    try std.testing.expectEqual(.fatal, classify(error.OutOfMemory));
}

test "policy: context propagation keeps semantic error" {
    try std.testing.expectError(error.InvalidPayload, loadUserPort("not-a-number"));
    try std.testing.expectEqual(@as(u16, 8080), try loadUserPort("8080"));
}

test "policy: panic is for invariants, parsing uses error union" {
    try std.testing.expectError(error.InvalidPayload, parsePositiveU16("-1"));
    try std.testing.expectEqual(@as(u16, 7), try parsePositiveU16("7"));
}
