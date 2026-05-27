# std.gpu

## Overview

`std.gpu` contains SPIR-V shader-facing builtins and execution-mode declarations.

Source: `/path/to/zig-0.16.0/lib/std/gpu.zig`

## Public API

### Shader Inputs and Outputs

- `std.gpu.position_in`
- `std.gpu.position_out`
- `std.gpu.point_size_in`
- `std.gpu.point_size_out`
- `std.gpu.invocation_id`
- `std.gpu.frag_coord`
- `std.gpu.point_coord`
- `std.gpu.frag_depth`
- `std.gpu.num_workgroups`
- `std.gpu.workgroup_size`
- `std.gpu.workgroup_id`
- `std.gpu.local_invocation_id`
- `std.gpu.global_invocation_id`
- `std.gpu.vertex_index`
- `std.gpu.instance_index`

### Execution Modes

- `std.gpu.ExecutionMode` - union describing SPIR-V execution modes.
- `std.gpu.executionMode(entry_point, mode)` - emits an `OpExecutionMode` declaration for the entry point.

## Notes

Execution-mode validation depends on the entry point calling convention. Fragment-only modes require a fragment calling convention, while `local_size` requires a SPIR-V kernel calling convention.
