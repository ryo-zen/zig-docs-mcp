# Zig Docs Roadmap

This roadmap defines the documentation work needed to make `zig-docs-mcp` strong enough for systems programming usage for Zig Language v0.16-dev

## Goals

1. Make high-stakes topics explicit: memory, concurrency, unsafe boundaries, error policy, and performance.
2. Ensure every major concept has runnable examples and a clear "when to use / when not to use" section.
3. Standardize doc quality and navigation across `zig_docs/`, `zig_docs_std/Namespaces/`, and `zig_docs_std/Types/`.

## Quality Bar (Definition of Done)

A document is "done" when it has:

1. `Overview` with clear scope.
2. `Quick Start` or minimal working pattern.
3. `Gotchas` and failure modes.
4. Practical guidance ("choose X vs Y") for real workloads.
5. Links to runnable examples in `zig_docs_std/Examples/`.
6. Correct cross-links to related docs.
7. Validated snippets (at least one compile/test path).

## Prioritized Workstreams

## S-Tier: Foundations (Must Have)

### 1) Memory + Allocator Strategy
- Why: This is the highest-impact systems topic in Zig.
- Status: Done ✅ Completed
- Deliverables:
  - New guide: `zig_docs/memory_allocator_strategy.md`
  - Upgrade existing: `zig_docs/memory.md`, `zig_docs/pointers.md`, `zig_docs/slices.md`
  - Add examples: allocator selection, lifetime boundaries, leak-avoidance patterns
- Acceptance criteria:
  - Includes allocator decision matrix (`GPA`, arena, fixed buffer, page allocator, custom).
  - Includes ownership/lifetime checklist and anti-patterns.

### 2) Unsafe Boundaries + Invariants
- Why: Systems programming depends on correctness around casts, aliasing, and bounds assumptions.
- Status: Done ✅ Completed
- Deliverables:
  - New guide: `zig_docs/unsafe_boundaries.md`
  - Cross-link from: `zig_docs/casting.md`, `zig_docs/pointers.md`, `zig_docs/illegal_behavior.md`
  - Add examples: sentinel mismatch, invalid alignment, pointer cast guard rails
- Acceptance criteria:
  - Explicit "preconditions before using X" sections.
  - At least 8 runnable failure/safe-pair examples.

### 3) Error Policy + Failure Design
- Why: Production behavior depends on consistent error handling strategy.
- Status: Done ✅ Completed
- Deliverables:
  - Upgrade: `zig_docs/errors.md`, `zig_docs/error_patterns.md`, `zig_docs/common_errors.md`
  - New guide: `zig_docs/error_handling.md`
  - Add examples: retry/backoff, classify-recoverable vs fatal, context propagation
- Acceptance criteria:
  - Includes policy templates for CLI/server/library styles.
  - Includes panic vs error-union decision guide.

### 4) Concurrency + Synchronization
- Why: Race conditions and lock discipline are core systems risks.
- Status: Done ✅ Completed
- Deliverables:
  - New guide: `zig_docs/concurrency.md`
  - Upgrade: `zig_docs/atomics.md`, async docs, relevant `std.Io` docs
  - Add examples: lock ordering, cancellation, timeout handling, producer-consumer
- Acceptance criteria:
  - Includes race-condition checklist and lock-order conventions.
  - Includes at least one multi-threaded test example.

### 5) I/O Reliability + Backpressure
- Why: Real systems fail at boundaries: partial writes, framing, shutdown semantics.
- Status: Done ✅ Completed
- Deliverables:
  - Upgrade: I/O docs and `std.Io` namespace/type docs
  - Add examples: robust read loops, partial write handling, protocol framing
- Acceptance criteria:
  - "What can fail and how to recover" listed for each key I/O pattern.

## A-Tier: High Leverage

### 6) Performance Methodology
- Status: Done ✅ Completed
- Deliverables:
  - New guide: `zig_docs/performance.md`
  - Add examples: benchmark harness patterns, allocation profiling, cache-friendly layouts
  - Added runnable example: `zig_docs_std/Examples/performance_methodology.tests.zig`
- Acceptance criteria:
  - Explicit measure-first workflow and optimization triage order.

### 7) Build Modes + Release Engineering
- Status: Done ✅ Completed
- Deliverables:
  - Upgrade: `zig_docs/build_mode.md`, `zig_docs/compilation_model.md`, `zig_docs/targets.md`
  - New guide: `zig_docs/release_checklist.md`
  - Added runnable example: `zig_docs_std/Examples/build_release_modes.tests.zig`
- Acceptance criteria:
  - Clear matrix of `Debug` / `ReleaseSafe` / `ReleaseFast` / `ReleaseSmall` behavior impact.

### 8) Comptime and API Design for Libraries
- Status: Done ✅ Completed
- Deliverables:
  - Upgrade: `zig_docs/comptime.md`, `zig_docs/result_location_semantics.md`
  - Add examples: compile-time validation, generic API ergonomics, specialization tradeoffs
  - Added runnable example: `zig_docs_std/Examples/comptime_api_design.tests.zig`
- Acceptance criteria:
  - Includes "avoid overusing comptime" guidance and complexity tradeoffs.

## B-Tier: Completeness

### 9) C Interop and ABI Pitfalls
- Deliverables:
  - Upgrade: `zig_docs/c.md`
  - Add examples: struct layout checks, ownership transfer rules, error translation

### 10) Doc Architecture + Navigation
- Deliverables:
  - Global cross-link cleanup (replace broken anchors with local file links where needed).
  - Add "runnable examples" line to core concept docs (like `arrays.md`).
  - Add status trackers per area similar to `documentation_status.md`.

## Execution Plan (Phased)

### Phase 1: Stabilize Foundations (Weeks 1-2)
1. Memory/allocators.
2. Unsafe boundaries.
3. Error policy.
4. Add/validate example files for each.

### Phase 2: Runtime Systems Reliability (Weeks 3-4)
1. Concurrency and synchronization.
2. I/O reliability/backpressure.
3. Build mode behavior impact.

### Phase 3: Optimization and Library Ergonomics (Weeks 5-6)
1. Performance methodology guide.
2. Comptime API design guidance.
3. C interop hardening.

### Phase 4: Consistency Sweep (Week 7+)
1. Cross-link and structure normalization.
2. Fill remaining stubs in `zig_docs_std/Namespaces/` and `zig_docs_std/Types/`.
3. Add per-area status files.

## Tracking Template

Use this checklist per document:

- [ ] Overview added
- [ ] Quick Start / minimal pattern
- [ ] Gotchas / failure modes
- [ ] Decision guidance
- [ ] Runnable example link added
- [ ] Snippets validated
- [ ] Cross-links fixed

## Immediate Next Targets

1. `zig_docs/c.md`
2. Cross-link cleanup for core docs and playbooks
3. Per-area status trackers (matching `documentation_status.md` style)
4. Remaining stubs in `zig_docs_std/Namespaces/` and `zig_docs_std/Types/`
