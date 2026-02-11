# Pointers

Zig has two kinds of pointers: single-item and many-item.

📚 **Runnable Examples:** `zig_docs_std/Examples/pointers.tests.zig`

## Overview

Use pointer types to model exact memory intent:

- `*T` for exactly one item.
- `[*]T` for contiguous memory when length is not encoded.
- `[]T` when you want pointer + length and bounds-checked indexing.

Prefer `[]T` at API boundaries unless you have a concrete reason to require a raw pointer form.

## Pointer Kind Selection

Use this decision order:

1. Need bounds and length in the value? Use `[]T`.
2. Need exactly one object? Use `*T`.
3. Need pointer arithmetic / unknown-length buffer walk? Use `[*]T`.
4. Need C string or sentinel protocol? Use `[*:x]T`.

When in doubt, start with slices and convert to pointer forms only at lower-level boundaries.

## Unsafe Pointer Checklist

Before pointer casts/arithmetic/dereference across boundaries:

1. **Alignment:** Is the address aligned for the target type?
2. **Lifetime:** Does backing memory outlive all uses?
3. **Bounds:** Is index/range access within allocated region?
4. **Sentinel contract:** If using sentinel types, is sentinel guaranteed?
5. **Mutability:** Are `const` vs mutable guarantees preserved?
6. **Concurrency:** Is there race-free ownership/synchronization for mutable access?
      

      
          `*T` - single-item pointer to exactly one item.
            
              
- Supports deref syntax: `ptr.*`
              
- Supports slice syntax: `ptr[0..1]`
              
- Supports pointer subtraction: `ptr - ptr`
            
          
          `[*]T` - many-item pointer to unknown number of items.
            
              
- Supports index syntax: `ptr[i]`
              
- Supports slice syntax: `ptr[start..end]` and `ptr[start..]`
              
- Supports pointer-integer arithmetic: `ptr + int`, `ptr - int`
              
