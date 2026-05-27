# std.c

## Overview

`std.c` exposes C ABI declarations, libc bindings, OS-specific C constants, and C-compatible types selected for the native target.

Source: `/path/to/zig-0.16.0/lib/std/c.zig`

## Public API Areas

### Common POSIX and C Types

`std.c` exports target-specific definitions for common C and POSIX types such as file descriptors, inode and offset types, user and group IDs, time structures, socket structures, pthread types, directory entries, and terminal structures.

Examples include:

- `std.c.fd_t`
- `std.c.pid_t`
- `std.c.time_t`
- `std.c.timespec`
- `std.c.timeval`
- `std.c.sockaddr`
- `std.c.socklen_t`
- `std.c.termios`
- `std.c.FILE`

### Constants and Enums

The namespace exports many OS-selected constants and enum-like groups for files, sockets, signals, polling, memory mapping, terminal control, syscalls, and platform-specific facilities.

Examples include:

- `std.c.E`
- `std.c.O`
- `std.c.S`
- `std.c.SIG`
- `std.c.SOCK`
- `std.c.AF`
- `std.c.IPPROTO`
- `std.c.MAP`
- `std.c.PROT`

### C and libc Functions

When available for the target, `std.c` exposes C ABI functions such as:

- `std.c.close`
- `std.c.clock_gettime`
- `std.c.fstat`
- `std.c.fstatat`
- `std.c.getrandom`
- `std.c.nanosleep`
- `std.c.socket`
- `std.c.stat`
- `std.c.fork`
- `std.c.wait4`

### Helpers

- `std.c.versionCheck(version)` - compile-time helper for libc version checks.
- `std.c.errno(rc)` - converts a C return code into the target errno enum.

## Notes

Prefer higher-level Zig APIs such as `std.posix`, `std.fs`, `std.process`, and `std.Io` for portable application code. Use `std.c` when code intentionally needs C ABI declarations or libc-specific behavior.
