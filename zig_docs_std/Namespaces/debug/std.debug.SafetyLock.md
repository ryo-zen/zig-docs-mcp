# std.debug.SafetyLock

## Overview

`std.debug.SafetyLock` is a lightweight state guard used by debug internals to assert expected lock/ownership transitions when runtime safety is enabled.

Its checks are meant for correctness diagnostics, not as a general-purpose synchronization primitive.

### Fields

    state: State = if (runtime_safety) .unlocked else .unknown

## Types

- State

## Functions

`pub fn assertLocked(l: SafetyLock) void`
Debug assertion that state is currently locked.

`pub fn assertUnlocked(l: SafetyLock) void`
Debug assertion that state is currently unlocked.

`pub fn lock(l: *SafetyLock) void`
Transitions to locked state (with safety assertions as applicable).

`pub fn unlock(l: *SafetyLock) void`
Transitions to unlocked state.

## Usage Notes

- In non-safety builds, state tracking can degrade to `.unknown` and checks may compile out.
- Use this for invariant checking around internal lock discipline, not for inter-thread mutual exclusion.