- Supports pointer subtraction: `ptr - ptr`
            
            `T` must have a known size, which means that it cannot be
            `anyopaque` or any other [opaque type](#opaque).
          
      
      

These types are closely related to [Arrays](#Arrays) and [Slices](#Slices):

        
            `*[N]T` - pointer to N items, same as single-item pointer to an array.
            
                
- Supports index syntax: `array_ptr[i]`
                
- Supports slice syntax: `array_ptr[start..end]`
                
- Supports len property: `array_ptr.len`
                
- Supports pointer subtraction: `array_ptr - array_ptr`
            
            
        
        
            `[]T` - is a slice (a fat pointer, which contains a pointer of type `[*]T` and a length).
            
                
- Supports index syntax: `slice[i]`
                
- Supports slice syntax: `slice[start..end]`
                
- Supports len property: `slice.len`
            
            
        
        

Use `&x` to obtain a single-item pointer:

      test_single_item_pointer.zig
```zig
const expect = @import("std").testing.expect;

test "address of syntax" {
    // Get the address of a variable:
    const x: i32 = 1234;
    const x_ptr = &x;

    // Dereference a pointer:
    try expect(x_ptr.* == 1234);

    // When you get the address of a const variable, you get a const single-item pointer.
    try expect(@TypeOf(x_ptr) == *const i32);

    // If you want to mutate the value, you'd need an address of a mutable variable:
    var y: i32 = 5678;
    const y_ptr = &y;
    try expect(@TypeOf(y_ptr) == *i32);
    y_ptr.* += 1;
    try expect(y_ptr.* == 5679);
}

test "pointer array access" {
    // Taking an address of an individual element gives a
    // single-item pointer. This kind of pointer
    // does not support pointer arithmetic.
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    const ptr = &array[2];
    try expect(@TypeOf(ptr) == *u8);

    try expect(array[2] == 3);
    ptr.* += 1;
    try expect(array[2] == 4);
}

test "slice syntax" {
    // Get a pointer to a variable:
    var x: i32 = 1234;
    const x_ptr = &x;

    // Convert to array pointer using slice syntax:
    const x_array_ptr = x_ptr[0..1];
    try expect(@TypeOf(x_array_ptr) == *[1]i32);

    // Coerce to many-item pointer:
    const x_many_ptr: [*]i32 = x_array_ptr;
    try expect(x_many_ptr[0] == 1234);
}
```
Shell$ zig test test_single_item_pointer.zig
1/3 test_single_item_pointer.test.address of syntax...OK
2/3 test_single_item_pointer.test.pointer array access...OK
3/3 test_single_item_pointer.test.slice syntax...OK
All 3 tests passed.

      

       Zig supports pointer arithmetic. It's better to assign the pointer to `[*]T` and increment that variable. For example, directly incrementing the pointer from a slice will corrupt it.
      

      test_pointer_arithmetic.zig
```zig
const expect = @import("std").testing.expect;

test "pointer arithmetic with many-item pointer" {
    const array = [_]i32{ 1, 2, 3, 4 };
    var ptr: [*]const i32 = &array;

    try expect(ptr[0] == 1);
    ptr += 1;
    try expect(ptr[0] == 2);

    // slicing a many-item pointer without an end is equivalent to
    // pointer arithmetic: `ptr[start..] == ptr + start`
    try expect(ptr[1..] == ptr + 1);

    // subtraction between any two pointers except slices based on element size is supported
    try expect(&ptr[1] - &ptr[0] == 1);
}

test "pointer arithmetic with slices" {
    var array = [_]i32{ 1, 2, 3, 4 };
    var length: usize = 0; // var to make it runtime-known
    _ = &length; // suppress 'var is never mutated' error
    var slice = array[length..array.len];

    try expect(slice[0] == 1);
    try expect(slice.len == 4);

    slice.ptr += 1;
    // now the slice is in an bad state since len has not been updated

    try expect(slice[0] == 2);
    try expect(slice.len == 4);
}
```
Shell$ zig test test_pointer_arithmetic.zig
1/2 test_pointer_arithmetic.test.pointer arithmetic with many-item pointer...OK
2/2 test_pointer_arithmetic.test.pointer arithmetic with slices...OK
All 2 tests passed.

      

        In Zig, we generally prefer [Slices](#Slices) rather than [Sentinel-Terminated Pointers](#Sentinel-Terminated-Pointers).
        You can turn an array or pointer into a slice using slice syntax.
      

      

        Slices have bounds checking and are therefore protected
        against this kind of Illegal Behavior. This is one reason
        we prefer slices to pointers.
      

      test_slice_bounds.zig
```zig
const expect = @import("std").testing.expect;

test "pointer slicing" {
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    var start: usize = 2; // var to make it runtime-known
    _ = &start; // suppress 'var is never mutated' error
    const slice = array[start..4];
    try expect(slice.len == 2);

    try expect(array[3] == 4);
    slice[1] += 1;
    try expect(array[3] == 5);
}
```
Shell$ zig test test_slice_bounds.zig
1/1 test_slice_bounds.test.pointer slicing...OK
All 1 tests passed.

      

Pointers work at compile-time too, as long as the code does not depend on
      an undefined memory layout:

      test_comptime_pointers.zig
```zig
const expect = @import("std").testing.expect;

test "comptime pointers" {
    comptime {
        var x: i32 = 1;
        const ptr = &x;
        ptr.* += 1;
        x += 1;
        try expect(ptr.* == 3);
    }
}
```
Shell$ zig test test_comptime_pointers.zig
1/1 test_comptime_pointers.test.comptime pointers...OK
All 1 tests passed.

      

To convert an integer address into a pointer, use `@ptrFromInt`.
      To convert a pointer to an integer, use `@intFromPtr`:

      test_integer_pointer_conversion.zig
```zig
const expect = @import("std").testing.expect;

test "@intFromPtr and @ptrFromInt" {
    const ptr: *i32 = @ptrFromInt(0xdeadbee0);
    const addr = @intFromPtr(ptr);
    try expect(@TypeOf(addr) == usize);
    try expect(addr == 0xdeadbee0);
}
```
Shell$ zig test test_integer_pointer_conversion.zig
1/1 test_integer_pointer_conversion.test.@intFromPtr and @ptrFromInt...OK
All 1 tests passed.

      

Zig is able to preserve memory addresses in comptime code, as long as
      the pointer is never dereferenced:

      test_comptime_pointer_conversion.zig
```zig
const expect = @import("std").testing.expect;

test "comptime @ptrFromInt" {
    comptime {
        // Zig is able to do this at compile-time, as long as
        // ptr is never dereferenced.
        const ptr: *i32 = @ptrFromInt(0xdeadbee0);
        const addr = @intFromPtr(ptr);
        try expect(@TypeOf(addr) == usize);
        try expect(addr == 0xdeadbee0);
    }
}
```
Shell$ zig test test_comptime_pointer_conversion.zig
1/1 test_comptime_pointer_conversion.test.comptime @ptrFromInt...OK
All 1 tests passed.

      

      [@ptrCast](#ptrCast) converts a pointer's element type to another. This
      creates a new pointer that can cause undetectable Illegal Behavior
      depending on the loads and stores that pass through it. Generally, other
      kinds of type conversions are preferable to
      `@ptrCast` if possible.
      

      test_pointer_casting.zig
```zig
const std = @import("std");
const expect = std.testing.expect;

test "pointer casting" {
    const bytes align(@alignOf(u32)) = [_]u8{ 0x12, 0x12, 0x12, 0x12 };
    const u32_ptr: *const u32 = @ptrCast(&bytes);
    try expect(u32_ptr.* == 0x12121212);

    // Even this example is contrived - there are better ways to do the above than
    // pointer casting. For example, using a slice narrowing cast:
    const u32_value = std.mem.bytesAsSlice(u32, bytes[0..])[0];
    try expect(u32_value == 0x12121212);

    // And even another way, the most straightforward way to do it:
    try expect(@as(u32, @bitCast(bytes)) == 0x12121212);
}

test "pointer child type" {
    // pointer types have a `child` field which tells you the type they point to.
    try expect(@typeInfo(*u32).pointer.child == u32);
}
```
Shell$ zig test test_pointer_casting.zig
1/2 test_pointer_casting.test.pointer casting...OK
2/2 test_pointer_casting.test.pointer child type...OK
All 2 tests passed.

      

See also:

- [Optional Pointers](#Optional-Pointers)

- [@ptrFromInt](#ptrFromInt)

- [@intFromPtr](#intFromPtr)

- [C Pointers](#C-Pointers)

      
## [volatile](#toc-volatile) §

      

Loads and stores are assumed to not have side effects. If a given load or store
      should have side effects, such as Memory Mapped Input/Output (MMIO), use `volatile`.
      In the following code, loads and stores with `mmio_ptr` are guaranteed to all happen
      and in the same order as in source code:

      test_volatile.zig
```zig
const expect = @import("std").testing.expect;

test "volatile" {
    const mmio_ptr: *volatile u8 = @ptrFromInt(0x12345678);
    try expect(@TypeOf(mmio_ptr) == *volatile u8);
}
```
Shell$ zig test test_volatile.zig
1/1 test_volatile.test.volatile...OK
All 1 tests passed.

      

      Note that `volatile` is unrelated to concurrency and [Atomics](#Atomics).
      If you see code that is using `volatile` for something other than Memory Mapped
      Input/Output, it is probably a bug.
      

      

      
## [Alignment](#toc-Alignment) §

      

      Each type has an **alignment** - a number of bytes such that,
      when a value of the type is loaded from or stored to memory,
      the memory address must be evenly divisible by this number. You can use
      [@alignOf](#alignOf) to find out this value for any type.
      

      

      Alignment depends on the CPU architecture, but is always a power of two, and
      less than `1 << 29`.
      

      

      In Zig, a pointer type has an alignment value. If the value is equal to the
      alignment of the underlying type, it can be omitted from the type:
      

      test_variable_alignment.zig
```zig
const std = @import("std");
const builtin = @import("builtin");
const expect = std.testing.expect;

test "variable alignment" {
    var x: i32 = 1234;
    const align_of_i32 = @alignOf(@TypeOf(x));
    try expect(@TypeOf(&x) == *i32);
    try expect(*i32 == *align(align_of_i32) i32);
    if (builtin.target.cpu.arch == .x86_64) {
        try expect(@typeInfo(*i32).pointer.alignment == 4);
    }
}
```
Shell$ zig test test_variable_alignment.zig
1/1 test_variable_alignment.test.variable alignment...OK
All 1 tests passed.

      

In the same way that a `*i32` can be [coerced](#Type-Coercion) to a
          `*const i32`, a pointer with a larger alignment can be implicitly
      cast to a pointer with a smaller alignment, but not vice versa.
      

      

      You can specify alignment on variables and functions. If you do this, then
      pointers to them get the specified alignment:
      

      test_variable_func_alignment.zig
```zig
const expect = @import("std").testing.expect;

var foo: u8 align(4) = 100;

test "global variable alignment" {
    try expect(@typeInfo(@TypeOf(&foo)).pointer.alignment == 4);
    try expect(@TypeOf(&foo) == *align(4) u8);
    const as_pointer_to_array: *align(4) [1]u8 = &foo;
    const as_slice: []align(4) u8 = as_pointer_to_array;
    const as_unaligned_slice: []u8 = as_slice;
    try expect(as_unaligned_slice[0] == 100);
}

fn derp() align(@sizeOf(usize) * 2) i32 {
    return 1234;
}
fn noop1() align(1) void {}
fn noop4() align(4) void {}

test "function alignment" {
    try expect(derp() == 1234);
    try expect(@TypeOf(derp) == fn () i32);
    try expect(@TypeOf(&derp) == *align(@sizeOf(usize) * 2) const fn () i32);

    noop1();
    try expect(@TypeOf(noop1) == fn () void);
    try expect(@TypeOf(&noop1) == *align(1) const fn () void);

    noop4();
    try expect(@TypeOf(noop4) == fn () void);
    try expect(@TypeOf(&noop4) == *align(4) const fn () void);
}
```
Shell$ zig test test_variable_func_alignment.zig
1/2 test_variable_func_alignment.test.global variable alignment...OK
2/2 test_variable_func_alignment.test.function alignment...OK
All 2 tests passed.

      

      If you have a pointer or a slice that has a small alignment, but you know that it actually
      has a bigger alignment, use [@alignCast](#alignCast) to change the
      pointer into a more aligned pointer. This is a no-op at runtime, but inserts a
      [safety check](#Incorrect-Pointer-Alignment):
      

      test_incorrect_pointer_alignment.zig
```zig
const std = @import("std");

test "pointer alignment safety" {
    var array align(4) = [_]u32{ 0x11111111, 0x11111111 };
    const bytes = std.mem.sliceAsBytes(array[0..]);
    try std.testing.expect(foo(bytes) == 0x11111111);
}
fn foo(bytes: []u8) u32 {
    const slice4 = bytes[1..5];
    const int_slice = std.mem.bytesAsSlice(u32, @as([]align(4) u8, @alignCast(slice4)));
    return int_slice[0];
}
```
Shell$ zig test test_incorrect_pointer_alignment.zig
1/1 test_incorrect_pointer_alignment.test.pointer alignment safety...thread 3447318 panic: incorrect alignment
/home/ci/zig-bootstrap/zig/doc/langref/test_incorrect_pointer_alignment.zig:10:68: 0x103f1f6 in foo (test_incorrect_pointer_alignment.zig)
    const int_slice = std.mem.bytesAsSlice(u32, @as([]align(4) u8, @alignCast(slice4)));
                                                                   ^
/home/ci/zig-bootstrap/zig/doc/langref/test_incorrect_pointer_alignment.zig:6:31: 0x103f08e in test.pointer alignment safety (test_incorrect_pointer_alignment.zig)
    try std.testing.expect(foo(bytes) == 0x11111111);
                              ^
/home/ci/zig-bootstrap/out/host/lib/zig/compiler/test_runner.zig:255:25: 0x11d0ff2 in mainTerminal (test_runner.zig)
        if (test_fn.func()) |_| {
                        ^
/home/ci/zig-bootstrap/out/host/lib/zig/compiler/test_runner.zig:70:28: 0x11caea2 in main (test_runner.zig)
        return mainTerminal(init);
                           ^
/home/ci/zig-bootstrap/out/host/lib/zig/std/start.zig:680:88: 0x11c7517 in callMain (std.zig)
    if (fn_info.params[0].type.? == std.process.Init.Minimal) return wrapMain(root.main(.{
                                                                                       ^
/home/ci/zig-bootstrap/out/host/lib/zig/std/start.zig:190:5: 0x11c6f41 in _start (std.zig)
    asm volatile (switch (native_arch) {
    ^
error: the following test command terminated with signal ABRT:
/home/ci/zig-bootstrap/out/zig-local-cache/o/a7f2f5b9d42a63e4655aa55e2afe9e67/test --seed=0x562512eb

      

      
## [allowzero](#toc-allowzero) §

      

      This pointer attribute allows a pointer to have address zero. This is only ever needed on the
      freestanding OS target, where the address zero is mappable. If you want to represent null pointers, use
      [Optional Pointers](#Optional-Pointers) instead. [Optional Pointers](#Optional-Pointers) with `allowzero`
      are not the same size as pointers. In this code example, if the pointer
      did not have the `allowzero` attribute, this would be a
      [Pointer Cast Invalid Null](#Pointer-Cast-Invalid-Null) panic:
      

      test_allowzero.zig
```zig
const std = @import("std");
const expect = std.testing.expect;

test "allowzero" {
    var zero: usize = 0; // var to make to runtime-known
    _ = &zero; // suppress 'var is never mutated' error
    const ptr: *allowzero i32 = @ptrFromInt(zero);
    try expect(@intFromPtr(ptr) == 0);
}
```
Shell$ zig test test_allowzero.zig
1/1 test_allowzero.test.allowzero...OK
All 1 tests passed.

      

      
## [Sentinel-Terminated Pointers](#toc-Sentinel-Terminated-Pointers) §

      

      The syntax `[*:x]T` describes a pointer that
      has a length determined by a sentinel value. This provides protection
      against buffer overflow and overreads.
      

      sentinel-terminated_pointer.zig
```zig
const std = @import("std");

// This is also available as `std.c.printf`.
pub extern "c" fn printf(format: [*:0]const u8, ...) c_int;

pub fn main() anyerror!void {
    _ = printf("Hello, world!\n"); // OK

    const msg = "Hello, world!\n";
    const non_null_terminated_msg: [msg.len]u8 = msg.*;
    _ = printf(&non_null_terminated_msg);
}
```
Shell$ zig build-exe sentinel-terminated_pointer.zig -lc
/home/ci/zig-bootstrap/zig/doc/langref/sentinel-terminated_pointer.zig:11:16: error: expected type '[*:0]const u8', found '*const [14]u8'
    _ = printf(&non_null_terminated_msg);
               ^~~~~~~~~~~~~~~~~~~~~~~~
/home/ci/zig-bootstrap/zig/doc/langref/sentinel-terminated_pointer.zig:11:16: note: destination pointer requires '0' sentinel
/home/ci/zig-bootstrap/zig/doc/langref/sentinel-terminated_pointer.zig:4:34: note: parameter type declared here
pub extern "c" fn printf(format: [*:0]const u8, ...) c_int;
                                 ^~~~~~~~~~~~~
referenced by:
    callMain [inlined]: /home/ci/zig-bootstrap/out/host/lib/zig/std/start.zig:679:59
    callMainWithArgs [inlined]: /home/ci/zig-bootstrap/out/host/lib/zig/std/start.zig:629:20
    main: /home/ci/zig-bootstrap/out/host/lib/zig/std/start.zig:656:28
    1 reference(s) hidden; use '-freference-trace=4' to see all references

      

See also:

- [Sentinel-Terminated Slices](#Sentinel-Terminated-Slices)

- [Sentinel-Terminated Arrays](#Sentinel-Terminated-Arrays)
