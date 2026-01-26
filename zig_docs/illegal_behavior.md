# Illegal Behavior §

Many operations in Zig trigger what is known as "Illegal Behavior" (IB). If Illegal Behavior is detected at compile-time, Zig emits a compile error and refuses to continue. Otherwise, when Illegal Behavior is not caught at compile-time, it falls into one of two categories. 

Some Illegal Behavior is _safety-checked_ : this means that the compiler will insert "safety checks" anywhere that the Illegal Behavior may occur at runtime, to determine whether it is about to happen. If it is, the safety check "fails", which triggers a panic. 

All other Illegal Behavior is _unchecked_ , meaning the compiler is unable to insert safety checks for it. If Unchecked Illegal Behavior is invoked at runtime, anything can happen: usually that will be some kind of crash, but the optimizer is free to make Unchecked Illegal Behavior do anything, such as calling arbitrary functions or clobbering arbitrary data. This is similar to the concept of "undefined behavior" in some other languages. Note that Unchecked Illegal Behavior still always results in a compile error if evaluated at comptime, because the Zig compiler is able to perform more sophisticated checks at compile-time than at runtime. 

Most Illegal Behavior is safety-checked. However, to facilitate optimizations, safety checks are disabled by default in the ReleaseFast and ReleaseSmall optimization modes. Safety checks can also be enabled or disabled on a per-block basis, overriding the default for the current optimization mode, using @setRuntimeSafety. When safety checks are disabled, Safety-Checked Illegal Behavior behaves like Unchecked Illegal Behavior; that is, any behavior may result from invoking it. 

When a safety check fails, Zig's default panic handler crashes with a stack trace, like this: 

test_illegal_behavior.zig

    ```
    test "safety check" {
        unreachable;
    }
    ```

Shell

    ```zig
    $ zig test test_illegal_behavior.zig
    1/1 test_illegal_behavior.test.safety check...thread 210495 panic: reached unreachable code
    /home/andy/dev/zig/doc/langref/test_illegal_behavior.zig:2:5: 0x10488c8 in test.safety check (test)
        unreachable;
        ^
    /home/andy/dev/zig/lib/compiler/test_runner.zig:214:25: 0x10ef065 in mainTerminal (test)
            if (test_fn.func()) |_| {
                            ^
    /home/andy/dev/zig/lib/compiler/test_runner.zig:62:28: 0x10e744d in main (test)
            return mainTerminal();
                               ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10e68c2 in posixCallMainAndExit (test)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10e649d in _start (test)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    error: the following test command crashed:
    /home/andy/dev/zig/.zig-cache/o/532079bf373c937f8f95a990d9470d7c/test --seed=0xbaefa3c8
    
    ```

### Reaching Unreachable Code §

At compile-time:

test_comptime_reaching_unreachable.zig

    ```zig
    comptime {
        assert(false);
    }
    fn assert(ok: bool) void {
        if (!ok) unreachable; // assertion failure
    }
    ```

Shell

    ```
    $ zig test test_comptime_reaching_unreachable.zig
    /home/andy/dev/zig/doc/langref/test_comptime_reaching_unreachable.zig:5:14: error: reached unreachable code
        if (!ok) unreachable; // assertion failure
                 ^~~~~~~~~~~
    /home/andy/dev/zig/doc/langref/test_comptime_reaching_unreachable.zig:2:11: note: called from here
        assert(false);
        ~~~~~~^~~~~~~

    ```

At runtime:

runtime_reaching_unreachable.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        std.debug.assert(false);
    }
    ```

Shell

    ```
    $ zig build-exe runtime_reaching_unreachable.zig
    $ ./runtime_reaching_unreachable
    thread 201175 panic: reached unreachable code
    /home/andy/dev/zig/lib/std/debug.zig:550:14: 0x10489fd in assert (runtime_reaching_unreachable)
        if (!ok) unreachable; // assertion failure
                 ^
    /home/andy/dev/zig/doc/langref/runtime_reaching_unreachable.zig:4:21: 0x10de84a in main (runtime_reaching_unreachable)
        std.debug.assert(false);
                        ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de242 in posixCallMainAndExit (runtime_reaching_unreachable)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10dde1d in _start (runtime_reaching_unreachable)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Index out of Bounds §

At compile-time:

test_comptime_index_out_of_bounds.zig

    ```zig
    comptime {
        const array: [5]u8 = "hello".*;
        const garbage = array[5];
        _ = garbage;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_index_out_of_bounds.zig
    /home/andy/dev/zig/doc/langref/test_comptime_index_out_of_bounds.zig:3:27: error: index 5 outside array of length 5
        const garbage = array[5];
                              ^

    ```

