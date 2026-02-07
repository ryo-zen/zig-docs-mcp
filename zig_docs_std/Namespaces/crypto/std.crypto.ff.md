# std.crypto.ff

Allocation-free, (best-effort) constant-time, finite field arithmetic for large integers.

Unlike `std.math.big`, these integers have a fixed maximum length and are only designed to be used for modular arithmetic. Arithmetic operations are meant to run in constant-time for a given modulus, making them suitable for cryptography.

Parts of that code was ported from the BSD-licensed crypto/internal/bigmod/nat.go file in the Go language, itself inspired from BearSSL.

## Types

- Modulus
- Uint

## Error Sets

- Error
- FieldElementError
- InvalidModulusError
- NullExponentError
- OverflowError
- RepresentationError
