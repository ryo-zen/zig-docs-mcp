# unreachable §

In Debug and ReleaseSafe mode `unreachable` emits a call to `panic` with the message `reached unreachable code`. 

In ReleaseFast and ReleaseSmall mode, the optimizer uses the assumption that `unreachable` code will never be hit to perform optimizations. 

### Basics §

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

Shell

    ```
    $ zig test test_unreachable.zig
    1/1 test_unreachable.test.basic math...OK
    All 1 tests passed.
    
    ```

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

Shell

    ```zig
    $ zig test test_assertion_failure.zig
    1/1 test_assertion_failure.test.this will fail...thread 209597 panic: reached unreachable code
    /home/andy/dev/zig/doc/langref/test_assertion_failure.zig:3:14: 0x104892d in assert (test)
        if (!ok) unreachable; // assertion failure
                 ^
    /home/andy/dev/zig/doc/langref/test_assertion_failure.zig:8:11: 0x10488fa in test.this will fail (test)
        assert(false);
              ^
    /home/andy/dev/zig/lib/compiler/test_runner.zig:214:25: 0x10ef0c5 in mainTerminal (test)
            if (test_fn.func()) |_| {
                            ^
    /home/andy/dev/zig/lib/compiler/test_runner.zig:62:28: 0x10e74ad in main (test)
            return mainTerminal();
                               ^
    /home/andy/dev/zig/lib/std/start.zig:651:22: 0x10e6922 in posixCallMainAndExit (test)
                root.main();
                         ^
    /home/andy/dev/zig/lib/std/start.zig:271:5: 0x10e64fd in _start (test)
        asm volatile (switch (native_arch) {
        ^
    ???:?:?: 0x0 in ??? (???)
    error: the following test command crashed:
    /home/andy/dev/zig/.zig-cache/o/0594f73810636b148c5e4293efd1faf6/test --seed=0x2a37766c
    
    ```

### At Compile-Time §

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

Shell

    ```
    $ zig test test_comptime_unreachable.zig
    /home/andy/dev/zig/doc/langref/test_comptime_unreachable.zig:10:16: error: unreachable code
            assert(@TypeOf(unreachable) == noreturn);
                   ^~~~~~~~~~~~~~~~~~~~
    /home/andy/dev/zig/doc/langref/test_comptime_unreachable.zig:10:24: note: control flow is diverted here
            assert(@TypeOf(unreachable) == noreturn);
                           ^~~~~~~~~~~

    ```

See also:

  * Zig Test
  * Build Mode
  * comptime