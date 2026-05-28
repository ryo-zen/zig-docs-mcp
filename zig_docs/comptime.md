# comptime

`comptime` is one of Zig's core language features. It lets you move specific work from runtime to compile time while staying in normal Zig code.

This page explains how compile-time evaluation works, when to use it, and how to avoid unnecessary complexity.

## Overview

In Zig, whether a value is known at compile time is part of the language model, not an implementation detail.

`comptime` is most useful for:

- Generic APIs driven by types.
- Compile-time validation of configuration.
- Specialization where runtime dispatch is unnecessary.

## Runnable Examples

- `zig_docs_std/Examples/comptime_api_design.tests.zig`
- `zig_docs_std/Examples/test_tier1_simple_annotated.zig`
- `zig_docs_std/Examples/zig_patterns.lazy_initialization.tests.zig`

## Quick Start

1. Use `comptime` when the input is inherently static (types, feature flags, structural API shape).
2. Keep operational data (user input, files, network data) at runtime.
3. Prefer explicit `@compileError` messages for invalid compile-time configuration.
4. Add specialization only when correctness or measured performance benefits are clear.

## [Introducing the Compile-Time Concept](#toc-Introducing-the-Compile-Time-Concept) §

Compile-time behavior in Zig appears in three main forms:

1. Compile-time parameters.
2. Compile-time variables.
3. Compile-time expressions.

### [Compile-Time Parameters](#toc-Compile-Time-Parameters) §

Compile-time parameters are Zig's generic mechanism. This is often described as compile-time duck typing.

compile-time_duck_typing.zig
```zig
fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

fn gimmeTheBiggerFloat(a: f32, b: f32) f32 {
    return max(f32, a, b);
}

fn gimmeTheBiggerInteger(a: u64, b: u64) u64 {
    return max(u64, a, b);
}
```

In Zig, types are first-class values. You can pass them to functions, but only where compile-time values are required. That is why `T` is marked `comptime`.

A `comptime` parameter means:

- At the call site, the argument must be compile-time known.
- Inside the function body, the value is compile-time known.

If you pass a runtime-only value to a comptime parameter, compilation fails:

test_unresolved_comptime_value.zig
```zig
fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

test "try to pass a runtime type" {
    foo(false);
}

fn foo(condition: bool) void {
    const result = max(if (condition) f32 else u64, 1234, 5678);
    _ = result;
}
```

Expected result: compile error indicating the argument to the comptime parameter is not comptime-known.

Compile-time duck typing also means generic code is type-checked with the concrete instantiation. If a required operation is invalid for that type, compilation fails:

test_comptime_mismatched_type.zig
```zig
fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

test "try to compare bools" {
    _ = max(bool, true, false);
}
```

Expected result: compile error because `>` is invalid for `bool`.

Because `T` is compile-time known inside `max`, you can branch on type:

test_comptime_max_with_bool.zig
```zig
fn max(comptime T: type, a: T, b: T) T {
    if (T == bool) {
        return a or b;
    } else if (a > b) {
        return a;
    } else {
        return b;
    }
}

test "try to compare bools" {
    try @import("std").testing.expect(max(bool, false, true) == true);
}
```

When `T` is known, Zig evaluates the compile-time branch and analyzes only the selected path. The resulting emitted function only contains runtime-relevant logic.

compiler_generated_function.zig
```zig
fn max(a: bool, b: bool) bool {
    return a or b;
}
```

This behavior also applies to `switch` when the target is compile-time known.

### [Compile-Time Variables](#toc-Compile-Time-Variables) §

A `comptime var` guarantees that all loads/stores happen at compile time. Violations are compile errors.

Combined with `inline` loops, this lets you partially evaluate logic at compile time while keeping normal runtime code.

