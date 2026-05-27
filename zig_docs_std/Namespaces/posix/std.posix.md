# std.posix

## Overview

`std.posix` contains POSIX-style types, constants, and syscall wrappers with Zig error sets. It selects a platform `system` namespace based on the target and whether libc is linked.

Source: `/path/to/zig-0.16.0/lib/std/posix.zig`

## Public API Areas

### Platform Binding

- `std.posix.system` - selected system namespace for the native target.
- Constants and types re-exported from `system`, including address families, file flags, socket options, signal constants, file descriptor types, time structs, socket structs, and terminal types.

### Process and Signal Helpers

- `std.posix.reboot`
- `std.posix.raise`
- `std.posix.kill`
- `std.posix.getppid`
- `std.posix.sigfillset`
- `std.posix.sigemptyset`
- `std.posix.sigaddset`
- `std.posix.sigdelset`
- `std.posix.sigismember`
- `std.posix.sigaction`
- `std.posix.sigprocmask`
- `std.posix.sigaltstack`

### File Descriptors and Memory

- `std.posix.read`
- `std.posix.openat`
- `std.posix.openatZ`
- `std.posix.mmap`
- `std.posix.munmap`
- `std.posix.mremap`
- `std.posix.msync`
- `std.posix.memfd_create`
- `std.posix.memfd_createZ`
- `std.posix.fdatasync`
- `std.posix.sync`
- `std.posix.syncfs`

### Networking and Polling

- `std.posix.getpeername`
- `std.posix.gethostname`
- `std.posix.poll`
- `std.posix.ppoll`
- `std.posix.setsockopt`

### System Information and Controls

- `std.posix.uname`
- `std.posix.getrusage`
- `std.posix.getrlimit`
- `std.posix.setrlimit`
- `std.posix.sysctl`
- `std.posix.sched_getaffinity`
- `std.posix.prctl`
- `std.posix.mincore`
- `std.posix.madvise`
- `std.posix.perf_event_open`
- `std.posix.ptrace`

### Terminal Helpers

- `std.posix.tcgetattr`
- `std.posix.tcsetattr`
- `std.posix.tcgetpgrp`
- `std.posix.tcsetpgrp`

### Error and Path Helpers

- `std.posix.UnexpectedError`
- `std.posix.unexpectedErrno`
- `std.posix.toPosixPath`

## Notes

Most wrappers return narrow Zig error sets rather than raw errno values. Prefer higher-level namespaces such as `std.fs`, `std.process`, or `std.Io` unless code specifically needs POSIX-level behavior.
