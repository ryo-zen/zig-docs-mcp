# std.Io.Mutex

Mutex is a synchronization primitive which enforces atomic access to a shared region of code known as the "critical section".

Mutex is an extern struct so that it may be used as a field inside another extern struct. Having a guaranteed memory layout including mutexes is important for IPC over shared memory (mmap).

### Fields

    state: std.atomic.Value(State)

## Types

- State

## Values

|      |         |     |
|------|---------|-----|
| init | `Mutex` |     |

## Functions

`pub fn lock(m: *Mutex, io: Io) Cancelable!void`  

`pub fn lockUncancelable(m: *Mutex, io: Io) void`  
Same as `lock`, except does not introduce a cancelation point.

`pub fn tryLock(m: *Mutex) bool`  

`pub fn unlock(m: *Mutex, io: Io) void`  