test_comptime_evaluation.zig
```zig
const expect = @import("std").testing.expect;

const CmdFn = struct {
    name: []const u8,
    func: fn (i32) i32,
};

const cmd_fns = [_]CmdFn{
    .{ .name = "one", .func = one },
    .{ .name = "two", .func = two },
    .{ .name = "three", .func = three },
};

fn one(value: i32) i32 {
    return value + 1;
}

fn two(value: i32) i32 {
    return value + 2;
}

fn three(value: i32) i32 {
    return value + 3;
}

fn performFn(comptime prefix_char: u8, start_value: i32) i32 {
    var result: i32 = start_value;
    comptime var i = 0;
    inline while (i < cmd_fns.len) : (i += 1) {
        if (cmd_fns[i].name[0] == prefix_char) {
            result = cmd_fns[i].func(result);
        }
    }
    return result;
}

test "perform fn" {
    try expect(performFn('t', 1) == 6);
    try expect(performFn('o', 0) == 1);
    try expect(performFn('w', 99) == 99);
}
```

This pattern is intentionally demonstrative. It is not automatically a performance optimization strategy; it is a way to guarantee selected logic runs at compile time and to express type/value-driven behavior cleanly.

The generated runtime code differs per comptime input.

performFn_1
```zig
// From: expect(performFn('t', 1) == 6)
fn performFn(start_value: i32) i32 {
    var result: i32 = start_value;
    result = two(result);
    result = three(result);
    return result;
}
```

performFn_2
```zig
// From: expect(performFn('o', 0) == 1)
fn performFn(start_value: i32) i32 {
    var result: i32 = start_value;
    result = one(result);
    return result;
}
```

performFn_3
```zig
// From: expect(performFn('w', 99) == 99)
fn performFn(start_value: i32) i32 {
    var result: i32 = start_value;
    _ = &result;
    return result;
}
```

### [Compile-Time Expressions](#toc-Compile-Time-Expressions) §

A `comptime` expression forces evaluation at compile time. If that is impossible, compilation fails.

test_comptime_call_extern_function.zig
```zig
extern fn exit() noreturn;

test "foo" {
    comptime {
        exit();
    }
}
```

Expected result: compile error (`comptime` cannot call extern/runtime functions).

Inside a `comptime` block:

- Variables are compile-time variables.
- Control flow (`if`, `while`, `for`, `switch`) must be evaluable at compile time.
- `return` and `try` are invalid unless the containing function itself is being called at compile time.
- Runtime side effects are invalid.
- Function calls are interpreted at compile time, and fail to compile if they require global runtime side effects.

This lets one function be evaluated in both runtime and compile-time contexts without separate implementations.

test_fibonacci_recursion.zig
```zig
const expect = @import("std").testing.expect;

fn fibonacci(index: u32) u32 {
    if (index < 2) return index;
    return fibonacci(index - 1) + fibonacci(index - 2);
}

test "fibonacci" {
    try expect(fibonacci(7) == 13); // runtime
    try comptime expect(fibonacci(7) == 13); // compile-time
}
```

If the base case is missing, compile-time evaluation reports the bug while compiling:

test_fibonacci_comptime_overflow.zig
```zig
const expect = @import("std").testing.expect;

fn fibonacci(index: u32) u32 {
    return fibonacci(index - 1) + fibonacci(index - 2);
}

test "fibonacci" {
    try comptime expect(fibonacci(7) == 13);
}
```

Expected result: compile error (integer underflow/overflow and comptime call trace).

If you use signed integers and remove the base case, the compiler will eventually exceed evaluation limits. You can raise the default branch budget with `@setEvalBranchQuota` when legitimate compile-time work needs it.

fibonacci_comptime_infinite_recursion.zig
```zig
const assert = @import("std").debug.assert;

fn fibonacci(index: i32) i32 {
    return fibonacci(index - 1) + fibonacci(index - 2);
}

test "fibonacci" {
    try comptime assert(fibonacci(7) == 13);
}
```

If logic is wrong but finite, compile-time assertions fail during compilation:

test_fibonacci_comptime_unreachable.zig
```zig
const assert = @import("std").debug.assert;

fn fibonacci(index: i32) i32 {
    if (index < 2) return index;
    return fibonacci(index - 1) + fibonacci(index - 2);
}

test "fibonacci" {
    try comptime assert(fibonacci(7) == 99999);
}
```