At runtime:

runtime_index_out_of_bounds.zig

    ```zig
    pub fn main() void {
        const x = foo("hello");
        _ = x;
    }
    
    fn foo(x: []const u8) u8 {
        return x[5];
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_index_out_of_bounds.zig
    $ ./runtime_index_out_of_bounds
    thread 207520 panic: index out of bounds: index 5, len 5
    /home/andy/dev/zig/doc/langref/runtime_index_out_of_bounds.zig:7:13: 0x10df121 in foo (runtime_index_out_of_bounds)
        return x[5];
                ^
    /home/andy/dev/zig/doc/langref/runtime_index_out_of_bounds.zig:2:18: 0x10de886 in main (runtime_index_out_of_bounds)
        const x = foo("hello");
                     ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de272 in posixCallMainAndExit (runtime_index_out_of_bounds)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10dde4d in _start (runtime_index_out_of_bounds)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Cast Negative Number to Unsigned Integer §

At compile-time:

test_comptime_invalid_cast.zig

    ```zig
    comptime {
        const value: i32 = -1;
        const unsigned: u32 = @intCast(value);
        _ = unsigned;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_invalid_cast.zig
    /home/andy/dev/zig/doc/langref/test_comptime_invalid_cast.zig:3:36: error: type 'u32' cannot represent integer value '-1'
        const unsigned: u32 = @intCast(value);
                                       ^~~~~

    ```

At runtime:

runtime_invalid_cast.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        var value: i32 = -1; // runtime-known
        _ = &value;
        const unsigned: u32 = @intCast(value);
        std.debug.print("value: {}\n", .{unsigned});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_invalid_cast.zig
    $ ./runtime_invalid_cast
    thread 202040 panic: attempt to cast negative value to unsigned integer
    /home/andy/dev/zig/doc/langref/runtime_invalid_cast.zig:6:27: 0x10de986 in main (runtime_invalid_cast)
        const unsigned: u32 = @intCast(value);
                              ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de362 in posixCallMainAndExit (runtime_invalid_cast)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddf3d in _start (runtime_invalid_cast)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

To obtain the maximum value of an unsigned integer, use `std.math.maxInt`. 

### Cast Truncates Data §

At compile-time:

test_comptime_invalid_cast_truncate.zig

    ```zig
    comptime {
        const spartan_count: u16 = 300;
        const byte: u8 = @intCast(spartan_count);
        _ = byte;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_invalid_cast_truncate.zig
    /home/andy/dev/zig/doc/langref/test_comptime_invalid_cast_truncate.zig:3:31: error: type 'u8' cannot represent integer value '300'
        const byte: u8 = @intCast(spartan_count);
                                  ^~~~~~~~~~~~~

    ```

At runtime:

runtime_invalid_cast_truncate.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        var spartan_count: u16 = 300; // runtime-known
        _ = &spartan_count;
        const byte: u8 = @intCast(spartan_count);
        std.debug.print("value: {}\n", .{byte});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_invalid_cast_truncate.zig
    $ ./runtime_invalid_cast_truncate
    thread 197892 panic: integer cast truncated bits
    /home/andy/dev/zig/doc/langref/runtime_invalid_cast_truncate.zig:6:22: 0x10dea18 in main (runtime_invalid_cast_truncate)
        const byte: u8 = @intCast(spartan_count);
                         ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de3f2 in posixCallMainAndExit (runtime_invalid_cast_truncate)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddfcd in _start (runtime_invalid_cast_truncate)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

To truncate bits, use @truncate. 

### Integer Overflow §

#### Default Operations §

The following operators can cause integer overflow:

  * `+` (addition)
  * `-` (subtraction)
  * `-` (negation)
  * `*` (multiplication)
  * `/` (division)
  * @divTrunc (division)
  * @divFloor (division)
  * @divExact (division)

Example with addition at compile-time:

test_comptime_overflow.zig

    ```zig
    comptime {
        var byte: u8 = 255;
        byte += 1;
    }
    ```

Shell

    ```
    $ zig test test_comptime_overflow.zig
    /home/andy/dev/zig/doc/langref/test_comptime_overflow.zig:3:10: error: overflow of integer type 'u8' with value '256'
        byte += 1;
        ~~~~~^~~~

    ```

At runtime:

runtime_overflow.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        var byte: u8 = 255;
        byte += 1;
        std.debug.print("value: {}\n", .{byte});
    }
    ```

Shell

    ```
    $ zig build-exe runtime_overflow.zig
    $ ./runtime_overflow
    thread 208546 panic: integer overflow
    /home/andy/dev/zig/doc/langref/runtime_overflow.zig:5:10: 0x10dea19 in main (runtime_overflow)
        byte += 1;
             ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de3f2 in posixCallMainAndExit (runtime_overflow)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddfcd in _start (runtime_overflow)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

#### Standard Library Math Functions §

These functions provided by the standard library return possible errors.

  * `@import("std").math.add`
  * `@import("std").math.sub`
  * `@import("std").math.mul`
  * `@import("std").math.divTrunc`
  * `@import("std").math.divFloor`
  * `@import("std").math.divExact`
  * `@import("std").math.shl`

Example of catching an overflow for addition:

math_add.zig

    ```zig
    const math = @import("std").math;
    const print = @import("std").debug.print;
    pub fn main() !void {
        var byte: u8 = 255;
    
        byte = if (math.add(u8, byte, 1)) |result| result else |err| {
            print("unable to add one: {s}\n", .{@errorName(err)});
            return err;
        };
    
        print("result: {}\n", .{byte});
    }
    ```

Shell

    ```
    $ zig build-exe math_add.zig
    $ ./math_add
    unable to add one: Overflow
    error: Overflow
    /home/andy/dev/zig/lib/std/math.zig:565:21: 0x10dea35 in add__anon_24027 (math_add)
        if (ov[1] != 0) return error.Overflow;
                        ^
    /home/andy/dev/zig/doc/langref/math_add.zig:8:9: 0x10de9cb in main (math_add)
            return err;
            ^
    
    ```

#### Builtin Overflow Functions §

These builtins return a tuple containing whether there was an overflow (as a `u1`) and the possibly overflowed bits of the operation: 

  * @addWithOverflow
  * @subWithOverflow
  * @mulWithOverflow
  * @shlWithOverflow

Example of @addWithOverflow: 

addWithOverflow_builtin.zig

    ```zig
    const print = @import("std").debug.print;
    pub fn main() void {
        const byte: u8 = 255;
    
        const ov = @addWithOverflow(byte, 10);
        if (ov[1] != 0) {
            print("overflowed result: {}\n", .{ov[0]});
        } else {
            print("result: {}\n", .{ov[0]});
        }
    }
    ```

Shell

    ```
    $ zig build-exe addWithOverflow_builtin.zig
    $ ./addWithOverflow_builtin
    overflowed result: 9
    
    ```

#### Wrapping Operations §

These operations have guaranteed wraparound semantics. 

  * `+%` (wraparound addition)
  * `-%` (wraparound subtraction)
  * `-%` (wraparound negation)
  * `*%` (wraparound multiplication)

test_wraparound_semantics.zig

    ```zig
    const std = @import("std");
    const expect = std.testing.expect;
    const minInt = std.math.minInt;
    const maxInt = std.math.maxInt;
    
    test "wraparound addition and subtraction" {
        const x: i32 = maxInt(i32);
        const min_val = x +% 1;
        try expect(min_val == minInt(i32));
        const max_val = min_val -% 1;
        try expect(max_val == maxInt(i32));
    }
    ```

Shell

    ```
    $ zig test test_wraparound_semantics.zig
    1/1 test_wraparound_semantics.test.wraparound addition and subtraction...OK
    All 1 tests passed.
    
    ```

### Exact Left Shift Overflow §

At compile-time:

test_comptime_shlExact_overwlow.zig

    ```zig
    comptime {
        const x = @shlExact(@as(u8, 0b01010101), 2);
        _ = x;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_shlExact_overwlow.zig
    /home/andy/dev/zig/doc/langref/test_comptime_shlExact_overwlow.zig:2:15: error: operation caused overflow
        const x = @shlExact(@as(u8, 0b01010101), 2);
                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ```

At runtime:

runtime_shlExact_overflow.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        var x: u8 = 0b01010101; // runtime-known
        _ = &x;
        const y = @shlExact(x, 2);
        std.debug.print("value: {}\n", .{y});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_shlExact_overflow.zig
    $ ./runtime_shlExact_overflow
    thread 197929 panic: left shift overflowed bits
    /home/andy/dev/zig/doc/langref/runtime_shlExact_overflow.zig:6:5: 0x10deab1 in main (runtime_shlExact_overflow)
        const y = @shlExact(x, 2);
        ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de462 in posixCallMainAndExit (runtime_shlExact_overflow)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10de03d in _start (runtime_shlExact_overflow)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Exact Right Shift Overflow §

At compile-time:

test_comptime_shrExact_overflow.zig

    ```zig
    comptime {
        const x = @shrExact(@as(u8, 0b10101010), 2);
        _ = x;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_shrExact_overflow.zig
    /home/andy/dev/zig/doc/langref/test_comptime_shrExact_overflow.zig:2:15: error: exact shift shifted out 1 bits
        const x = @shrExact(@as(u8, 0b10101010), 2);
                  ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ```

At runtime:

runtime_shrExact_overflow.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        var x: u8 = 0b10101010; // runtime-known
        _ = &x;
        const y = @shrExact(x, 2);
        std.debug.print("value: {}\n", .{y});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_shrExact_overflow.zig
    $ ./runtime_shrExact_overflow
    thread 205633 panic: right shift overflowed bits
    /home/andy/dev/zig/doc/langref/runtime_shrExact_overflow.zig:6:5: 0x10deaad in main (runtime_shrExact_overflow)
        const y = @shrExact(x, 2);
        ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de462 in posixCallMainAndExit (runtime_shrExact_overflow)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10de03d in _start (runtime_shrExact_overflow)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Division by Zero §

At compile-time:

test_comptime_division_by_zero.zig

    ```zig
    comptime {
        const a: i32 = 1;
        const b: i32 = 0;
        const c = a / b;
        _ = c;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_division_by_zero.zig
    /home/andy/dev/zig/doc/langref/test_comptime_division_by_zero.zig:4:19: error: division by zero here causes undefined behavior
        const c = a / b;
                      ^

    ```

At runtime:

runtime_division_by_zero.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        var a: u32 = 1;
        var b: u32 = 0;
        _ = .{ &a, &b };
        const c = a / b;
        std.debug.print("value: {}\n", .{c});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_division_by_zero.zig
    $ ./runtime_division_by_zero
    thread 210516 panic: division by zero
    /home/andy/dev/zig/doc/langref/runtime_division_by_zero.zig:7:17: 0x10de9ca in main (runtime_division_by_zero)
        const c = a / b;
                    ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de372 in posixCallMainAndExit (runtime_division_by_zero)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddf4d in _start (runtime_division_by_zero)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Remainder Division by Zero §

At compile-time:

test_comptime_remainder_division_by_zero.zig

    ```zig
    comptime {
        const a: i32 = 10;
        const b: i32 = 0;
        const c = a % b;
        _ = c;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_remainder_division_by_zero.zig
    /home/andy/dev/zig/doc/langref/test_comptime_remainder_division_by_zero.zig:4:19: error: division by zero here causes undefined behavior
        const c = a % b;
                      ^

    ```

At runtime:

runtime_remainder_division_by_zero.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        var a: u32 = 10;
        var b: u32 = 0;
        _ = .{ &a, &b };
        const c = a % b;
        std.debug.print("value: {}\n", .{c});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_remainder_division_by_zero.zig
    $ ./runtime_remainder_division_by_zero
    thread 204394 panic: division by zero
    /home/andy/dev/zig/doc/langref/runtime_remainder_division_by_zero.zig:7:17: 0x10de9ca in main (runtime_remainder_division_by_zero)
        const c = a % b;
                    ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de372 in posixCallMainAndExit (runtime_remainder_division_by_zero)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddf4d in _start (runtime_remainder_division_by_zero)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Exact Division Remainder §

At compile-time:

test_comptime_divExact_remainder.zig

    ```zig
    comptime {
        const a: u32 = 10;
        const b: u32 = 3;
        const c = @divExact(a, b);
        _ = c;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_divExact_remainder.zig
    /home/andy/dev/zig/doc/langref/test_comptime_divExact_remainder.zig:4:15: error: exact division produced remainder
        const c = @divExact(a, b);
                  ^~~~~~~~~~~~~~~

    ```

At runtime:

runtime_divExact_remainder.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        var a: u32 = 10;
        var b: u32 = 3;
        _ = .{ &a, &b };
        const c = @divExact(a, b);
        std.debug.print("value: {}\n", .{c});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_divExact_remainder.zig
    $ ./runtime_divExact_remainder
    thread 206096 panic: exact division produced remainder
    /home/andy/dev/zig/doc/langref/runtime_divExact_remainder.zig:7:15: 0x10de9eb in main (runtime_divExact_remainder)
        const c = @divExact(a, b);
                  ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de372 in posixCallMainAndExit (runtime_divExact_remainder)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddf4d in _start (runtime_divExact_remainder)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Attempt to Unwrap Null §

At compile-time:

test_comptime_unwrap_null.zig

    ```zig
    comptime {
        const optional_number: ?i32 = null;
        const number = optional_number.?;
        _ = number;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_unwrap_null.zig
    /home/andy/dev/zig/doc/langref/test_comptime_unwrap_null.zig:3:35: error: unable to unwrap null
        const number = optional_number.?;
                       ~~~~~~~~~~~~~~~^~

    ```

At runtime:

runtime_unwrap_null.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        var optional_number: ?i32 = null;
        _ = &optional_number;
        const number = optional_number.?;
        std.debug.print("value: {}\n", .{number});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_unwrap_null.zig
    $ ./runtime_unwrap_null
    thread 210622 panic: attempt to use null value
    /home/andy/dev/zig/doc/langref/runtime_unwrap_null.zig:6:35: 0x10de9b6 in main (runtime_unwrap_null)
        const number = optional_number.?;
                                      ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de372 in posixCallMainAndExit (runtime_unwrap_null)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddf4d in _start (runtime_unwrap_null)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

One way to avoid this crash is to test for null instead of assuming non-null, with the `if` expression:

testing_null_with_if.zig

    ```zig
    const print = @import("std").debug.print;
    pub fn main() void {
        const optional_number: ?i32 = null;
    
        if (optional_number) |number| {
            print("got number: {}\n", .{number});
        } else {
            print("it's null\n", .{});
        }
    }
    ```

Shell

    ```
    $ zig build-exe testing_null_with_if.zig
    $ ./testing_null_with_if
    it's null
    
    ```

See also:

  * Optionals

### Attempt to Unwrap Error §

At compile-time:

test_comptime_unwrap_error.zig

    ```zig
    comptime {
        const number = getNumberOrFail() catch unreachable;
        _ = number;
    }
    
    fn getNumberOrFail() !i32 {
        return error.UnableToReturnNumber;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_unwrap_error.zig
    /home/andy/dev/zig/doc/langref/test_comptime_unwrap_error.zig:2:44: error: caught unexpected error 'UnableToReturnNumber'
        const number = getNumberOrFail() catch unreachable;
                                               ^~~~~~~~~~~
    /home/andy/dev/zig/doc/langref/test_comptime_unwrap_error.zig:7:18: note: error returned here
        return error.UnableToReturnNumber;
                     ^~~~~~~~~~~~~~~~~~~~

    ```

At runtime:

runtime_unwrap_error.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        const number = getNumberOrFail() catch unreachable;
        std.debug.print("value: {}\n", .{number});
    }
    
    fn getNumberOrFail() !i32 {
        return error.UnableToReturnNumber;
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_unwrap_error.zig
    $ ./runtime_unwrap_error
    thread 198035 panic: attempt to unwrap error: UnableToReturnNumber
    /home/andy/dev/zig/doc/langref/runtime_unwrap_error.zig:9:5: 0x10df28f in getNumberOrFail (runtime_unwrap_error)
        return error.UnableToReturnNumber;
        ^
    /home/andy/dev/zig/doc/langref/runtime_unwrap_error.zig:4:44: 0x10dea21 in main (runtime_unwrap_error)
        const number = getNumberOrFail() catch unreachable;
                                               ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de3d2 in posixCallMainAndExit (runtime_unwrap_error)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddfad in _start (runtime_unwrap_error)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

One way to avoid this crash is to test for an error instead of assuming a successful result, with the `if` expression:

testing_error_with_if.zig

    ```zig
    const print = @import("std").debug.print;
    
    pub fn main() void {
        const result = getNumberOrFail();
    
        if (result) |number| {
            print("got number: {}\n", .{number});
        } else |err| {
            print("got error: {s}\n", .{@errorName(err)});
        }
    }
    
    fn getNumberOrFail() !i32 {
        return error.UnableToReturnNumber;
    }
    ```

Shell

    ```
    $ zig build-exe testing_error_with_if.zig
    $ ./testing_error_with_if
    got error: UnableToReturnNumber
    
    ```

See also:

  * Errors

### Invalid Error Code §

At compile-time:

test_comptime_invalid_error_code.zig

    ```zig
    comptime {
        const err = error.AnError;
        const number = @intFromError(err) + 10;
        const invalid_err = @errorFromInt(number);
        _ = invalid_err;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_invalid_error_code.zig
    /home/andy/dev/zig/doc/langref/test_comptime_invalid_error_code.zig:4:39: error: integer value '11' represents no error
        const invalid_err = @errorFromInt(number);
                                          ^~~~~~

    ```

At runtime:

runtime_invalid_error_code.zig

    ```zig
    const std = @import("std");
    
    pub fn main() void {
        const err = error.AnError;
        var number = @intFromError(err) + 500;
        _ = &number;
        const invalid_err = @errorFromInt(number);
        std.debug.print("value: {}\n", .{invalid_err});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_invalid_error_code.zig
    $ ./runtime_invalid_error_code
    thread 209716 panic: invalid error code
    /home/andy/dev/zig/doc/langref/runtime_invalid_error_code.zig:7:5: 0x10dea46 in main (runtime_invalid_error_code)
        const invalid_err = @errorFromInt(number);
        ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de3d2 in posixCallMainAndExit (runtime_invalid_error_code)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddfad in _start (runtime_invalid_error_code)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Invalid Enum Cast §

At compile-time:

test_comptime_invalid_enum_cast.zig

    ```zig
    const Foo = enum {
        a,
        b,
        c,
    };
    comptime {
        const a: u2 = 3;
        const b: Foo = @enumFromInt(a);
        _ = b;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_invalid_enum_cast.zig
    /home/andy/dev/zig/doc/langref/test_comptime_invalid_enum_cast.zig:8:20: error: enum 'test_comptime_invalid_enum_cast.Foo' has no tag with value '3'
        const b: Foo = @enumFromInt(a);
                       ^~~~~~~~~~~~~~~
    /home/andy/dev/zig/doc/langref/test_comptime_invalid_enum_cast.zig:1:13: note: enum declared here
    const Foo = enum {
                ^~~~

    ```

At runtime:

runtime_invalid_enum_cast.zig

    ```zig
    const std = @import("std");
    
    const Foo = enum {
        a,
        b,
        c,
    };
    
    pub fn main() void {
        var a: u2 = 3;
        _ = &a;
        const b: Foo = @enumFromInt(a);
        std.debug.print("value: {s}\n", .{@tagName(b)});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_invalid_enum_cast.zig
    $ ./runtime_invalid_enum_cast
    thread 210733 panic: invalid enum value
    /home/andy/dev/zig/doc/langref/runtime_invalid_enum_cast.zig:12:20: 0x10dea0a in main (runtime_invalid_enum_cast)
        const b: Foo = @enumFromInt(a);
                       ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de3e2 in posixCallMainAndExit (runtime_invalid_enum_cast)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddfbd in _start (runtime_invalid_enum_cast)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Invalid Error Set Cast §

At compile-time:

test_comptime_invalid_error_set_cast.zig

    ```zig
    const Set1 = error{
        A,
        B,
    };
    const Set2 = error{
        A,
        C,
    };
    comptime {
        _ = @as(Set2, @errorCast(Set1.B));
    }
    ```

Shell

    ```
    $ zig test test_comptime_invalid_error_set_cast.zig
    /home/andy/dev/zig/doc/langref/test_comptime_invalid_error_set_cast.zig:10:19: error: 'error.B' not a member of error set 'error{A,C}'
        _ = @as(Set2, @errorCast(Set1.B));
                      ^~~~~~~~~~~~~~~~~~

    ```

At runtime:

runtime_invalid_error_set_cast.zig

    ```zig
    const std = @import("std");
    
    const Set1 = error{
        A,
        B,
    };
    const Set2 = error{
        A,
        C,
    };
    pub fn main() void {
        foo(Set1.B);
    }
    fn foo(set1: Set1) void {
        const x: Set2 = @errorCast(set1);
        std.debug.print("value: {}\n", .{x});
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_invalid_error_set_cast.zig
    $ ./runtime_invalid_error_set_cast
    thread 209635 panic: invalid error code
    /home/andy/dev/zig/doc/langref/runtime_invalid_error_set_cast.zig:15:21: 0x10df2fd in foo (runtime_invalid_error_set_cast)
        const x: Set2 = @errorCast(set1);
                        ^
    /home/andy/dev/zig/doc/langref/runtime_invalid_error_set_cast.zig:12:8: 0x10dea2c in main (runtime_invalid_error_set_cast)
        foo(Set1.B);
           ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de412 in posixCallMainAndExit (runtime_invalid_error_set_cast)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10ddfed in _start (runtime_invalid_error_set_cast)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Incorrect Pointer Alignment §

At compile-time:

test_comptime_incorrect_pointer_alignment.zig

    ```zig
    comptime {
        const ptr: *align(1) i32 = @ptrFromInt(0x1);
        const aligned: *align(4) i32 = @alignCast(ptr);
        _ = aligned;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_incorrect_pointer_alignment.zig
    /home/andy/dev/zig/doc/langref/test_comptime_incorrect_pointer_alignment.zig:3:47: error: pointer address 0x1 is not aligned to 4 bytes
        const aligned: *align(4) i32 = @alignCast(ptr);
                                                  ^~~

    ```

At runtime:

runtime_incorrect_pointer_alignment.zig

    ```zig
    const mem = @import("std").mem;
    pub fn main() !void {
        var array align(4) = [_]u32{ 0x11111111, 0x11111111 };
        const bytes = mem.sliceAsBytes(array[0..]);
        if (foo(bytes) != 0x11111111) return error.Wrong;
    }
    fn foo(bytes: []u8) u32 {
        const slice4 = bytes[1..5];
        const int_slice = mem.bytesAsSlice(u32, @as([]align(4) u8, @alignCast(slice4)));
        return int_slice[0];
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_incorrect_pointer_alignment.zig
    $ ./runtime_incorrect_pointer_alignment
    thread 210771 panic: incorrect alignment
    /home/andy/dev/zig/doc/langref/runtime_incorrect_pointer_alignment.zig:9:64: 0x10de7d2 in foo (runtime_incorrect_pointer_alignment)
        const int_slice = mem.bytesAsSlice(u32, @as([]align(4) u8, @alignCast(slice4)));
                                                                   ^
    /home/andy/dev/zig/doc/langref/runtime_incorrect_pointer_alignment.zig:5:12: 0x10de6cf in main (runtime_incorrect_pointer_alignment)
        if (foo(bytes) != 0x11111111) return error.Wrong;
               ^
    /home/andy/dev/zig/lib/std/start.zig:660:37: 0x10de5ba in posixCallMainAndExit (runtime_incorrect_pointer_alignment)
                const result = root.main() catch |err| {
                                        ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10de16d in _start (runtime_incorrect_pointer_alignment)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Wrong Union Field Access §

At compile-time:

test_comptime_wrong_union_field_access.zig

    ```zig
    comptime {
        var f = Foo{ .int = 42 };
        f.float = 12.34;
    }
    
    const Foo = union {
        float: f32,
        int: u32,
    };
    ```

Shell

    ```zig
    $ zig test test_comptime_wrong_union_field_access.zig
    /home/andy/dev/zig/doc/langref/test_comptime_wrong_union_field_access.zig:3:6: error: access of union field 'float' while field 'int' is active
        f.float = 12.34;
        ~^~~~~~
    /home/andy/dev/zig/doc/langref/test_comptime_wrong_union_field_access.zig:6:13: note: union declared here
    const Foo = union {
                ^~~~~

    ```

At runtime:

runtime_wrong_union_field_access.zig

    ```zig
    const std = @import("std");
    
    const Foo = union {
        float: f32,
        int: u32,
    };
    
    pub fn main() void {
        var f = Foo{ .int = 42 };
        bar(&f);
    }
    
    fn bar(f: *Foo) void {
        f.float = 12.34;
        std.debug.print("value: {}\n", .{f.float});
    }
    ```

Shell

    ```
    $ zig build-exe runtime_wrong_union_field_access.zig
    $ ./runtime_wrong_union_field_access
    thread 202573 panic: access of union field 'float' while field 'int' is active
    /home/andy/dev/zig/doc/langref/runtime_wrong_union_field_access.zig:14:6: 0x10e4b18 in bar (runtime_wrong_union_field_access)
        f.float = 12.34;
         ^
    /home/andy/dev/zig/doc/langref/runtime_wrong_union_field_access.zig:10:8: 0x10e426c in main (runtime_wrong_union_field_access)
        bar(&f);
           ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10e3c52 in posixCallMainAndExit (runtime_wrong_union_field_access)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10e382d in _start (runtime_wrong_union_field_access)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

This safety is not available for `extern` or `packed` unions. 

To change the active field of a union, assign the entire union, like this: 

change_active_union_field.zig

    ```zig
    const std = @import("std");
    
    const Foo = union {
        float: f32,
        int: u32,
    };
    
    pub fn main() void {
        var f = Foo{ .int = 42 };
        bar(&f);
    }
    
    fn bar(f: *Foo) void {
        f.* = Foo{ .float = 12.34 };
        std.debug.print("value: {}\n", .{f.float});
    }
    ```

Shell

    ```
    $ zig build-exe change_active_union_field.zig
    $ ./change_active_union_field
    value: 1.234e1
    
    ```

To change the active field of a union when a meaningful value for the field is not known, use undefined, like this: 

undefined_active_union_field.zig

    ```zig
    const std = @import("std");
    
    const Foo = union {
        float: f32,
        int: u32,
    };
    
    pub fn main() void {
        var f = Foo{ .int = 42 };
        f = Foo{ .float = undefined };
        bar(&f);
        std.debug.print("value: {}\n", .{f.float});
    }
    
    fn bar(f: *Foo) void {
        f.float = 12.34;
    }
    ```

Shell

    ```
    $ zig build-exe undefined_active_union_field.zig
    $ ./undefined_active_union_field
    value: 1.234e1
    
    ```

See also:

  * union
  * extern union

### Out of Bounds Float to Integer Cast §

This happens when casting a float to an integer where the float has a value outside the integer type's range. 

At compile-time:

test_comptime_out_of_bounds_float_to_integer_cast.zig

    ```zig
    comptime {
        const float: f32 = 4294967296;
        const int: i32 = @intFromFloat(float);
        _ = int;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_out_of_bounds_float_to_integer_cast.zig
    /home/andy/dev/zig/doc/langref/test_comptime_out_of_bounds_float_to_integer_cast.zig:3:36: error: float value '4294967296' cannot be stored in integer type 'i32'
        const int: i32 = @intFromFloat(float);
                                       ^~~~~

    ```

At runtime:

runtime_out_of_bounds_float_to_integer_cast.zig

    ```zig
    pub fn main() void {
        var float: f32 = 4294967296; // runtime-known
        _ = &float;
        const int: i32 = @intFromFloat(float);
        _ = int;
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_out_of_bounds_float_to_integer_cast.zig
    $ ./runtime_out_of_bounds_float_to_integer_cast
    thread 200414 panic: integer part of floating point value out of bounds
    /home/andy/dev/zig/doc/langref/runtime_out_of_bounds_float_to_integer_cast.zig:4:22: 0x10de8d9 in main (runtime_out_of_bounds_float_to_integer_cast)
        const int: i32 = @intFromFloat(float);
                         ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de272 in posixCallMainAndExit (runtime_out_of_bounds_float_to_integer_cast)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10dde4d in _start (runtime_out_of_bounds_float_to_integer_cast)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```

### Pointer Cast Invalid Null §

This happens when casting a pointer with the address 0 to a pointer which may not have the address 0. For example, C Pointers, Optional Pointers, and allowzero pointers allow address zero, but normal Pointers do not. 

At compile-time:

test_comptime_invalid_null_pointer_cast.zig

    ```zig
    comptime {
        const opt_ptr: ?*i32 = null;
        const ptr: *i32 = @ptrCast(opt_ptr);
        _ = ptr;
    }
    ```

Shell

    ```zig
    $ zig test test_comptime_invalid_null_pointer_cast.zig
    /home/andy/dev/zig/doc/langref/test_comptime_invalid_null_pointer_cast.zig:3:32: error: null pointer casted to type '*i32'
        const ptr: *i32 = @ptrCast(opt_ptr);
                                   ^~~~~~~

    ```

At runtime:

runtime_invalid_null_pointer_cast.zig

    ```zig
    pub fn main() void {
        var opt_ptr: ?*i32 = null;
        _ = &opt_ptr;
        const ptr: *i32 = @ptrCast(opt_ptr);
        _ = ptr;
    }
    ```

Shell

    ```zig
    $ zig build-exe runtime_invalid_null_pointer_cast.zig
    $ ./runtime_invalid_null_pointer_cast
    thread 202309 panic: cast causes pointer to be null
    /home/andy/dev/zig/doc/langref/runtime_invalid_null_pointer_cast.zig:4:23: 0x10de88c in main (runtime_invalid_null_pointer_cast)
        const ptr: *i32 = @ptrCast(opt_ptr);
                          ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10de252 in posixCallMainAndExit (runtime_invalid_null_pointer_cast)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10dde2d in _start (runtime_invalid_null_pointer_cast)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    (process terminated by signal)
    
    ```