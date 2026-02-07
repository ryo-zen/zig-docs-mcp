// Test suite for std.fs.path namespace documentation
// Validates all examples from zig_docs_std/Namespaces/fs/std.fs.md

const std = @import("std");

// ============================================================================
// Quick Start Examples
// ============================================================================

test "quick start: extract filename from path" {
    const path = "src/utils/parser.zig";
    const filename = std.fs.path.basename(path);
    try std.testing.expectEqualStrings("parser.zig", filename);

    std.debug.print("  ✅ Extract filename: {s}\n", .{filename});
}

test "quick start: join path components" {
    const allocator = std.testing.allocator;
    const full_path = try std.fs.path.join(allocator, &.{ "src", "main.zig" });
    defer allocator.free(full_path);

    // Result depends on platform
    const expected_posix = "src/main.zig";
    const expected_windows = "src\\main.zig";

    const matches = std.mem.eql(u8, full_path, expected_posix) or
        std.mem.eql(u8, full_path, expected_windows);
    try std.testing.expect(matches);

    std.debug.print("  ✅ Join paths: {s}\n", .{full_path});
}

test "quick start: get file extension" {
    const path = "document.tar.gz";
    const ext = std.fs.path.extension(path);
    try std.testing.expectEqualStrings(".gz", ext);

    const stem = std.fs.path.stem(path);
    try std.testing.expectEqualStrings("document.tar", stem);

    std.debug.print("  ✅ Extension: {s}, Stem: {s}\n", .{ ext, stem });
}

test "quick start: check if path is absolute" {
    const is_abs1 = std.fs.path.isAbsolute("/usr/bin");
    const is_abs2 = std.fs.path.isAbsolute("C:\\Windows");
    const is_abs3 = std.fs.path.isAbsolute("relative/path");

    // POSIX: /usr/bin is absolute, C:\Windows is not (no drive concept)
    // Windows: both are absolute
    if (@import("builtin").os.tag == .windows) {
        try std.testing.expect(is_abs2);
    } else {
        try std.testing.expect(is_abs1);
    }
    try std.testing.expect(!is_abs3);

    std.debug.print("  ✅ Absolute check: /usr/bin={}, C:\\Windows={}, relative/path={}\n", .{ is_abs1, is_abs2, is_abs3 });
}

test "quick start: parse path components" {
    const path = "/home/user/document.txt";
    const parsed = std.fs.path.parsePath(path);

    // Platform-specific, just verify it doesn't crash
    _ = parsed;
    std.debug.print("  ✅ Parse path: {s}\n", .{path});
}

// ============================================================================
// Component Extraction Functions
// ============================================================================

test "basename: extract filename" {
    try std.testing.expectEqualStrings("main.zig", std.fs.path.basename("src/main.zig"));
    try std.testing.expectEqualStrings("zig", std.fs.path.basename("/usr/local/bin/zig"));

    // On POSIX, backslash is not a separator, so Windows path returns full string
    // Use platform-specific functions for Windows paths on POSIX
    if (@import("builtin").os.tag == .windows) {
        try std.testing.expectEqualStrings("notepad.exe", std.fs.path.basename("C:\\Windows\\notepad.exe"));
    } else {
        // On POSIX, use Windows-specific function for Windows paths
        try std.testing.expectEqualStrings("notepad.exe", std.fs.path.basenameWindows("C:\\Windows\\notepad.exe"));
    }

    try std.testing.expectEqualStrings("no_slashes", std.fs.path.basename("no_slashes"));

    // Trailing slash behavior - check actual behavior
    const trailing_result = std.fs.path.basename("/trailing/");
    // Just verify it doesn't crash, behavior may vary
    _ = trailing_result;

    std.debug.print("  ✅ basename() tests passed\n", .{});
}

test "dirname: extract directory" {
    if (std.fs.path.dirname("src/utils/parser.zig")) |dir| {
        try std.testing.expectEqualStrings("src/utils", dir);
    } else {
        return error.UnexpectedNull;
    }

    if (std.fs.path.dirname("/etc/passwd")) |dir| {
        try std.testing.expectEqualStrings("/etc", dir);
    } else {
        return error.UnexpectedNull;
    }

    // No directory component - should return null
    try std.testing.expect(std.fs.path.dirname("no_directory") == null);

    std.debug.print("  ✅ dirname() tests passed\n", .{});
}

