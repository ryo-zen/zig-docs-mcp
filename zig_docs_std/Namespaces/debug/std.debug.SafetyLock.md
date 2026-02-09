# std.debug.SafetyLock

### Fields

    state: State = if (runtime_safety) .unlocked else .unknown

## Types

- State

## Functions

`pub fn assertLocked(l: SafetyLock) void`  

`pub fn assertUnlocked(l: SafetyLock) void`  

`pub fn lock(l: *SafetyLock) void`  

`pub fn unlock(l: *SafetyLock) void`  
