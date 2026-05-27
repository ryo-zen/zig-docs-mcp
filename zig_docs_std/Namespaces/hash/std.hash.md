# std.hash

## Overview

`std.hash` provides non-cryptographic hash functions and helpers used for checksums, hash tables, and fast content hashing.

Source: `/path/to/zig-0.16.0/lib/std/hash.zig`

## Public API

### Generic and Auto Hashing

- `std.hash.autoHash` - hashes values using the standard auto-hash implementation.
- `std.hash.autoHashStrat` - hashes with an explicit hash strategy.
- `std.hash.Strategy` - strategy enum/type from `hash/auto_hash.zig`.
- `std.hash.int(input)` - integer-to-integer hash for integer bit widths up to 256.

### Checksum and Non-Cryptographic Hashes

- `std.hash.Adler32`
- `std.hash.crc`
- `std.hash.Crc32`
- `std.hash.Fnv1a_32`
- `std.hash.Fnv1a_64`
- `std.hash.Fnv1a_128`
- `std.hash.Murmur2_32`
- `std.hash.Murmur2_64`
- `std.hash.Murmur3_32`
- `std.hash.CityHash32`
- `std.hash.CityHash64`
- `std.hash.Wyhash`
- `std.hash.XxHash3`
- `std.hash.XxHash64`
- `std.hash.XxHash32`

### SipHash

- `std.hash.SipHash64`
- `std.hash.SipHash128`

## Notes

This namespace is not a general cryptography API. For cryptographic hashes, message authentication, key derivation, signatures, or side-channel-sensitive operations, use `std.crypto`.