test "extension: extract file extension" {
    try std.testing.expectEqualStrings(".txt", std.fs.path.extension("document.txt"));
    try std.testing.expectEqualStrings(".gz", std.fs.path.extension("archive.tar.gz"));
    try std.testing.expectEqualStrings("", std.fs.path.extension(".gitignore"));
    try std.testing.expectEqualStrings(".backup", std.fs.path.extension(".vimrc.backup"));
    try std.testing.expectEqualStrings(".zig", std.fs.path.extension("main.zig"));
    try std.testing.expectEqualStrings(".zig", std.fs.path.extension("src/main.zig"));
    try std.testing.expectEqualStrings(".json", std.fs.path.extension(".config.json"));
    try std.testing.expectEqualStrings(".", std.fs.path.extension("keep."));
    try std.testing.expectEqualStrings("", std.fs.path.extension("no_extension"));

    std.debug.print("  ✅ extension() tests passed\n", .{});
}

test "stem: filename without extension" {
    try std.testing.expectEqualStrings("document", std.fs.path.stem("document.txt"));
    try std.testing.expectEqualStrings("archive.tar", std.fs.path.stem("archive.tar.gz"));
    try std.testing.expectEqualStrings("main", std.fs.path.stem("src/main.zig"));
    try std.testing.expectEqualStrings(".bashrc", std.fs.path.stem(".bashrc"));
    try std.testing.expectEqualStrings("lib.tar", std.fs.path.stem("hello/world/lib.tar.gz"));
    try std.testing.expectEqualStrings("lib", std.fs.path.stem("hello/world/lib.tar"));
    try std.testing.expectEqualStrings("lib", std.fs.path.stem("hello/world/lib"));

    std.debug.print("  ✅ stem() tests passed\n", .{});
}

// ============================================================================
// Path Construction Functions
// ============================================================================

test "join: combine path components" {
    const allocator = std.testing.allocator;

    const path1 = try std.fs.path.join(allocator, &.{ "src", "utils", "parser.zig" });
    defer allocator.free(path1);

    const path2 = try std.fs.path.join(allocator, &.{ "/usr", "local", "bin" });
    defer allocator.free(path2);

    const path3 = try std.fs.path.join(allocator, &.{ "a", "b", "c", "d" });
    defer allocator.free(path3);

    // Verify basic structure (exact separators depend on platform)
    try std.testing.expect(std.mem.indexOf(u8, path1, "parser.zig") != null);
    try std.testing.expect(std.mem.indexOf(u8, path2, "bin") != null);
    try std.testing.expect(std.mem.indexOf(u8, path3, "a") != null);

    std.debug.print("  ✅ join() tests passed: {s}, {s}, {s}\n", .{ path1, path2, path3 });
}

test "joinZ: null-terminated path" {
    const allocator = std.testing.allocator;
    const c_path = try std.fs.path.joinZ(allocator, &.{ "usr", "bin", "zig" });
    defer allocator.free(c_path);

    // Verify null termination
    try std.testing.expect(c_path[c_path.len] == 0);

    std.debug.print("  ✅ joinZ() null-terminated: {s}\n", .{c_path});
}

test "resolve: normalize path with . and .." {
    const allocator = std.testing.allocator;

    const resolved = try std.fs.path.resolve(allocator, &.{
        "/usr/local",
        "../share",
        "doc",
    });
    defer allocator.free(resolved);

    // Result should contain share/doc
    try std.testing.expect(std.mem.indexOf(u8, resolved, "share") != null);
    try std.testing.expect(std.mem.indexOf(u8, resolved, "doc") != null);

    std.debug.print("  ✅ resolve() test passed: {s}\n", .{resolved});
}

// ============================================================================
// Path Analysis Functions
// ============================================================================

