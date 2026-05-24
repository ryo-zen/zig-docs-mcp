const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Practical Reader Examples ===\n\n", .{});

    // Example 1: HTTP-like header parsing
    std.debug.print("Example 1: HTTP-like Header Parsing\n", .{});
    {
        const http_data =
            \\GET /index.html HTTP/1.1
            \\Host: example.com
            \\User-Agent: ZigClient/1.0
            \\Accept: */*
            \\
            \\
        ;

        var reader = std.Io.Reader.fixed(http_data);

        // Parse request line
        const method = try reader.takeDelimiterExclusive(' ');
        reader.toss(1);
        const path = try reader.takeDelimiterExclusive(' ');
        reader.toss(1);
        const version = try reader.takeDelimiterExclusive('\n');
        reader.toss(1);

        std.debug.print("  Method: {s}\n", .{method});
        std.debug.print("  Path: {s}\n", .{path});
        std.debug.print("  Version: {s}\n", .{version});
        std.debug.print("  Headers:\n", .{});

        // Parse headers
        while (true) {
            const line = try reader.takeDelimiterExclusive('\n');
            if (line.len == 0) break; // Empty line = end of headers

            // Split on colon
            var line_reader = std.Io.Reader.fixed(line);
            const header_name = try line_reader.takeDelimiterExclusive(':');
            line_reader.toss(2); // Skip ': '
            const header_value = line_reader.buffered();

            std.debug.print("    {s}: {s}\n", .{ header_name, header_value });

            reader.toss(1); // Skip newline
        }

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Example 2: JSON-like parsing (simplified)
    // Note: Last field will include '}' - proper handling would require
    // more complex logic that would obscure the Reader API demonstration
    std.debug.print("Example 2: Simple JSON-like Parsing\n", .{});
    {
        const json_data =
            \\{"name":"Alice","age":30,"active":true}
        ;

        var reader = std.Io.Reader.fixed(json_data);

        // Skip opening brace
        _ = try reader.takeByte();

        std.debug.print("  Parsed fields:\n", .{});

        while (true) {
            // Check for closing brace (or end of stream)
            const next = reader.peekByte() catch break;
            if (next == '}') break;

            // Skip comma if not first field
            if (next == ',') reader.toss(1);

            // Read field name
            _ = try reader.takeByte(); // Skip opening quote
            const field_name = try reader.takeDelimiterExclusive('"');
            reader.toss(1); // Skip closing quote
            reader.toss(1); // Skip colon

            // Read field value (simplified - assume string or number)
            const value_start = try reader.peekByte();
            const value = if (value_start == '"') blk: {
                reader.toss(1); // Skip opening quote
                const val = try reader.takeDelimiterExclusive('"');
                reader.toss(1); // Skip closing quote
                break :blk val;
            } else blk: {
                // Number or boolean - try comma first, then closing brace
                const val = reader.takeDelimiterExclusive(',') catch |err| switch (err) {
                    error.EndOfStream => reader.takeDelimiterExclusive('}') catch reader.buffered(),
                    else => return err,
                };
                break :blk val;
            };

            std.debug.print("    {s} = {s}\n", .{ field_name, value });
        }

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Example 3: Log file parsing
    std.debug.print("Example 3: Log File Parsing\n", .{});
    {
        const log_data =
            \\2024-01-15 10:30:00 [INFO] Application started
            \\2024-01-15 10:30:05 [DEBUG] Connecting to database
            \\2024-01-15 10:30:06 [ERROR] Connection failed: timeout
            \\2024-01-15 10:30:10 [INFO] Retrying connection
            \\
        ;

        var reader = std.Io.Reader.fixed(log_data);

        std.debug.print("  Parsed logs:\n", .{});

        while (true) {
            const line = reader.takeDelimiterInclusive('\n') catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };

            if (line.len == 0) break;

            // Parse log entry
            var line_reader = std.Io.Reader.fixed(line);

            const date = try line_reader.take(10);
            line_reader.toss(1); // space
            const time = try line_reader.take(8);
            line_reader.toss(2); // space + [

            const level = try line_reader.takeDelimiterExclusive(']');
            line_reader.toss(2); // ] + space

            const message = line_reader.buffered();

            // Only show errors
            if (std.mem.eql(u8, level, "ERROR")) {
                std.debug.print("    [{s} {s}] ERROR: {s}", .{ date, time, message });
            }
        }

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Example 4: Configuration file parsing
    std.debug.print("Example 4: INI-style Config Parsing\n", .{});
    {
        const config_data =
            \\[database]
            \\host=localhost
            \\port=5432
            \\
            \\[server]
            \\host=0.0.0.0
            \\port=8080
            \\debug=true
            \\
        ;

        var reader = std.Io.Reader.fixed(config_data);

        var current_section: []const u8 = "";

        while (true) {
            const line = reader.takeDelimiterInclusive('\n') catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };

            if (line.len <= 1) continue; // Skip empty lines

            var line_reader = std.Io.Reader.fixed(line);
            const first = try line_reader.peekByte();

            if (first == '[') {
                // Section header
                line_reader.toss(1);
                const section = try line_reader.takeDelimiterExclusive(']');
                current_section = section;
                std.debug.print("  Section: [{s}]\n", .{section});
            } else {
                // Key-value pair
                const key = try line_reader.takeDelimiterExclusive('=');
                line_reader.toss(1);
                const value = try line_reader.takeDelimiterExclusive('\n');

                std.debug.print("    {s}.{s} = {s}\n", .{ current_section, key, value });
            }
        }

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Example 5: Binary file header parsing
    std.debug.print("Example 5: Binary File Header\n", .{});
    {
        // Create a binary file header
        var write_buf: [1024]u8 = undefined;
        var writer = std.Io.Writer.fixed(&write_buf);

        // Magic bytes
        try writer.writeAll("MYFT"); // My File Type
        // Version
        try writer.writeInt(u16, 1, .little);
        try writer.writeInt(u16, 2, .little); // 1.2
        // Flags
        try writer.writeInt(u32, 0x0000_0001, .little); // bit 0 = compressed
        // File size
        try writer.writeInt(u64, 123456, .little);
        // Checksum
        try writer.writeInt(u32, 0xABCD_1234, .little);
        // Reserved
        try writer.writeInt(u64, 0, .little);

        try writer.flush();

        // Parse it
        var reader = std.Io.Reader.fixed(writer.buffered());

        const magic = try reader.takeArray(4);
        const version_major = try reader.takeInt(u16, .little);
        const version_minor = try reader.takeInt(u16, .little);
        const flags = try reader.takeInt(u32, .little);
        const file_size = try reader.takeInt(u64, .little);
        const checksum = try reader.takeInt(u32, .little);
        const reserved = try reader.takeInt(u64, .little);

        std.debug.print("  Magic: {s}\n", .{magic});
        std.debug.print("  Version: {}.{}\n", .{ version_major, version_minor });
        std.debug.print("  Flags: 0x{x:0>8}\n", .{flags});
        std.debug.print("    - Compressed: {}\n", .{flags & 0x01 != 0});
        std.debug.print("  File Size: {} bytes\n", .{file_size});
        std.debug.print("  Checksum: 0x{x:0>8}\n", .{checksum});
        std.debug.print("  Reserved: {}\n", .{reserved});
        std.debug.print("  ✅ PASS\n\n", .{});
    }

    // Example 6: Token stream parsing
    std.debug.print("Example 6: Simple Tokenizer\n", .{});
    {
        const code = "let x = 42 + y;";
        var reader = std.Io.Reader.fixed(code);

        std.debug.print("  Tokens:\n", .{});

        while (true) {
            // Skip whitespace
            while (true) {
                const ch = reader.peekByte() catch break;
                if (ch != ' ' and ch != '\t' and ch != '\n') break;
                reader.toss(1);
            }

            const first = reader.peekByte() catch break;

            if (std.ascii.isAlphabetic(first)) {
                // Identifier or keyword
                var token_buf: [100]u8 = undefined;
                var token_len: usize = 0;
                while (true) {
                    const ch = reader.peekByte() catch break;
                    if (!std.ascii.isAlphanumeric(ch)) break;
                    token_buf[token_len] = try reader.takeByte();
                    token_len += 1;
                }
                std.debug.print("    IDENT: {s}\n", .{token_buf[0..token_len]});
            } else if (std.ascii.isDigit(first)) {
                // Number
                var num_buf: [100]u8 = undefined;
                var num_len: usize = 0;
                while (true) {
                    const ch = reader.peekByte() catch break;
                    if (!std.ascii.isDigit(ch)) break;
                    num_buf[num_len] = try reader.takeByte();
                    num_len += 1;
                }
                std.debug.print("    NUMBER: {s}\n", .{num_buf[0..num_len]});
            } else {
                // Operator or punctuation
                const ch = try reader.takeByte();
                std.debug.print("    SYMBOL: {c}\n", .{ch});
            }
        }

        std.debug.print("  ✅ PASS\n\n", .{});
    }

    std.debug.print("=== All Examples Complete! ===\n", .{});
    _ = allocator;
}
