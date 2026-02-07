# std.testing

## Types

- FailingAllocator
- FuzzInputOptions
- Reader
- ReaderIndirect
- TmpDir

## Global Variables

|  |  |  |
|----|----|----|
| allocator_instance | `std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = if (std.debug.sys_can_stack_trace) 10 else 0, .resize_stack_traces = true,.canary = @truncate(0x2731e675c3a701ba), })` |  |
| environ | `Environ` |  |
| io_instance | `Io.Threaded` |  |
| log_level |  | TODO https://github.com/ziglang/zig/issues/5738 |
| random_seed | `u32` | Provides deterministic randomness in unit tests. Initialized on startup. Read-only after that. |

## Values

|                   |     |                                                      |
|-------------------|-----|------------------------------------------------------|
| allocator         |     | This should only be used in temporary test programs. |
| backend_can_print |     |                                                      |
| failing_allocator |     |                                                      |
| io                |     |                                                      |

## Functions

`pub fn checkAllAllocationFailures(backing_allocator: std.mem.Allocator, comptime test_fn: anytype, extra_args: anytype) !void`  
Exhaustively check that allocation failures within `test_fn` are handled without introducing memory leaks. If used with the `testing.allocator` as the `backing_allocator`, it will also be able to detect double frees, etc (when runtime safety is enabled).

`pub fn expect(ok: bool) !void`  
This function is intended to be used only in tests. When `ok` is false, returns a test failure error.

`pub inline fn expectApproxEqAbs(expected: anytype, actual: anytype, tolerance: anytype) !void`  
This function is intended to be used only in tests. When the actual value is not approximately equal to the expected value, prints diagnostics to stderr to show exactly how they are not equal, then returns a test failure error. See `math.approxEqAbs` for more information on the tolerance parameter. The types must be floating-point. `actual` and `expected` are coerced to a common type using peer type resolution.

`pub inline fn expectApproxEqRel(expected: anytype, actual: anytype, tolerance: anytype) !void`  
This function is intended to be used only in tests. When the actual value is not approximately equal to the expected value, prints diagnostics to stderr to show exactly how they are not equal, then returns a test failure error. See `math.approxEqRel` for more information on the tolerance parameter. The types must be floating-point. `actual` and `expected` are coerced to a common type using peer type resolution.

`pub inline fn expectEqual(expected: anytype, actual: anytype) !void`  
This function is intended to be used only in tests. When the two values are not equal, prints diagnostics to stderr to show exactly how they are not equal, then returns a test failure error. `actual` and `expected` are coerced to a common type using peer type resolution.

`pub inline fn expectEqualDeep(expected: anytype, actual: anytype) error{TestExpectedEqual}!void`  
This function is intended to be used only in tests. When the two values are not deeply equal, prints diagnostics to stderr to show exactly how they are not equal, then returns a test failure error. `actual` and `expected` are coerced to a common type using peer type resolution.

`pub fn expectEqualSentinel(comptime T: type, comptime sentinel: T, expected: [:sentinel]const T, actual: [:sentinel]const T) !void`  
This function is intended to be used only in tests. Checks that two slices or two arrays are equal, including that their sentinel (if any) are the same. Will error if given another type.

`pub fn expectEqualSlices(comptime T: type, expected: []const T, actual: []const T) !void`  
This function is intended to be used only in tests. When the two slices are not equal, prints diagnostics to stderr to show exactly how they are not equal (with the differences highlighted in red), then returns a test failure error.

`pub fn expectEqualStrings(expected: []const u8, actual: []const u8) !void`  

`pub fn expectError(expected_error: anyerror, actual_error_union: anytype) !void`  
This function is intended to be used only in tests. It prints diagnostics to stderr and then returns a test failure error when actual_error_union is not expected_error.

`pub fn expectFmt(expected: []const u8, comptime template: []const u8, args: anytype) !void`  
This function is intended to be used only in tests. When the formatted result of the template and its arguments does not equal the expected text, it prints diagnostics to stderr to show how they are not equal, then returns an error. It depends on `expectEqualStrings` for printing diagnostics.

`pub fn expectStringEndsWith(actual: []const u8, expected_ends_with: []const u8) !void`  

`pub fn expectStringStartsWith(actual: []const u8, expected_starts_with: []const u8) !void`  

`pub fn format(self: @This(), writer: *Io.Writer) !void`  

`pub inline fn fuzz( context: anytype, comptime testOne: fn (context: @TypeOf(context), input: []const u8) anyerror!void, options: FuzzInputOptions, ) anyerror!void`  
Inline to avoid coverage instrumentation.

`pub fn refAllDecls(comptime T: type) void`  
Given a type, references all the declarations inside, so that the semantic analyzer sees them.

`pub fn tmpDir(opts: Io.Dir.OpenOptions) TmpDir`  
