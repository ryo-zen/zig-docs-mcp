# Zig std Namespace Documentation Priority

## Zig 0.16.0 Migration Backlog

Current status:
- [x] Compile-check all `zig_docs_std/Examples/*.zig` with `zig test --test-no-exec`.
- [x] Build-check every example with `pub fn main` using `zig build-exe -fno-emit-bin`.
- [ ] Sweep docs for stale 0.15-era API names and update examples/snippets.
- [ ] Re-run TypeScript tests after doc/index changes: `npm test`.

Verification commands:

```sh
zig test "$file" --test-no-exec --cache-dir /tmp/zig-docs-mcp-cache --global-cache-dir /tmp/zig-docs-mcp-global-cache
zig build-exe "$file" -fno-emit-bin --cache-dir /tmp/zig-docs-mcp-cache --global-cache-dir /tmp/zig-docs-mcp-global-cache
npm test
```

### P0 - Stale Docs To Fix First

- [ ] Update `zig_docs/migration_016.md` into the main 0.15-to-0.16 stdlib migration checklist.
- [ ] Fix `zig_docs/simple_timestamp_016.md` for current `std.Io.Clock` / `std.Io.Timestamp` APIs.
- [ ] Fix `zig_docs/migration_time.md` examples for `std.time.Instant`, `std.time.Timer`, and `std.time.timestamp` migrations.
- [ ] Fix `zig_docs/common_errors.md` error-name migration examples.
- [ ] Fix `zig_docs/performance.md` if examples still use removed time APIs.
- [ ] Fix process docs under `zig_docs_std/Namespaces/process/` for removed `Child` APIs, `collectOutput`, and `getCwd*`.
- [ ] Fix heap docs under `zig_docs_std/Namespaces/heap/` for `DebugAllocator` and removed `ThreadSafeAllocator`.
- [ ] Review Io docs for removed or stale `PollFiles`, `Poller`, `GenericWriter`, `AnyWriter`, `null_writer`, and `CountingReader` references.

### P1 - 0.16 Migration Topics To Cover

- [ ] I/O interface: explain accepting `std.Io`, using `init.io`, `std.testing.io`, and temporary `Io.Threaded` fallbacks.
- [ ] File system: document `std.fs.Dir/File` migration to `std.Io.Dir/File` and the new `io` parameters.
- [ ] Process: document `std.process.Init`, `Init.Minimal`, args, env maps, `spawn`, `run`, and `replace`.
- [ ] Time: document `std.Io.Clock`, `std.Io.Timestamp`, `Duration`, `Timeout`, and current-path clock behavior.
- [ ] Entropy: document `std.crypto.random` and `posix.getrandom` migration to `io.random` / `io.randomSecure`.
- [ ] Sync primitives: document `std.Thread.*` migrations to `std.Io.Event`, `Group`, `Futex`, `Mutex`, `Condition`, `Semaphore`, and `RwLock`.
- [ ] Formatting/writers: document `Formatter` to `Alt`, `FormatOptions` to `Options`, `format` to `std.Io.Writer.print`, and `bufPrintZ` to `bufPrintSentinel`.
- [ ] Containers: document removed `SegmentedList`, managed `ArrayHashMap` variants, `PriorityQueue` / `PriorityDequeue` method renames, and `BitSet` / `EnumSet` literal initialization.
- [ ] Debug: document `captureCurrentStackTrace`, `writeCurrentStackTrace`, `dumpCurrentStackTrace`, and removed stack iterator APIs.
- [ ] Errors: document renamed errors such as `CrossDevice`, `FileBusy`, and `EnvironmentVariableMissing`.
- [ ] Path APIs: document pure `std.fs.path.relative` signatures without blanket-replacing valid `std.fs.path` utilities.

### P2 - New Examples Worth Adding

- [ ] `std.process.Init` main function with args, env, allocator, and `io`.
- [ ] `std.testing.io` in tests.
- [ ] `Io.Dir.renamePreserve`.
- [ ] `Io.net.Socket.createPair`.
- [ ] `Io.Dir.walkSelectively`.
- [ ] `io.async` / `Future.await` / `Future.cancel`.
- [ ] `Io.Group` task management.
- [ ] `Io.Queue(T)` producer/consumer example.
- [ ] `Io.Batch` once the docs can show a small stable operation.
- [ ] `std.process.run` capturing stdout/stderr with reader APIs.
- [ ] `io.random` and `std.Random.IoSource`.
- [ ] `std.Io.Writer.print` replacing old formatting examples.

### P3 - Removed Or Renamed API Search List

