# std.debug.sys_can_stack_trace

Whether we can unwind the stack on this target, allowing capturing and/or printing the current stack trace. It is still legal to call `captureCurrentStackTrace`, `writeCurrentStackTrace`, and `dumpCurrentStackTrace` if this is `false`; it will just print an error / capture an empty trace due to missing functionality. This value is just intended as a heuristic to avoid pointless work e.g. capturing always-empty stack traces.

## Overview

`std.debug.sys_can_stack_trace` is a compile-time heuristic for whether stack-trace capture is expected to work on the current target/toolchain combination.

It is not a hard guarantee; it helps decide whether tracing work is likely useful.

## Source Code

```
pub const sys_can_stack_trace = switch (builtin.cpu.arch) {
    // `@returnAddress()` in LLVM 10 gives
    // "Non-Emscripten WebAssembly hasn't implemented __builtin_return_address".
    // On Emscripten, Zig only supports `@returnAddress()` in debug builds
    // because Emscripten's implementation is very slow.
    .wasm32,
    .wasm64,
    => native_os == .emscripten and builtin.mode == .Debug,

    // `@returnAddress()` is unsupported in LLVM 21.
    .bpfel,
    .bpfeb,
    => false,

    else => true,
}
```

## Usage Notes

- Safe to call stack-trace APIs even when this is `false`; behavior may degrade to empty/unavailable traces.
- Use it to avoid costly trace capture work when support is known missing.
- Architecture-specific exceptions (for example wasm and bpf variants) are encoded directly in this constant.

## Related APIs

- `std.debug.captureCurrentStackTrace`
- `std.debug.dumpCurrentStackTrace`
- `std.debug.have_segfault_handling_support`
