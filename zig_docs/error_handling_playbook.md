# Error Handling Playbook

Production-oriented error policy design for Zig applications and libraries.

## Runnable Examples

- `zig_docs_std/Examples/error_handling_playbook.tests.zig`
- `zig_docs_std/Examples/memory_oom_handling.tests.zig`
- `zig_docs_std/Examples/memory_ownership_contract.tests.zig`

## Overview

Zig error handling is most effective when policy is explicit.
A strong policy answers:

1. Which errors are recoverable?
2. Which errors are fatal?
3. How many retries are allowed?
4. Where is context attached and logged?

## Quick Start Policy

1. Use specific error sets for public APIs.
2. Classify errors into recoverable and non-recoverable categories.
3. Retry only idempotent operations.
4. Propagate with `try` by default.
5. Panic only for broken invariants, not expected runtime failures.

```zig
const FetchError = error{ TemporaryUnavailable, InvalidResponse, OutOfMemory };

fn fetchOnce() FetchError!void {
    return error.TemporaryUnavailable;
}

fn fetchWithRetry(max_attempts: u8) FetchError!void {
    var attempt: u8 = 0;
    while (attempt < max_attempts) : (attempt += 1) {
        fetchOnce() catch |err| switch (err) {
            error.TemporaryUnavailable => continue, // retry
            else => return err, // fatal/non-retryable
        };
        return;
    }
    return error.TemporaryUnavailable;
}
```

## Policy Templates

### CLI Policy

- Input and environment errors: print actionable message and exit non-zero.
- Programmer bugs/invariant breaks: panic.
- Prefer clear top-level mapping from error to exit code.

### Server Policy

- Per-request errors: return structured error response, keep process alive.
- Resource exhaustion (`OutOfMemory`, fd limits): shed load and log at high severity.
- Supervisor/process-level unrecoverable state: fail fast and restart.

### Library Policy

- Never panic for caller-caused invalid runtime input.
- Return precise error sets.
- Document ownership and cleanup behavior on both success and failure.

## Panic vs Error Union Decision Guide

Use error unions when failure is plausible at runtime:

1. I/O, network, parsing, allocation, config loading.
2. Any boundary with external input.

Use panic only for invariant failures:

1. Internal impossible states.
2. API misuse that violates documented preconditions and cannot be recovered locally.

Rule of thumb: if the caller can realistically recover, return an error.

## Context Propagation

Attach context at boundaries, not everywhere.

1. Add subsystem + operation context when crossing layers.
2. Preserve original error value for caller policy decisions.
3. Avoid replacing specific errors with `anyerror` at API surfaces.

## Retry and Backoff Guidance

1. Retry only idempotent operations.
2. Cap attempts.
3. Use bounded backoff, never unbounded loops.
4. Distinguish transport/transient errors from semantic errors.

## Gotchas

1. Catch-all `catch unreachable` hides real failure paths.
2. `anyerror` at public boundaries degrades clarity and switch exhaustiveness.
3. Overusing `panic` in library code removes caller control.
4. Missing `errdefer` often leaks partial initialization on failure.

## Related Docs

- [Errors](errors.md)
- [Error Handling Patterns](error_patterns.md)
- [Common Compilation Errors](common_errors.md)
- [Memory Allocator Strategy](memory_allocator_strategy.md)
