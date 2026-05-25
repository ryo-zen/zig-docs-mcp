# std.Io

Cross-platform interface for I/O and concurrency.

`std.Io` is a small vtable-backed handle that lets code perform filesystem, networking, process, time, randomness, async task, queue, and synchronization operations through an implementation-provided backend.

## Fields

### `userdata: ?*anyopaque`

Backend-specific state passed to every vtable function.

### `vtable: *const VTable`

Function table implementing the backend operations.

## Types

- `AnyFuture`
- `Batch`
- `CancelProtection`
- `Clock`
- `Condition`
- `Dir`
- `Dispatch`
- `Duration`
- `Event`
- `Evented`
- `File`
- `Future`
- `Group`
- `Kqueue`
- `Limit`
- `LockedStderr`
- `Mutex`
- `Operation`
- `Queue`
- `Reader`
- `RwLock`
- `Select`
- `Semaphore`
- `Terminal`
- `Threaded`
- `Timeout`
- `Timestamp`
- `TypeErasedQueue`
- `Uring`
- `VTable`
- `Writer`

## Namespaces

- `fiber`
- `net`

## Values

### `failing: std.Io`

An `std.Io` implementation that simulates a system supporting no I/O operations. It is useful for tests, defaults, and vtable slots that must fail predictably.

## Core Functions

### `pub fn async(io: Io, function: anytype, args: std.meta.ArgsTuple(@TypeOf(function))) Future(@typeInfo(@TypeOf(function)).@"fn".return_type.?)`

Calls `function` with `args`. The return value is available through the returned `Future`.

### `pub fn concurrent(io: Io, function: anytype, args: std.meta.ArgsTuple(@TypeOf(function))) ConcurrentError!Future(@typeInfo(@TypeOf(function)).@"fn".return_type.?)`

Calls `function` with `args` while allowing the caller to make progress waiting on other `Io` operations. This has stronger backend requirements than `async`.

### `pub fn operate(io: Io, operation: Operation) Cancelable!Operation.Result`

Performs one low-level `Operation`.

### `pub fn operateTimeout(io: Io, operation: Operation, timeout: Timeout) OperateTimeoutError!Operation.Result`

Performs one low-level `Operation` with a timeout.

### `pub fn recancel(io: Io) void`

Re-arms a cancellation request after `error.Canceled` was returned from a previous cancellation point.

### `pub fn swapCancelProtection(io: Io, new: CancelProtection) CancelProtection`

Updates the current task's cancellation protection state and returns the previous state.

### `pub fn checkCancel(io: Io) Cancelable!void`

Pure cancellation point. It returns `error.Canceled` if a non-blocked cancellation request is outstanding; otherwise it is a no-op.

### `pub fn sleep(io: Io, duration: Duration, clock: Clock) Cancelable!void`

Waits until the requested duration has passed on the selected clock.

## Futex Functions

### `pub fn futexWait(io: Io, comptime T: type, ptr: *align(@alignOf(u32)) const T, expected: T) Cancelable!void`

Waits while `ptr` still contains `expected`.

### `pub fn futexWaitTimeout(io: Io, comptime T: type, ptr: *align(@alignOf(u32)) const T, expected: T, timeout: Timeout) Cancelable!void`

Like `futexWait`, with timeout support.

### `pub fn futexWaitUncancelable(io: Io, comptime T: type, ptr: *align(@alignOf(u32)) const T, expected: T) void`

Like `futexWait`, without introducing a cancellation point.

### `pub fn futexWake(io: Io, comptime T: type, ptr: *align(@alignOf(u32)) const T, max_waiters: u32) void`

Wakes up to `max_waiters` waiters blocked on `ptr`.

## Stderr Functions

### `pub fn lockStderr(io: Io, buffer: []u8, terminal_mode: ?Terminal.Mode) Cancelable!LockedStderr`

Locks standard error for coordinated application-level writes.

### `pub fn tryLockStderr(io: Io, buffer: []u8, terminal_mode: ?Terminal.Mode) Cancelable!?LockedStderr`

Non-blocking variant of `lockStderr`.

### `pub fn unlockStderr(io: Io) void`

Unlocks standard error after `lockStderr` or `tryLockStderr`.

## Randomness Functions

### `pub fn random(io: Io, buffer: []u8) void`

Fills `buffer` with pseudo-random bytes from a cryptographically secure generator managed by the backend.

