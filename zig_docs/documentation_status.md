# Zig Language Docs Status

Last updated: 2026-05-28

## Coverage Summary

- Language docs in `zig_docs/`: maintained
- Playbook-style docs (memory, unsafe boundaries, errors, concurrency, I/O, performance): complete
- Remaining focus: preserving 0.16 API accuracy as the docs evolve

## Area Tracker

| Area | Primary Files | Status |
|---|---|---|
| Memory and Ownership | `memory.md`, `memory_allocator_strategy.md`, `pointers.md`, `slices.md` | ✅ Complete |
| Unsafe Boundaries | `unsafe_boundaries.md`, `casting.md`, `illegal_behavior.md` | ✅ Complete |
| Errors and Failure Policy | `error_handling.md`, `errors.md`, `error_patterns.md` | ✅ Complete |
| Concurrency and I/O | `concurrency.md`, `io_reliability_backpressure.md`, `atomics.md` | ✅ Complete |
| Performance and Release | `performance.md`, `build_mode.md`, `release_checklist.md`, `targets.md` | ✅ Complete |
| Interop | `c.md` | ✅ Complete |

## Notes

- Runnable examples are linked from core docs where applicable.
- Cross-links should prefer local `.md` file references over fragile anchor-only links when crossing documents.
