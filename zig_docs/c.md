# C

Although Zig is independent of C, and, unlike most other languages, does not depend on libc,
Zig acknowledges the importance of interacting with existing C code.

There are a few ways that Zig facilitates C interop.

## [C Type Primitives](#toc-C-Type-Primitives) §

These have guaranteed C ABI compatibility and can be used like any other type.

- `c_char`

- `c_short`

- `c_ushort`

- `c_int`

- `c_uint`

- `c_long`

- `c_ulong`

- `c_longlong`

- `c_ulonglong`

- `c_longdouble`

To interop with the C `void` type, use `anyopaque`.

See also:

- [Primitive Types](#Primitive-Types)

## [Import from C Header File](#toc-Import-from-C-Header-File) §

The `@cImport` builtin function can be used
to directly import symbols from .h files:

cImport_builtin.zig
```zig
const c = @cImport({
    // See https://github.com/ziglang/zig/issues/515
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
});
pub fn main() void {
    if (@import("builtin").os.tag == .netbsd) return; // https://github.com/Vexu/arocc/issues/960
    _ = c.printf("hello\n");
}
```
Shell$ zig build-exe cImport_builtin.zig -lc
$ ./cImport_builtin
hello

The `@cImport` function takes an expression as a parameter.
This expression is evaluated at compile-time and is used to control
preprocessor directives and include multiple .h files:

@cImport Expression
```zig
const builtin = @import("builtin");

const c = @cImport({
    @cDefine("NDEBUG", builtin.mode == .ReleaseFast);
    if (something) {
  @cDefine("_GNU_SOURCE", {});
    }
    @cInclude("stdlib.h");
    if (something) {
  @cUndef("_GNU_SOURCE");
    }
    @cInclude("soundio.h");
});
```

See also:

- [@cImport](#cImport)

- [@cInclude](#cInclude)

- [@cDefine](#cDefine)

- [@cUndef](#cUndef)

- [@import](#import)

## [C Translation CLI](#toc-C-Translation-CLI) §

Zig's C translation capability is available as a CLI tool via zig translate-c.
It requires a single filename as an argument. It may also take a set of optional flags that are
forwarded to clang. It writes the translated file to stdout.

### [Command line flags](#toc-Command-line-flags) §

    -I:
    Specify a search directory for include files. May be used multiple times. Equivalent to

    clang's -I flag. The current directory is *not* included by default;
    use -I. to include it.

    -D: Define a preprocessor macro. Equivalent to

    clang's -D flag.

    -cflags [flags] --: Pass arbitrary additional
    command line
    flags to clang. Note: the list of flags must end with --

    -target: The [target triple](#Targets) for the translated Zig code.
    If no target is specified, the current host target will be used.

### [Using -target and -cflags](#toc-Using--target-and--cflags) §

  **Important!** When translating C code with zig translate-c,
  you **must** use the same -target triple that you will use when compiling
  the translated code. In addition, you **must** ensure that the -cflags used,
  if any, match the cflags used by code on the target system. Using the incorrect -target
  or -cflags could result in clang or Zig parse failures, or subtle ABI incompatibilities
  when linking with C code.

varytarget.h
```zig
long FOO = __LONG_MAX__;
```

Shell$ zig translate-c -target thumb-freestanding-gnueabihf varytarget.h|grep FOO
pub export var FOO: c_long = 2147483647;
$ zig translate-c -target x86_64-macos-gnu varytarget.h|grep FOO
pub export var FOO: c_long = 9223372036854775807;

varycflags.h
```zig
enum FOO { BAR };
int do_something(enum FOO foo);
```

Shell$ zig translate-c varycflags.h|grep -B1 do_something
pub const enum_FOO = c_uint;
pub extern fn do_something(foo: enum_FOO) c_int;
$ zig translate-c -cflags -fshort-enums -- varycflags.h|grep -B1 do_something
pub const enum_FOO = u8;
pub extern fn do_something(foo: enum_FOO) c_int;

### [@cImport vs translate-c](#toc-cImport-vs-translate-c) §

`@cImport` and zig translate-c use the same underlying
C translation functionality, so on a technical level they are equivalent. In practice,
`@cImport` is useful as a way to quickly and easily access numeric constants, typedefs,
and record types without needing any extra setup. If you need to pass [cflags](#Using--target-and--cflags)
to clang, or if you would like to edit the translated code, it is recommended to use
zig translate-c and save the results to a file. Common reasons for editing
the generated code include: changing `anytype` parameters in function-like macros to more
specific types; changing `[*c]T` pointers to `[*]T` or
`*T` pointers for improved type safety; and
[enabling or disabling runtime safety](#setRuntimeSafety) within specific functions.

See also:

- [Targets](#Targets)

- [C Type Primitives](#C-Type-Primitives)

- [Pointers](#Pointers)

- [C Pointers](#C-Pointers)

- [Import from C Header File](#Import-from-C-Header-File)

- [@cInclude](#cInclude)

- [@cImport](#cImport)

- [@setRuntimeSafety](#setRuntimeSafety)

## [C Translation Caching](#toc-C-Translation-Caching) §

  The C translation feature (whether used via zig translate-c or
  `@cImport`) integrates with the Zig caching system. Subsequent runs with
  the same source file, target, and cflags will use the cache instead of repeatedly translating
  the same code.

  To see where the cached files are stored when compiling code that uses `@cImport`,
  use the --verbose-cimport flag:

verbose_cimport_flag.zig
```zig
const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
});
pub fn main() void {
    if (@import("builtin").os.tag == .netbsd) return; // https://github.com/Vexu/arocc/issues/960
    _ = c;
}
```
Shell$ zig build-exe verbose_cimport_flag.zig -lc --verbose-cimport
info(compilation): writing C import source to /home/ci/zig-bootstrap/out/zig-local-cache/tmp/518c7dc66918086c/cimport.h
--zig-integration -x c -isystem /home/ci/zig-bootstrap/out/host/lib/zig/compiler/aro/include -fno-PIE -fPIC -gdwarf-4 -gdwarf32 -fno-lto -MD -MV -MF /home/ci/zig-bootstrap/out/zig-local-cache/tmp/518c7dc66918086c/cimport.h.d -fhosted -nostdinc -D__GLIBC_MINOR__=31 -isystem /home/ci/zig-bootstrap/out/host/lib/zig/include -isystem /usr/include -isystem /usr/include/x86_64-linux-gnu -O0 -target x86_64-linux.5.10...5.10-gnu.2.31 -mcpu=znver2-16bit_mode-32bit_mode-3dnow-3dnowa+64bit+adx+aes+allow_light_256_bit-amx_avx512-amx_bf16-amx_complex-amx_fp16-amx_fp8-amx_int8-amx_movrs-amx_tf32-amx_tile-amx_transpose+avx-avx10_1-avx10_2+avx2-avx512bf16-avx512bitalg-avx512bw-avx512cd-avx512dq-avx512er-avx512f-avx512fp16-avx512ifma-avx512pf-avx512vbmi-avx512vbmi2-avx512vl-avx512vnni-avx512vp2intersect-avx512vpopcntdq-avxifma-avxneconvert-avxvnni-avxvnniint16-avxvnniint8+bmi+bmi2-branch_hint+branchfusion-bsf_bsr_0_clobbers_result-ccmp-cf-cldemote+clflushopt+clwb+clzero+cmov-cmpccxadd+crc32+cx16+cx8-egpr-enqcmd-ermsb-evex512+f16c-false_deps_getmant-false_deps_lzcnt_tzcnt-false_deps_mulc-false_deps_mullq-false_deps_perm-false_deps_popcnt-false_deps_range-fast_11bytenop+fast_15bytenop-fast_7bytenop+fast_bextr-fast_dpwssd-fast_gather-fast_hops+fast_imm16+fast_lzcnt+fast_movbe+fast_scalar_fsqrt+fast_scalar_shift_masks-fast_shld_rotate-fast_variable_crosslane_shuffle+fast_variable_perlane_shuffle+fast_vector_fsqrt-fast_vector_shift_masks-faster_shift_than_shuffle+fma-fma4+fsgsbase-fsrm+fxsr-gfni-harden_sls_ijmp-harden_sls_ret-hreset-idivl_to_divb+idivq_to_divl-inline_asm_use_gpr32-invpcid-kl-lea_sp-lea_uses_ag-lvi_cfi-lvi_load_hardening-lwp+lzcnt-macrofusion+mmx+movbe-movdir64b-movdiri-movrs+mwaitx-ndd-nf-no_bypass_delay-no_bypass_delay_blend-no_bypass_delay_mov-no_bypass_delay_shuffle+nopl-pad_short_functions+pclmul-pconfig-pku+popcnt-ppx-prefer_128_bit-prefer_256_bit-prefer_mask_registers-prefer_movmsk_over_vtest-prefer_no_gather-prefer_no_scatter-prefetchi-prefetchwt1+prfchw-ptwrite-push2pop2-raoint+rdpid+rdpru+rdrnd+rdseed-retpoline-retpoline_external_thunk-retpoline_indirect_branches-retpoline_indirect_calls-rtm+sahf+sbb_dep_breaking-serialize-seses-sgx+sha-sha512-shstk-slow_3ops_lea-slow_incdec-slow_lea-slow_pmaddwd-slow_pmulld+slow_shld-slow_two_mem_ops-slow_unaligned_mem_16-slow_unaligned_mem_32-sm3-sm4+smap+smep-soft_float+sse+sse2+sse3+sse4_1+sse4_2+sse4a-sse_unaligned_mem+ssse3-tagged_globals-tbm-tsxldtrk-tuning_fast_imm_vector_shift-uintr-use_glm_div_sqrt_costs-use_slm_arith_costs-usermsr-vaes-vpclmulqdq+vzeroupper-waitpkg+wbnoinvd-widekl+x87-xop+xsave+xsavec+xsaveopt+xsaves-zu /home/ci/zig-bootstrap/out/zig-local-cache/tmp/518c7dc66918086c/cimport.h -o /home/ci/zig-bootstrap/out/zig-local-cache/tmp/518c7dc66918086c/cimport.zig
info(compilation): processing dep file at /home/ci/zig-bootstrap/out/zig-local-cache/tmp/518c7dc66918086c/cimport.h.d
info(compilation): renaming tmp/518c7dc66918086c to o/b970e0ec5d1613de66d35cc738f53b3e
$ ./verbose_cimport_flag

  cimport.h contains the file to translate (constructed from calls to
  `@cInclude`, `@cDefine`, and `@cUndef`),
  cimport.h.d is the list of file dependencies, and
  cimport.zig contains the translated output.

See also:

- [Import from C Header File](#Import-from-C-Header-File)

- [C Translation CLI](#C-Translation-CLI)

- [@cInclude](#cInclude)

- [@cImport](#cImport)

## [Translation failures](#toc-Translation-failures) §

  Some C constructs cannot be translated to Zig - for example, *goto*,
  structs with bitfields, and token-pasting macros. Zig employs *demotion* to allow translation
  to continue in the face of non-translatable entities.

  Demotion comes in three varieties - [opaque](#opaque), *extern*, and
  `@compileError`.

  C structs and unions that cannot be translated correctly will be translated as `opaque{}`.
  Functions that contain opaque types or code constructs that cannot be translated will be demoted
  to `extern` declarations.

  Thus, non-translatable types can still be used as pointers, and non-translatable functions
  can be called so long as the linker is aware of the compiled function.

  `@compileError` is used when top-level definitions (global variables,
  function prototypes, macros) cannot be translated or demoted. Since Zig uses lazy analysis for
  top-level declarations, untranslatable entities will not cause a compile error in your code unless
  you actually use them.

See also:

- [opaque](#opaque)

- [extern](#extern)

- [@compileError](#compileError)

## [C Macros](#toc-C-Macros) §

  C Translation makes a best-effort attempt to translate function-like macros into equivalent
  Zig functions. Since C macros operate at the level of lexical tokens, not all C macros
  can be translated to Zig. Macros that cannot be translated will be demoted to
  `@compileError`. Note that C code which *uses* macros will be
  translated without any additional issues (since Zig operates on the pre-processed source
  with macros expanded). It is merely the macros themselves which may not be translatable to
  Zig.

Consider the following example:

macro.c
```zig
#define MAKELOCAL(NAME, INIT) int NAME = INIT
int foo(void) {
   MAKELOCAL(a, 1);
   MAKELOCAL(b, 2);
   return a + b;
}
```

Shell$ zig translate-c macro.c > macro.zig

macro.zig
```zig
pub export fn foo() c_int {
    var a: c_int = 1;
    _ = &a;
    var b: c_int = 2;
    _ = &b;
    return a + b;
}
pub const MAKELOCAL = @compileError("unable to translate C expr: unexpected token .Equal"); // macro.c:1:9
```

Note that `foo` was translated correctly despite using a non-translatable
  macro. `MAKELOCAL` was demoted to `@compileError` since
  it cannot be expressed as a Zig function; this simply means that you cannot directly use
  `MAKELOCAL` from Zig.

See also:

- [@compileError](#compileError)

## [C Pointers](#toc-C-Pointers) §

This type is to be avoided whenever possible. The only valid reason for using a C pointer is in
auto-generated code from translating C code.

When importing C header files, it is ambiguous whether pointers should be translated as
single-item pointers (`*T`) or many-item pointers (`[*]T`).
C pointers are a compromise so that Zig code can utilize translated header files directly.

`[*c]T` - C pointer.

- Supports all the syntax of the other two pointer types (`*T`) and (`[*]T`).
  Coerces to other pointer types, as well as [Optional Pointers](#Optional-Pointers).
      When a C pointer is coerced to a non-optional pointer, safety-checked
      [Illegal Behavior](#Illegal-Behavior) occurs if the address is 0.

  Allows address 0. On non-freestanding targets, dereferencing address 0 is safety-checked
      [Illegal Behavior](#Illegal-Behavior). Optional C pointers introduce another bit to keep track of
      null, just like `?usize`. Note that creating an optional C pointer
      is unnecessary as one can use normal [Optional Pointers](#Optional-Pointers).

- Supports [Type Coercion](#Type-Coercion) to and from integers.

- Supports comparison with integers.
  Does not support Zig-only pointer attributes such as alignment. Use normal [Pointers](#Pointers)
  please!

When a C pointer is pointing to a single struct (not an array), dereference the C pointer to
  access the struct's fields or member data. That syntax looks like
  this:

`ptr_to_struct.*.struct_member`

This is comparable to doing `->` in C.

 When a C pointer is pointing to an array of structs, the syntax reverts to this:

`ptr_to_struct_array[index].struct_member`

## [Null-Terminated Strings](#toc-Null-Terminated-Strings) §

C functions require null-terminated strings (`[:0]const u8`), but Zig slices are not null-terminated by default.

### Problem

```zig
const str = "hello";
const dynamic_str = try std.fmt.allocPrint(allocator, "value: {}", .{42});
c_function(dynamic_str);  // ERROR: expected [:0]const u8, found []const u8
```

### Solution 1: String Literals (Already Null-Terminated)

String literals in Zig are automatically null-terminated:

```zig
const str = "hello";  // Type is [:0]const u8
c_function(str);  // ✅ Works directly
```

### Solution 2: Dynamic Strings (Zig 0.16)

For dynamically created strings, use `allocPrint` + `dupeZ`:

```zig
// Step 1: Create string
const str = try std.fmt.allocPrint(allocator, "value: {}", .{42});
defer allocator.free(str);

// Step 2: Add null terminator
const str_z = try allocator.dupeZ(u8, str);
defer allocator.free(str_z);

// Step 3: Pass to C
c_function(str_z);  // ✅ Now works
```

**⚠️ Important:** `std.fmt.allocPrintZ` does NOT exist in Zig 0.16. Always use `allocPrint` + `dupeZ`.

**One-step version** (if you don't need the non-null-terminated version):

```zig
const str = try std.fmt.allocPrint(allocator, "value: {}", .{42});
const str_z = try allocator.dupeZ(u8, str);
allocator.free(str);  // Free original immediately
defer allocator.free(str_z);

c_function(str_z);
```

### Solution 3: Fixed-Size Buffers

For fixed-size buffers, reserve space for the null terminator:

```zig
var buffer: [256:0]u8 = undefined;  // ✅ Reserve space for null terminator
const str = try std.fmt.bufPrint(&buffer, "value: {}", .{42});
buffer[str.len] = 0;  // Add null terminator
c_function(&buffer);
```

### Solution 4: Sentinel-Terminated Slices

Convert slices to sentinel-terminated:

```zig
const slice: []const u8 = getData();
const terminated: [:0]const u8 = try allocator.dupeZ(u8, slice);
defer allocator.free(terminated);
c_function(terminated);
```

### Common Errors

**"expected type '[:0]const u8', found '[]const u8'"**
- Cause: Passing regular slice to C function
- Fix: Use `allocator.dupeZ()` to add null terminator

**"no member named 'allocPrintZ' in struct 'std.fmt'"**
- Cause: `allocPrintZ` was removed in Zig 0.16
- Fix: Use `allocPrint()` + `dupeZ()`

See also:

- [common_errors.md](common_errors.md#string-and-c-interop-errors) - String and C interop error solutions
- [C Type Primitives](#C-Type-Primitives)
- [C Pointers](#C-Pointers)

## [C Variadic Functions](#toc-C-Variadic-Functions) §

Zig supports extern variadic functions.

test_variadic_function.zig
```zig
const std = @import("std");
const testing = std.testing;

pub extern "c" fn printf(format: [*:0]const u8, ...) c_int;

test "variadic function" {
    try testing.expect(printf("Hello, world!\n") == 14);
    try testing.expect(@typeInfo(@TypeOf(printf)).@"fn".is_var_args);
}
```
Shell$ zig test test_variadic_function.zig -lc
1/1 test_variadic_function.test.variadic function...OK
All 1 tests passed.
Hello, world!

  Variadic functions can be implemented using [@cVaStart](#cVaStart), [@cVaEnd](#cVaEnd), [@cVaArg](#cVaArg) and [@cVaCopy](#cVaCopy).

test_defining_variadic_function.zig
```zig
const std = @import("std");
const testing = std.testing;
const builtin = @import("builtin");

fn add(count: c_int, ...) callconv(.c) c_int {
    var ap = @cVaStart();
    defer @cVaEnd(&ap);
    var i: usize = 0;
    var sum: c_int = 0;
    while (i 1) {
  sum += @cVaArg(&ap, c_int);
    }
    return sum;
}

test "defining a variadic function" {
    if (builtin.cpu.arch == .aarch64 and builtin.os.tag != .macos) {
  // https://github.com/ziglang/zig/issues/14096
  return error.SkipZigTest;
    }
    if (builtin.cpu.arch == .x86_64 and builtin.os.tag == .windows) {
  // https://github.com/ziglang/zig/issues/16961
  return error.SkipZigTest;
    }
    if (builtin.cpu.arch == .s390x) {
  // https://github.com/ziglang/zig/issues/21350#issuecomment-3543006475
  return error.SkipZigTest;
    }

    try std.testing.expectEqual(@as(c_int, 0), add(0));
    try std.testing.expectEqual(@as(c_int, 1), add(1, @as(c_int, 1)));
    try std.testing.expectEqual(@as(c_int, 3), add(2, @as(c_int, 1), @as(c_int, 2)));
}
```
Shell$ zig test test_defining_variadic_function.zig
1/1 test_defining_variadic_function.test.defining a variadic function...OK
All 1 tests passed.

## [Exporting a C Library](#toc-Exporting-a-C-Library) §

One of the primary use cases for Zig is exporting a library with the C ABI for other programming languages
to call into. The `export` keyword in front of functions, variables, and types causes them to
be part of the library API:

mathtest.zig
```zig
export fn add(a: i32, b: i32) i32 {
    return a + b;
}
```

To make a static library:

Shell$ zig build-lib mathtest.zig

To make a shared library:

Shell$ zig build-lib mathtest.zig -dynamic

Here is an example with the [Zig Build System](#Zig-Build-System):

test.c
```zig
// This header is generated by zig from mathtest.zig
#include "mathtest.h"
#include

int main(int argc, char **argv) {
    int32_t result = add(42, 1337);
    printf("%d\n", result);
    return 0;
}
```

build_c.zig
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const lib = b.addLibrary(.{
  .linkage = .dynamic,
  .name = "mathtest",
  .root_module = b.createModule(.{
      .root_source_file = b.path("mathtest.zig"),
  }),
  .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });
    const exe = b.addExecutable(.{
  .name = "test",
  .root_module = b.createModule(.{
      .link_libc = true,
  }),
    });
    exe.root_module.addCSourceFile(.{ .file = b.path("test.c"), .flags = &.{"-std=c99"} });
    exe.root_module.linkLibrary(lib);

    b.default_step.dependOn(&exe.step);

    const run_cmd = exe.run();

    const test_step = b.step("test", "Test the program");
    test_step.dependOn(&run_cmd.step);
}
```

Shell$ zig build test
1379

See also:

- [export](#export)

## [Mixing Object Files](#toc-Mixing-Object-Files) §

You can mix Zig object files with any other object files that respect the C ABI. Example:

base64.zig
```zig
const base64 = @import("std").base64;

export fn decode_base_64(
    dest_ptr: [*]u8,
    dest_len: usize,
    source_ptr: [*]const u8,
    source_len: usize,
) usize {
    const src = source_ptr[0..source_len];
    const dest = dest_ptr[0..dest_len];
    const base64_decoder = base64.standard.Decoder;
    const decoded_size = base64_decoder.calcSizeForSlice(src) catch unreachable;
    base64_decoder.decode(dest[0..decoded_size], src) catch unreachable;
    return decoded_size;
}
```

test.c
```zig
// This header is generated by zig from base64.zig
#include "base64.h"

#include
#include

int main(int argc, char **argv) {
    const char *encoded = "YWxsIHlvdXIgYmFzZSBhcmUgYmVsb25nIHRvIHVz";
    char buf[200];

    size_t len = decode_base_64(buf, 200, encoded, strlen(encoded));
    buf[len] = 0;
    puts(buf);

    return 0;
}
```

build_object.zig
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const obj = b.addObject(.{
  .name = "base64",
  .root_module = b.createModule(.{
      .root_source_file = b.path("base64.zig"),
  }),
    });

    const exe = b.addExecutable(.{
  .name = "test",
  .root_module = b.createModule(.{
      .link_libc = true,
  }),
    });
    exe.root_module.addCSourceFile(.{ .file = b.path("test.c"), .flags = &.{"-std=c99"} });
    exe.root_module.addObject(obj);
    b.installArtifact(exe);
}
```

Shell$ zig build
$ ./zig-out/bin/test
all your base are belong to us

See also:

- [Targets](#Targets)

- [Zig Build System](#Zig-Build-System)
