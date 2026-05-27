# std.simd

## Overview

`std.simd` contains SIMD convenience functions for vector length selection, vector construction, lane rearrangement, boolean-mask inspection, and prefix scans.

Source: `/path/to/zig-0.16.0/lib/std/simd.zig`

## Public API

### Vector Length Helpers

- `std.simd.suggestVectorLengthForCpu(T, cpu)` - suggests a target-specific vector lane count for a type and CPU.
- `std.simd.suggestVectorLength(T)` - suggests a vector lane count for the current target CPU.
- `std.simd.VectorIndex(VectorType)` - smallest unsigned integer type that can index the vector.
- `std.simd.VectorCount(VectorType)` - smallest unsigned integer type that can hold the vector length.

### Construction and Rearrangement

- `std.simd.iota(T, len)` - vector containing `0` through `len - 1`.
- `std.simd.repeat(len, vec)` - repeats a vector to a longer vector length.
- `std.simd.join(a, b)` - concatenates two vectors.
- `std.simd.interlace(vecs)` - interlaces vectors.
- `std.simd.deinterlace(vec, count)` - splits an interlaced vector.
- `std.simd.extract(vec, first, len)` - extracts a sub-vector.
- `std.simd.mergeShift(a, b, shift)` - merges two vectors with a lane shift.
- `std.simd.shiftElementsRight(vec, amount, shift_in)`
- `std.simd.shiftElementsLeft(vec, amount, shift_in)`
- `std.simd.rotateElementsLeft(vec, amount)`
- `std.simd.rotateElementsRight(vec, amount)`
- `std.simd.reverseOrder(vec)`

### Boolean and Value Queries

- `std.simd.firstTrue(vec)`
- `std.simd.lastTrue(vec)`
- `std.simd.countTrues(vec)`
- `std.simd.firstIndexOfValue(vec, value)`
- `std.simd.lastIndexOfValue(vec, value)`
- `std.simd.countElementsWithValue(vec, value)`

### Prefix Scans

- `std.simd.prefixScanWithFunc(hop, vec, context, combine)`
- `std.simd.prefixScan(op, hop, vec)`

## Notes

SIMD performance and support are target-dependent. The source notes that some functions are known not to work on MIPS.
