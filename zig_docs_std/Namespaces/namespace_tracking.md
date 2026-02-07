# Zig std Namespace Documentation Priority

## Tier 1 - Essential (used in almost every project)
| Namespace | Description | Status |
|-----------|-------------|--------|
| `mem` | Memory manipulation, allocation, slicing, comparison | Done |
| `fmt` | String formatting, printing, parsing | Done |
| `fs` | Path manipulation (0.16: file I/O moved to std.Io.Dir) | Done |
| `heap` | Allocators (GeneralPurpose, page, arena, c) | Done |
| `testing` | Test assertions, expect, allocator for tests | Not started |
| `log` | Structured logging | Not started |
| `array_list` | Dynamic arrays (ArrayList) | Partial (Types) |
| `hash_map` | Hash maps (HashMap, AutoHashMap) | Partial (Types) |

## Tier 2 - Very Common (most non-trivial projects)
| Namespace | Description | Status |
|-----------|-------------|--------|
| `json` | JSON parsing and serialization | Not started |
| `math` | Math operations, min/max, clamp, overflow | Not started |
| `sort` | Sorting algorithms | Not started |
| `ascii` | ASCII character classification and manipulation | Not started |
| `os` | OS-level interfaces (env, signals) | Not started |
| `process` | Child processes, environment, args | Not started |
| `debug` | Stack traces, assert, panic handling | Not started |
| `time` | Timers, timestamps, sleep | Not started |
| `http` | HTTP client/server | Not started |

## Tier 3 - Moderate Use (specific domains)
| Namespace | Description | Status |
|-----------|-------------|--------|
| `builtin` | Compile-time target info, cpu, os, features | Not started |
| `unicode` | Unicode handling, UTF-8/16 | Not started |
| `compress` | Compression (zlib, gzip, zstd, xz) | Not started |
| `crypto` | Hashing, encryption, random | Not started |
| `bit_set` | Bit set data structures | Not started |
| `enums` | Enum utilities (from std.enums, not the language feature) | Not started |
| `atomic` | Atomic operations for concurrency | Not started |
| `array_hash_map` | Ordered hash maps (insertion-order preserving) | Partial (Types) |
| `static_string_map` | Compile-time string lookup maps | Not started |

## Tier 4 - Specialized (specific use cases)
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

## Tier 5 - Niche (advanced/low-level)
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

## Notes
- **Tier 1** should be documented first - these are the namespaces every Zig programmer needs
- **Tier 2** covers the next most common needs and should follow soon after
- Types already partially documented (ArrayList, HashMap, ArrayHashMap) under `zig_docs_std/Types/`
- `mem` is the only namespace with full documentation so far