### `pub fn randomSecure(io: Io, buffer: []u8) RandomSecureError!void`

Obtains fresh cryptographically secure entropy from outside the process.

## Default Backend Helper Functions

The root namespace also exposes default vtable helper functions. These are primarily for backend implementers and for the `failing` implementation.

### Generic helpers

- `noCrashHandler`
- `noAsync`
- `failingConcurrent`
- `unreachableAwait`
- `unreachableCancel`
- `noGroupAsync`
- `failingGroupConcurrent`
- `unreachableGroupAwait`
- `unreachableGroupCancel`
- `unreachableRecancel`
- `unreachableSwapCancelProtection`
- `unreachableCheckCancel`
- `noFutexWait`
- `noFutexWaitUncancelable`
- `noFutexWake`
- `failingOperate`
- `unreachableBatchAwaitAsync`
- `unreachableBatchAwaitConcurrent`
- `unreachableBatchCancel`
- `noRandom`
- `failingRandomSecure`
- `noNow`
- `failingClockResolution`
- `noSleep`

### Directory helpers

- `failingDirCreateDir`
- `failingDirCreateDirPath`
- `failingDirCreateDirPathOpen`
- `failingDirOpenDir`
- `failingDirStat`
- `failingDirStatFile`
- `failingDirAccess`
- `failingDirCreateFile`
- `failingDirCreateFileAtomic`
- `failingDirOpenFile`
- `unreachableDirClose`
- `noDirRead`
- `failingDirRealPath`
- `failingDirRealPathFile`
- `failingDirDeleteFile`
- `failingDirDeleteDir`
- `failingDirRename`
- `failingDirRenamePreserve`
- `failingDirSymLink`
- `failingDirReadLink`
- `failingDirSetOwner`
- `failingDirSetFileOwner`
- `failingDirSetPermissions`
- `failingDirSetFilePermissions`
- `noDirSetTimestamps`
- `failingDirHardLink`

### File helpers

- `failingFileStat`
- `failingFileLength`
- `unreachableFileClose`
- `failingFileWritePositional`
- `noFileWriteFileStreaming`
- `noFileWriteFilePositional`
- `failingFileReadPositional`
- `failingFileSeekBy`
- `failingFileSeekTo`
- `failingFileSync`
- `unreachableFileIsTty`
- `unreachableFileEnableAnsiEscapeCodes`
- `unreachableFileSupportsAnsiEscapeCodes`
- `failingFileSetLength`
- `failingFileSetOwner`
- `failingFileSetPermissions`
- `noFileSetTimestamps`
- `failingFileLock`
- `failingFileTryLock`
- `unreachableFileUnlock`
- `failingFileDowngradeLock`
- `failingFileRealPath`
- `failingFileHardLink`
- `failingFileMemoryMapCreate`
- `unreachableFileMemoryMapDestroy`
- `unreachableFileMemoryMapSetLength`
- `unreachableFileMemoryMapRead`
- `unreachableFileMemoryMapWrite`

### Process helpers

- `failingProcessExecutableOpen`
- `failingProcessExecutablePath`
- `unreachableLockStderr`
- `noTryLockStderr`
- `unreachableUnlockStderr`
- `failingProcessCurrentPath`
- `failingProcessSetCurrentDir`
- `failingProcessSetCurrentPath`
- `failingProcessReplace`
- `failingProcessReplacePath`
- `failingProcessSpawn`
- `failingProcessSpawnPath`
- `unreachableChildWait`
- `unreachableChildKill`
- `failingProgressParentFile`

### Networking helpers

- `failingNetListenIp`
- `failingNetAccept`
- `failingNetBindIp`
- `failingNetConnectIp`
- `failingNetListenUnix`
- `failingNetConnectUnix`
- `failingNetSocketCreatePair`
- `failingNetSend`
- `failingNetRead`
- `failingNetWrite`
- `failingNetWriteFile`
- `unreachableNetClose`
- `failingNetShutdown`
- `failingNetInterfaceNameResolve`
- `unreachableNetInterfaceName`
- `failingNetLookup`

## Error Sets

- `Cancelable`
- `ConcurrentError`
- `OperateTimeoutError`
- `QueueClosedError`
- `RandomSecureError`
- `UnexpectedError`

## See Also

- `std.Io.Threaded`
- `std.Io.Evented`
- `std.Io.VTable`
- `std.Io.File`
- `std.Io.Dir`
- `std.Io.net`