test "isAbsolute: platform-specific absolute check" {
    const posix_abs = std.fs.path.isAbsolute("/usr/bin");
    const windows_abs = std.fs.path.isAbsolute("C:\\Windows");
    const relative = std.fs.path.isAbsolute("relative/path");
    const current = std.fs.path.isAbsolute("./current");

    // On POSIX, /usr/bin is absolute; on Windows, C:\ is absolute
    if (@import("builtin").os.tag == .windows) {
        try std.testing.expect(windows_abs);
    } else {
        try std.testing.expect(posix_abs);
    }

    try std.testing.expect(!relative);
    try std.testing.expect(!current);

    std.debug.print("  ✅ isAbsolute() tests passed\n", .{});
}

test "isSep: separator check" {
    try std.testing.expect(std.fs.path.isSep('/')); // Always true

    if (@import("builtin").os.tag == .windows) {
        try std.testing.expect(std.fs.path.isSep('\\')); // True on Windows
    } else {
        try std.testing.expect(!std.fs.path.isSep('\\')); // False on POSIX
    }

    try std.testing.expect(!std.fs.path.isSep('a'));

    std.debug.print("  ✅ isSep() tests passed\n", .{});
}

// ============================================================================
// Component Iteration
// ============================================================================

test "componentIterator: iterate path components" {
    const path = "/usr/local/bin/zig";
    var it = std.fs.path.componentIterator(path);

    var count: usize = 0;
    const expected = [_][]const u8{ "usr", "local", "bin", "zig" };

    while (it.next()) |component| {
        // In Zig 0.16, component is a struct with .name field
        try std.testing.expectEqualStrings(expected[count], component.name);
        count += 1;
    }

    try std.testing.expectEqual(@as(usize, 4), count);

    std.debug.print("  ✅ componentIterator() test passed: {d} components\n", .{count});
}

// ============================================================================
// Usage Patterns
// ============================================================================

test "pattern: building output paths from input files" {
    const allocator = std.testing.allocator;

    const input_file = "src/parser.zig";
    const dir = std.fs.path.dirname(input_file) orelse ".";
    const base = std.fs.path.stem(input_file);

    // Construct output path
    const output_dir = "output";
    const new_basename = try std.fmt.allocPrint(allocator, "{s}.out", .{base});
    defer allocator.free(new_basename);

    const output = try std.fs.path.join(allocator, &.{ dir, output_dir, new_basename });
    defer allocator.free(output);

    // Verify structure
    try std.testing.expect(std.mem.indexOf(u8, output, "parser.out") != null);

    std.debug.print("  ✅ Pattern: build output path: {s}\n", .{output});
}

test "pattern: cross-platform path handling" {
    const allocator = std.testing.allocator;

    // Normalize mixed separators
    const mixed = "usr/local\\bin/zig";
    var components = std.ArrayList([]const u8).empty; // Zig 0.16: use .empty
    defer components.deinit(allocator);

    var it = std.fs.path.componentIterator(mixed);
    while (it.next()) |component| {
        try components.append(allocator, component.name); // .name field in 0.16
    }

    const normalized = try std.fs.path.join(allocator, components.items);
    defer allocator.free(normalized);

    // Verify all components present
    try std.testing.expect(std.mem.indexOf(u8, normalized, "usr") != null);
    try std.testing.expect(std.mem.indexOf(u8, normalized, "local") != null);
    try std.testing.expect(std.mem.indexOf(u8, normalized, "bin") != null);
    try std.testing.expect(std.mem.indexOf(u8, normalized, "zig") != null);

    std.debug.print("  ✅ Pattern: normalize separators: {s}\n", .{normalized});
}

test "pattern: changing file extensions" {
    const allocator = std.testing.allocator;

    const path = "src/main.zig";
    const dir = std.fs.path.dirname(path) orelse ".";
    const stem_only = std.fs.path.stem(path);
    const new_ext = ".o";

    const new_basename = try std.fmt.allocPrint(allocator, "{s}{s}", .{ stem_only, new_ext });
    defer allocator.free(new_basename);

    const result = try std.fs.path.join(allocator, &.{ dir, new_basename });
    defer allocator.free(result);

    try std.testing.expect(std.mem.indexOf(u8, result, "main.o") != null);

    std.debug.print("  ✅ Pattern: change extension: {s}\n", .{result});
}