At container level (outside functions), expressions are implicitly comptime. This is useful for precomputed static data.

test_container-level_comptime_expressions.zig
```zig
const first_25_primes = firstNPrimes(25);
const sum_of_first_25_primes = sum(&first_25_primes);

fn firstNPrimes(comptime n: usize) [n]i32 {
    var prime_list: [n]i32 = undefined;
    var next_index: usize = 0;
    var test_number: i32 = 2;

    while (next_index < prime_list.len) : (test_number += 1) {
        var test_prime_index: usize = 0;
        var is_prime = true;

        while (test_prime_index < next_index) : (test_prime_index += 1) {
            if (test_number % prime_list[test_prime_index] == 0) {
                is_prime = false;
                break;
            }
        }

        if (is_prime) {
            prime_list[next_index] = test_number;
            next_index += 1;
        }
    }

    return prime_list;
}

fn sum(numbers: []const i32) i32 {
    var result: i32 = 0;
    for (numbers) |x| result += x;
    return result;
}

test "variable values" {
    try @import("std").testing.expect(sum_of_first_25_primes == 1060);
}
```

Compilation can precompute these values into static constants.

## [Generic Data Structures](#toc-Generic-Data-Structures) §

Zig uses comptime to express generic data structures without introducing separate template syntax.

generic_data_structure.zig
```zig
fn List(comptime T: type) type {
    return struct {
        items: []T,
        len: usize,
    };
}

// Instantiate by passing a type.
var buffer: [10]i32 = undefined;
var list = List(i32){
    .items = &buffer,
    .len = 0,
};
```

That is just a function returning a type. For diagnostics, Zig infers names like `List(i32)`.

To give a type an explicit name, assign it to a constant:

anonymous_struct_name.zig
```zig
const Node = struct {
    next: ?*Node,
    name: []const u8,
};

var node_a = Node{
    .next = null,
    .name = "Node A",
};

var node_b = Node{
    .next = &node_a,
    .name = "Node B",
};
```

`Node` can reference itself because top-level declarations are order-independent, and `?*Node` has a known size at compile time.

## [Case Study: print in Zig](#toc-Case-Study-print-in-Zig) §

This section shows how Zig's standard formatting uses comptime in library code rather than compiler special-casing.

print.zig
```zig
const print = @import("std").debug.print;

const a_number: i32 = 1234;
const a_string = "foobar";

pub fn main() void {
    print("here is a string: '{s}' here is a number: {}\n", .{ a_string, a_number });
}
```

`print` accepts a comptime-known format string. A proof-of-concept implementation:

poc_print_fn.zig
```zig
const Writer = struct {
    pub fn print(self: *Writer, comptime format: []const u8, args: anytype) anyerror!void {
        const State = enum {
            start,
            open_brace,
            close_brace,
        };

        comptime var start_index: usize = 0;
        comptime var state = State.start;
        comptime var next_arg: usize = 0;

        inline for (format, 0..) |c, i| {
            switch (state) {
                .start => switch (c) {
                    '{' => {
                        if (start_index < i) try self.write(format[start_index..i]);
                        state = .open_brace;
                    },
                    '}' => {
                        if (start_index < i) try self.write(format[start_index..i]);
                        state = .close_brace;
                    },
                    else => {},
                },
                .open_brace => switch (c) {
                    '{' => {
                        state = .start;
                        start_index = i;
                    },
                    '}' => {
                        try self.printValue(args[next_arg]);
                        next_arg += 1;
                        state = .start;
                        start_index = i + 1;
                    },
                    's' => continue,
                    else => @compileError("Unknown format character: " ++ [1]u8{c}),
                },
                .close_brace => switch (c) {
                    '}' => {
                        state = .start;
                        start_index = i;
                    },
                    else => @compileError("Single '}' encountered in format string"),
                },
            }
        }

        comptime {
            if (args.len != next_arg) {
                @compileError("Unused arguments");
            }
            if (state != .start) {
                @compileError("Incomplete format string: " ++ format);
            }
        }

        if (start_index < format.len) {
            try self.write(format[start_index..format.len]);
        }
        try self.flush();
    }

    fn write(self: *Writer, value: []const u8) !void {
        _ = self;
        _ = value;
    }

    pub fn printValue(self: *Writer, value: anytype) !void {
        _ = self;
        _ = value;
    }

    fn flush(self: *Writer) !void {
        _ = self;
    }
};
```

