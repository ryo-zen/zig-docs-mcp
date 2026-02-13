# unreachable

In [Debug](#Debug) and [ReleaseSafe](#ReleaseSafe) mode
`unreachable` emits a call to `panic` with the message `reached unreachable code`.

In [ReleaseFast](#ReleaseFast) and [ReleaseSmall](#ReleaseSmall) mode, the optimizer uses the assumption that `unreachable` code
will never be hit to perform optimizations.

## [Basics](#toc-Basics) §

test_unreachable.zig
```zig
// unreachable is used to assert that control flow will never reach a
// particular location:
test "basic math" {
    const x = 1;
    const y = 2;
    if (x + y != 3) {
  unreachable;
    }
}
```
Shell$ zig test test_unreachable.zig
1/1 test_unreachable.test.basic math...OK
All 1 tests passed.

In fact, this is how `std.debug.assert` is implemented:

test_assertion_failure.zig
```zig
// This is how std.debug.assert is implemented
fn assert(ok: bool) void {
    if (!ok) unreachable; // assertion failure
}

// This test will fail because we hit unreachable.
test "this will fail" {
    assert(false);
}
```
Shell$ zig test test_assertion_failure.zig
1/1 test_assertion_failure.test.this will fail...thread 3449470 panic: reached unreachable code
/home/ci/zig-bootstrap/zig/doc/langref/test_assertion_failure.zig:3:14: 0x103f039 in assert (test_assertion_failure.zig)
    if (!ok) unreachable; // assertion failure
       ^
/home/ci/zig-bootstrap/zig/doc/langref/test_assertion_failure.zig:8:11: 0x103f00e in test.this will fail (test_assertion_failure.zig)
    assert(false);
    ^
/home/ci/zig-bootstrap/out/host/lib/zig/compiler/test_runner.zig:255:25: 0x11d0d12 in mainTerminal (test_runner.zig)
  if (test_fn.func()) |_| {
                  ^
/home/ci/zig-bootstrap/out/host/lib/zig/compiler/test_runner.zig:70:28: 0x11cabc2 in main (test_runner.zig)
  return mainTerminal(init);
                     ^
/home/ci/zig-bootstrap/out/host/lib/zig/std/start.zig:680:88: 0x11c7237 in callMain (std.zig)
    if (fn_info.params[0].type.? == std.process.Init.Minimal) return wrapMain(root.main(.{
                                                                                 ^
/home/ci/zig-bootstrap/out/host/lib/zig/std/start.zig:190:5: 0x11c6c61 in _start (std.zig)
    asm volatile (switch (native_arch) {
    ^
error: the following test command terminated with signal ABRT:
/home/ci/zig-bootstrap/out/zig-local-cache/o/4b96511dd6cdbe503ddfa7d8986820fa/test --seed=0xafda51e1

## [At Compile-Time](#toc-At-Compile-Time) §

test_comptime_unreachable.zig
```zig
const assert = @import("std").debug.assert;

test "type of unreachable" {
    comptime {
  // The type of unreachable is noreturn.

  // However this assertion will still fail to compile because
  // unreachable expressions are compile errors.

  assert(@TypeOf(unreachable) == noreturn);
    }
}
```
Shell$ zig test test_comptime_unreachable.zig
/home/ci/zig-bootstrap/zig/doc/langref/test_comptime_unreachable.zig:10:16: error: unreachable code
  assert(@TypeOf(unreachable) == noreturn);
         ^~~~~~~~~~~~~~~~~~~~
/home/ci/zig-bootstrap/zig/doc/langref/test_comptime_unreachable.zig:10:24: note: control flow is diverted here
  assert(@TypeOf(unreachable) == noreturn);
                 ^~~~~~~~~~~

See also:

- [Zig Test](#Zig-Test)

- [Build Mode](#Build-Mode)

- [comptime](#comptime)