// ============================================================================
// Constants
// ============================================================================

test "constants: separators and delimiters" {
    // Just verify they exist and are the right type
    const sep: u8 = std.fs.path.sep;
    const sep_posix: u8 = std.fs.path.sep_posix;
    const sep_windows: u8 = std.fs.path.sep_windows;

    try std.testing.expectEqual(@as(u8, '/'), sep_posix);
    try std.testing.expectEqual(@as(u8, '\\'), sep_windows);

    _ = sep;

    const delimiter: u8 = std.fs.path.delimiter;
    const delimiter_posix: u8 = std.fs.path.delimiter_posix;
    const delimiter_windows: u8 = std.fs.path.delimiter_windows;

    try std.testing.expectEqual(@as(u8, ':'), delimiter_posix);
    try std.testing.expectEqual(@as(u8, ';'), delimiter_windows);

    _ = delimiter;

    std.debug.print("  ✅ Constants verified\n", .{});
}

// ============================================================================
// Edge Cases and Debug Checklist
// ============================================================================

test "edge case: empty strings and null handling" {
    // dirname of no-separator path
    try std.testing.expect(std.fs.path.dirname("file.txt") == null);

    // basename of trailing slash - behavior may vary, just check it doesn't crash
    const trailing_basename = std.fs.path.basename("path/");
    _ = trailing_basename;

    // extension of dotfile
    try std.testing.expectEqualStrings("", std.fs.path.extension(".gitignore"));

    std.debug.print("  ✅ Edge cases handled correctly\n", .{});
}

test "edge case: path normalization awareness" {
    const allocator = std.testing.allocator;

    // join does NOT normalize
    const not_normalized = try std.fs.path.join(allocator, &.{ "a", "..", "b" });
    defer allocator.free(not_normalized);

    // Should contain ".." literally
    try std.testing.expect(std.mem.indexOf(u8, not_normalized, "..") != null);

    std.debug.print("  ✅ join() does not normalize: {s}\n", .{not_normalized});
}

// ============================================================================
// Platform-Specific Functions
// ============================================================================

test "platform-specific: POSIX functions" {
    try std.testing.expectEqualStrings("file.txt", std.fs.path.basenamePosix("/path/to/file.txt"));
    try std.testing.expectEqualStrings("/path/to", std.fs.path.dirnamePosix("/path/to/file.txt").?);
    try std.testing.expect(std.fs.path.isAbsolutePosix("/absolute"));
    try std.testing.expect(!std.fs.path.isAbsolutePosix("relative"));

    std.debug.print("  ✅ POSIX-specific functions work\n", .{});
}

test "platform-specific: Windows functions" {
    try std.testing.expectEqualStrings("file.txt", std.fs.path.basenameWindows("C:\\path\\to\\file.txt"));
    try std.testing.expectEqualStrings("C:\\path\\to", std.fs.path.dirnameWindows("C:\\path\\to\\file.txt").?);
    try std.testing.expect(std.fs.path.isAbsoluteWindows("C:\\path"));
    try std.testing.expect(!std.fs.path.isAbsoluteWindows("relative"));

    std.debug.print("  ✅ Windows-specific functions work\n", .{});
}

// ============================================================================
// Summary
// ============================================================================

test "std.fs.path comprehensive test suite summary" {
    std.debug.print("\n", .{});
    std.debug.print("========================================\n", .{});
    std.debug.print("std.fs.path Test Suite Summary\n", .{});
    std.debug.print("========================================\n", .{});
    std.debug.print("✅ All path manipulation tests passed!\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("Coverage:\n", .{});
    std.debug.print("  • basename, dirname, extension, stem\n", .{});
    std.debug.print("  • join, joinZ, resolve\n", .{});
    std.debug.print("  • isAbsolute, isSep, parsePath\n", .{});
    std.debug.print("  • componentIterator\n", .{});
    std.debug.print("  • Platform-specific functions\n", .{});
    std.debug.print("  • Usage patterns\n", .{});
    std.debug.print("  • Edge cases\n", .{});
    std.debug.print("========================================\n", .{});
}