The real stdlib implementation supports more formatting behavior, but the principle is the same: compile-time parsing of the format string and compile-time validation of arguments.

After partial compile-time evaluation, emitted code is effectively specialized for that format:

emitted_print_function.zig
```zig
pub fn print(self: *Writer, arg0: []const u8, arg1: i32) !void {
    try self.write("here is a string: '");
    try self.printValue(arg0);
    try self.write("' here is a number: ");
    try self.printValue(arg1);
    try self.write("\n");
    try self.flush();
}
```

`printValue` can dispatch by type using `@typeInfo`:

poc_printValue_fn.zig
```zig
const Writer = struct {
    pub fn printValue(self: *Writer, value: anytype) !void {
        switch (@typeInfo(@TypeOf(value))) {
            .int => return self.writeInt(value),
            .float => return self.writeFloat(value),
            .pointer => return self.write(value),
            else => @compileError("Unable to print type '" ++ @typeName(@TypeOf(value)) ++ "'"),
        }
    }

    fn write(self: *Writer, value: []const u8) !void {
        _ = self;
        _ = value;
    }

    fn writeInt(self: *Writer, value: anytype) !void {
        _ = self;
        _ = value;
    }

    fn writeFloat(self: *Writer, value: anytype) !void {
        _ = self;
        _ = value;
    }
};
```

If you pass too many arguments, compilation fails:

test_print_too_many_args.zig
```zig
const print = @import("std").debug.print;

const a_number: i32 = 1234;
const a_string = "foobar";

test "print too many arguments" {
    print("here is a string: '{s}' here is a number: {}\n", .{
        a_string,
        a_number,
        a_number,
    });
}
```

Expected result: compile error for an unused format argument.

The format value does not need to be a literal. It only needs to be comptime-known and coercible to `[]const u8`.

print_comptime-known_format.zig
```zig
const print = @import("std").debug.print;

const a_number: i32 = 1234;
const a_string = "foobar";
const fmt = "here is a string: '{s}' here is a number: {}\n";

pub fn main() void {
    print(fmt, .{ a_string, a_number });
}
```

This demonstrates an important design point: Zig keeps powerful metaprogramming in normal Zig code, not in a separate macro/preprocessor language.

## Library API Design Guidance

For public APIs, use `comptime` deliberately:

1. Put structural constraints (type shape, feature compatibility) at compile time.
2. Keep runtime inputs and operational policy at runtime.
3. Minimize comptime knobs in the primary API surface.
4. Offer convenience wrappers so common cases stay simple.

## Specialization Tradeoffs

Benefits:

- Removes runtime branches or dispatch in some designs.
- Improves type-level safety and call-site clarity.

Costs:

- More compile-time work.
- Potential binary growth from additional instantiations.
- More complex diagnostics if constraints are broad.

Guideline: specialize where correctness or measured performance clearly justifies the cost.

## Avoid Overusing `comptime`

Prefer runtime logic when:

1. Inputs naturally come from users or external systems.
2. Behavior must vary often at runtime.
3. Specialization would generate many near-identical instantiations.

Recommended progression:

1. Start with a runtime design.
2. Add compile-time constraints for API correctness.
3. Add specialization only where needed.
4. Re-check compile time and binary size after each step.

## Gotchas

1. Passing runtime values to comptime parameters fails at call sites.
2. Excessive specialization can significantly slow builds.
3. Missing `@compileError` guards can produce confusing errors for API users.
4. Compile-time work still has resource limits (`@setEvalBranchQuota`).

See also:

- [inline while](#inline-while)
- [inline for](#inline-for)
- [Result Location Semantics](result_location_semantics.md)
- [Functions](functions.md)
