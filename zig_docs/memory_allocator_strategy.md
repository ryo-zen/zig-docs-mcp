# Memory Allocator Strategy

Practical allocator selection and ownership design for production Zig code.

📚 **Related runnable examples:**
- `zig_docs_std/Examples/memory_allocator_strategy.tests.zig`
- `zig_docs_std/Examples/memory_oom_handling.tests.zig`
- `zig_docs_std/Examples/memory_ownership_contract.tests.zig`
- `zig_docs_std/Examples/test_memory_patterns.zig`
- `zig_docs_std/Examples/test_memory_safety.zig`

## Overview

In Zig, allocator choice is an architectural decision, not an implementation detail.
The right allocator depends on workload shape, lifetime model, failure policy, and platform constraints.

If you are unsure, start with `GeneralPurposeAllocator` and move only after measurement.

## Decision Matrix

| Allocator | Best For | Strengths | Risks / Tradeoffs |
|---|---|---|---|
| `std.heap.GeneralPurposeAllocator` | General applications and services | Strong debug diagnostics, good default behavior | More overhead than specialized allocators |
| `std.heap.ArenaAllocator` | Request/frame/job-scoped lifetimes | Fast allocation, simple bulk cleanup | No individual free, memory can balloon if scope is too large |
| `std.heap.FixedBufferAllocator` | Hard memory budgets, embedded, bounded parsing | Deterministic memory footprint, fast | Fails with `error.OutOfMemory` when full |
| `std.heap.page_allocator` | Large page-aligned buffers, low-level tooling | Simple, OS-backed pages | Costly for many small allocations |
| `std.heap.c_allocator` | C interop where `malloc/free` ownership crosses boundary | ABI-compatible ownership with C | Behavior tied to libc allocator characteristics |
| Custom allocator (wrapper or implementation) | Domain-specific policy: quotas, tagging, telemetry, deterministic replay | Full policy control, observability | Complexity and correctness burden shifts to you |

## Selection Flow

Use this order:

1. Do you need allocator ABI compatibility with C code ownership?
Use `c_allocator`.
2. Do you have strict memory limits and known maximum usage?
Use `FixedBufferAllocator`.
3. Are allocations naturally phase-scoped (request/frame/task)?
Use `ArenaAllocator`.
4. Are allocations general-purpose with mixed lifetimes?
Use `GeneralPurposeAllocator`.
5. Are allocations mostly large page-granular blocks?
Use `page_allocator`.
6. Do you need policy not provided above (quotas, accounting, controlled failures)?
Introduce a custom allocator wrapper.

## Ownership and Lifetime Checklist

For every allocation site, answer all of these explicitly:

1. **Who owns this memory after return?**
2. **What exact API releases it (`free`, `destroy`, `deinit`)?**
3. **What is the lifetime boundary (scope, request, arena reset, process)?**
4. **What happens on error path before ownership transfer?**
5. **Can the memory alias mutable state elsewhere?**
6. **Will this be used across threads? If yes, what synchronization exists?**
7. **Is allocation failure acceptable here, and what is fallback behavior?**

If any answer is ambiguous, your API contract is incomplete.

## Ownership Contract Template

Use this template in docs/comments for allocating APIs:

```zig
/// Allocates output using caller-provided allocator.
/// Owner: caller.
/// Cleanup: caller must `allocator.free(result)` (or `result.deinit(allocator)`).
/// Lifetime: valid until explicitly freed/deinitialized.
/// On error: no ownership transferred, no leaked allocations.
pub fn transform(allocator: Allocator, input: []const u8) ![]u8 { ... }
```

## Anti-Patterns to Avoid

1. Returning pointers/slices to stack memory.
2. Using `ArenaAllocator` in long-lived loops without reset/deinit boundaries.
3. Ignoring `error.OutOfMemory` with `catch unreachable` in non-fatal contexts.
4. Mixing ownership domains (allocate with one allocator, free with another).
5. Mutating through aliases with unclear ownership.
6. Building APIs that allocate implicitly without documenting ownership transfer.

## OOM Strategy

Choose one policy per subsystem:

- **Propagate:** return `error.OutOfMemory` and let caller decide.
- **Recover:** degrade functionality (reduce cache/batch size).
- **Abort:** crash only in explicitly non-recoverable application contexts.

For libraries, default to **propagate**.

## Custom Allocator Guidance

Add a custom allocator only when you need one of:

- allocation accounting/telemetry by subsystem,
- per-request quotas,
- deterministic failure injection outside tests,
- specialized placement policy.

Start with a wrapper around an existing allocator before writing a new allocator from scratch.

## Validation Workflow

1. Run with `std.testing.allocator` to catch leaks in tests.
2. Add `std.testing.FailingAllocator` tests for OOM branches.
3. Run representative load profile before changing allocator strategy.
4. Compare both latency and peak memory, not just throughput.

## See Also

- [Memory](memory.md)
- [Pointers](pointers.md)
- [Slices](slices.md)
- [Errors](errors.md)
