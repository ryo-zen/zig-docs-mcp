# std.valgrind

## Overview

`std.valgrind` exposes Valgrind client requests and helpers for communicating allocation, stack, mempool, and profiling metadata to Valgrind tools.

Source: `/path/to/zig-0.16.0/lib/std/valgrind.zig`

## Public API Areas

### Core Client Requests

- `std.valgrind.doClientRequest`
- `std.valgrind.ClientRequest`
- `std.valgrind.ToolBase`
- `std.valgrind.IsTool`
- `std.valgrind.runningOnValgrind`
- `std.valgrind.countErrors`

### Translation and Call Control

- `std.valgrind.discardTranslations`
- `std.valgrind.innerThreads`
- `std.valgrind.nonSimdCall0`
- `std.valgrind.nonSimdCall1`
- `std.valgrind.nonSimdCall2`
- `std.valgrind.nonSimdCall3`

### Allocation and Mempool Annotation

- `std.valgrind.mallocLikeBlock`
- `std.valgrind.resizeInPlaceBlock`
- `std.valgrind.freeLikeBlock`
- `std.valgrind.MempoolFlags`
- `std.valgrind.createMempool`
- `std.valgrind.destroyMempool`
- `std.valgrind.mempoolAlloc`
- `std.valgrind.mempoolFree`
- `std.valgrind.mempoolTrim`
- `std.valgrind.moveMempool`
- `std.valgrind.mempoolChange`
- `std.valgrind.mempoolExists`

### Stack and Diagnostics

- `std.valgrind.stackRegister`
- `std.valgrind.stackDeregister`
- `std.valgrind.stackChange`
- `std.valgrind.mapIpToSrcloc`
- `std.valgrind.disableErrorReporting`
- `std.valgrind.enableErrorReporting`
- `std.valgrind.monitorCommand`

### Tool-Specific Namespaces

- `std.valgrind.memcheck`
- `std.valgrind.callgrind`
- `std.valgrind.cachegrind`

## Notes

These APIs are no-ops or special client requests depending on whether the program is running under Valgrind and which tool is active.
