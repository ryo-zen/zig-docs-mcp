// Import the Zig standard library - gives access to all std.* functions
const std = @import("std");

// Main entry point of the program
// '!' means this function can return errors (error union type)
// 'void' means it doesn't return a value on success
pub fn main() !void {
    // ========================================
    // SETUP: Memory Allocator
    // ========================================

    // Create a General Purpose Allocator for dynamic memory allocation
    // '.{}' means use default configuration
    // This allocator is good for general use and has safety checks
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    // Schedule cleanup when function exits (success or error)
    // '_' discards the deinit() return value (leak detection result)
    defer _ = gpa.deinit();

    // Get the allocator interface from the GPA
    // This is what you pass to functions that need to allocate memory
    const allocator = gpa.allocator();

    // ========================================
    // SETUP: I/O Backend
    // ========================================

    // Create a Threaded I/O backend
    // - Threaded = synchronous/blocking I/O using threads
    // - allocator = used for internal allocations
    // - .environ = .empty = don't inherit environment variables (simpler for tests)
    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });

    // Schedule cleanup when function exits
    // Will properly shut down the I/O backend
    defer threaded.deinit();

    // Get the I/O interface - this is what you pass to File/Dir operations
    // Think of 'io' as the "how to do I/O" handle
    const io = threaded.io();

    // ========================================
    // GET CURRENT DIRECTORY
    // ========================================

    // Get a handle to the current working directory
    // This lets you create/open files relative to where the program runs
    // 'const' because we won't change which directory we're working with
    const dir = std.Io.Dir.cwd();

    // ========================================
    // WRITE BLOCK: Create file and write data
    // ========================================

    // This block creates a new scope (variables inside are local)
    // Helps organize code and ensures 'file' is closed before reading
    {
        // Create a new file named "test_tier1.txt"
        // - io = the I/O backend to use
        // - "test_tier1.txt" = filename
        // - .{} = default options (overwrite if exists)
        // 'try' = if this fails, return the error from main()
        const file = try dir.createFile(io, "test_tier1.txt", .{});

        // Schedule file close when this block exits
        // CRITICAL: Always close files! Otherwise you leak file descriptors
        defer file.close(io);

        // The data we want to write - a string literal
        // \n = newline character
        const data = "Hello from Tier 1!\nThe answer is 42\n";

        // Write ALL the data to the file
        // - io = I/O backend
        // - data = the string to write
        // 'Streaming' = may do multiple write syscalls if needed
        // 'All' = keeps writing until all data is written
        try file.writeStreamingAll(io, data);

        // When block exits, defer runs: file.close(io)
    }

    // Print success message to stderr (debug output)
    // .{} = empty format arguments (no placeholders in the string)
    std.debug.print("✅ Wrote to file\n", .{});

    // ========================================
    // READ BLOCK: Open file and read data
    // ========================================

    // Another scope block for the reading operation
    {
        // Open existing file for reading
        // - io = I/O backend
        // - "test_tier1.txt" = filename (the one we just created)
        // - .{} = default open options (read-only)
        const file = try dir.openFile(io, "test_tier1.txt", .{});

        // Schedule file close when this block exits
        defer file.close(io);

        // Create a buffer to read data into
        // [1024]u8 = array of 1024 bytes (unsigned 8-bit integers)
        // 'undefined' = don't initialize (faster, we'll fill it by reading)
        var buffer: [1024]u8 = undefined;

        // Read from the file into our buffer
        // - io = I/O backend
        // - &[_][]u8{&buffer} = array of slices - we pass one slice (our buffer)
        //   - &[_] = array literal, infer length
        //   - []u8 = slice of bytes type
        //   - {&buffer} = array content - pointer to our buffer
        // Returns: number of bytes actually read
        const bytes_read = try file.readStreaming(io, &[_][]u8{&buffer});

        // Print how many bytes we read
        // {} = placeholder for the bytes_read value
        std.debug.print("✅ Read {} bytes from file\n", .{bytes_read});

        // Print the actual content
        // {s} = format as string
        // buffer[0..bytes_read] = slice from start (0) to bytes_read
        // We only want to print the bytes we actually read, not the whole buffer
        std.debug.print("Content:\n{s}", .{buffer[0..bytes_read]});

        // When block exits, defer runs: file.close(io)
    }

    // Print completion message
    // \n at start = blank line before message
    std.debug.print("\n🎉 Tier 1 test complete!\n", .{});

    // Function exits, defers run in reverse order:
    // 1. threaded.deinit() - cleanup I/O backend
    // 2. gpa.deinit() - cleanup allocator
}