- [ ] Search and resolve: `std.io`, `fixedBufferStream`, `FixedBufferStream`.
- [ ] Search and resolve: `std.fs.cwd`, `std.fs.File`, `std.fs.Dir`, removed absolute/Z/W filesystem helpers.
- [ ] Search and resolve: `std.process.getCwd`, `std.process.getCwdAlloc`, `std.process.argsWithAllocator`.
- [ ] Search and resolve: `std.process.Child.init`, `std.process.Child.run`, `collectOutput`, `execv`.
- [ ] Search and resolve: `std.crypto.random`, `posix.getrandom`.
- [ ] Search and resolve: `std.Thread.Mutex`, `WaitGroup`, `ResetEvent`, `Condition`, `Semaphore`, `RwLock`, `Pool`.
- [ ] Search and resolve: `ThreadSafeAllocator`, `std.once`.
- [ ] Search and resolve: `ArrayHashMap(`, `AutoArrayHashMap(`, `StringArrayHashMap(`, and unmanaged alias docs.
- [ ] Search and resolve: `std.time.Instant`, `std.time.Timer`, `std.time.timestamp`.
- [ ] Search and resolve: `std.leb.readUleb128`, `std.leb.readIleb128`.
- [ ] Search and resolve: old error names from the 0.16 changelog.

## Tier 1 - Essential
| Namespace | Description | Status |
|-----------|-------------|--------|
| `mem` | Memory manipulation, allocation, slicing, comparison | ✅ Done |
| `fmt` | String formatting, printing, parsing | ✅ Done |
| `fs` | Path manipulation (0.16: file I/O moved to std.Io.Dir) | ✅ Done |
| `heap` | Allocators (GeneralPurpose, page, arena, c) | ✅ Done |
| `testing` | Test assertions, expect, allocator for tests | ✅ Done |
| `log` | Structured logging | ✅ Done |
| `array_list` | Dynamic arrays (ArrayList) | ✅ Done |
| `hash_map` | Hash maps (HashMap, AutoHashMap) | ✅ Done |

## Tier 2 - Very Common
| Namespace | Description | Status |
|-----------|-------------|--------|
| `json` | JSON parsing and serialization | ✅ Done |
| `math` | Math operations, min/max, clamp, overflow | ✅ Done |
| `sort` | Sorting algorithms | Not started |
| `ascii` | ASCII character classification and manipulation | Not started |
| `os` | OS-level interfaces (env, signals) | Not started |
| `process` | Child processes, environment, args | ✅ Done |
| `debug` | Stack traces, assert, panic handling | ✅ Done |
| `time` | Timers, timestamps, sleep | Not started |
| `http` | HTTP client/server | Not started |

## Tier 3 - Moderate Use
| Namespace | Description | Status |
|-----------|-------------|--------|
| `builtin` | Compile-time target info, cpu, os, features | Not started |
| `unicode` | Unicode handling, UTF-8/16 | Not started |
| `compress` | Compression (zlib, gzip, zstd, xz) | Not started |
| `crypto` | Hashing, encryption, random | ✅ Done |
| `bit_set` | Bit set data structures | Not started |
| `enums` | Enum utilities (from std.enums, not the language feature) | Not started |
| `atomic` | Atomic operations for concurrency | ✅ Done |
| `array_hash_map` | Ordered hash maps (insertion-order preserving) | Partial (Types) |
| `static_string_map` | Compile-time string lookup maps | Not started |

## Tier 4 - Specialized
| Namespace | Description | Status |
|-----------|-------------|--------|
| `zon` | ZON (Zig Object Notation) parsing | Not started |
| `tar` | Tar archive handling | Not started |
| `zip` | Zip archive handling | Not started |
| `base64` | Base64 encoding/decoding | Not started |
| `leb` | LEB128 integer encoding | Not started |
| `tz` | Timezone handling | Not started |
| `c` | C interop utilities | Not started |
| `posix` | POSIX system calls | Not started |

## Tier 5 - Niche
| Namespace | Description | Status |
|-----------|-------------|--------|
| `meta` | Compile-time type introspection/reflection | Not started |
| `simd` | SIMD vector operations | Not started |
| `wasm` | WebAssembly support | Not started |
| `gpu` | GPU compute support | Not started |
| `elf` | ELF binary format parsing | Not started |
| `coff` | COFF binary format parsing | Not started |
| `macho` | Mach-O binary format parsing | Not started |
| `dwarf` | DWARF debug info parsing | Not started |
| `pdb` | PDB debug info parsing | Not started |
| `pie` | Position-independent executable support | Not started |
| `valgrind` | Valgrind integration | Not started |
| `start` | Program startup/entry point | Not started |
| `zig` | Zig compiler/toolchain internals | Not started |
