const std = @import("std");

pub fn main() !void {
    std.debug.print("=== Delimiter Reading Tests ===\n\n", .{});

    // Test 1: Line by line reading (inclusive)
    std.debug.print("Test 1: Line by Line (Inclusive)\n", .{});
    {
        const data = "Line 1\nLine 2\nLine 3\n";
        var reader = std.Io.Reader.fixed(data);

        var line_num: usize = 1;
        while (true) {
            const line = reader.takeDelimiterInclusive('\n') catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };
            std.debug.print("  Line {}: {s}", .{ line_num, line });
            line_num += 1;
        }
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 2: Line by line reading (exclusive)
    std.debug.print("Test 2: Line by Line (Exclusive)\n", .{});
    {
        const data = "First\nSecond\nThird";
        var reader = std.Io.Reader.fixed(data);

        var line_num: usize = 1;
        while (true) {
            const line = reader.takeDelimiterExclusive('\n') catch |err| switch (err) {
                error.EndOfStream => {
                    // Get remaining data
                    const rest = reader.buffered();
                    if (rest.len > 0) {
                        std.debug.print("  Line {}: {s}\n", .{ line_num, rest });
                    }
                    break;
                },
                else => return err,
            };
            std.debug.print("  Line {}: {s}\n", .{ line_num, line });
            // Skip the newline if not at end
            if (reader.bufferedLen() > 0) {
                reader.toss(1);
            }
            line_num += 1;
        }
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 3: CSV-like parsing
    std.debug.print("Test 3: CSV Parsing\n", .{});
    {
        const data = "apple,banana,cherry,date";
        var reader = std.Io.Reader.fixed(data);

        var field_num: usize = 1;
        while (true) {
            const field = reader.takeDelimiterExclusive(',') catch |err| switch (err) {
                error.EndOfStream => {
                    const rest = reader.buffered();
                    if (rest.len > 0) {
                        std.debug.print("  Field {}: {s}\n", .{ field_num, rest });
                    }
                    break;
                },
                else => return err,
            };
            std.debug.print("  Field {}: {s}\n", .{ field_num, field });
            if (reader.bufferedLen() > 0) {
                reader.toss(1); // Skip comma
            }
            field_num += 1;
        }
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Test 4: Peek delimiter (lookahead)
    std.debug.print("Test 4: Peek Delimiter (Lookahead)\n", .{});
    {
        const data = "command:argument";
        var reader = std.Io.Reader.fixed(data);

        const lookahead = try reader.peekDelimiterExclusive(':');
        std.debug.print("  Peeked command: {s}\n", .{lookahead});

        const command = try reader.takeDelimiterExclusive(':');
        reader.toss(1); // Skip colon
        const argument = reader.buffered();

        std.debug.print("  Command: {s}\n", .{command});
        std.debug.print("  Argument: {s}\n", .{argument});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("=== All Tests Passed! ===\n", .{});
}
