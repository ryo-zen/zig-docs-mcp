# std.crypto.pwhash

A password hashing function derives a uniform key from low-entropy input material such as passwords. It is intentionally slow or expensive.

With the standard definition of a key derivation function, if a key space is small, an exhaustive search may be practical. Password hashing functions make exhaustive searches way slower or way more expensive, even when implemented on GPUs and ASICs, by using different, optionally combined strategies:

- Requiring a lot of computation cycles to complete
- Requiring a lot of memory to complete
- Requiring multiple CPU cores to complete
- Requiring cache-local data to complete in reasonable time
- Requiring large static tables
- Avoiding precomputations and time/memory tradeoffs
- Requiring multi-party computations
- Combining the input material with random per-entry data (salts), application-specific contexts and keys

Password hashing functions must be used whenever sensitive data has to be directly derived from a password.

## Types

- Encoding

## Namespaces

- argon2
- bcrypt
- phc_format
- scrypt

## Functions

`pub fn pbkdf2(dk: []u8, password: []const u8, salt: []const u8, rounds: u32, comptime Prf: type) (WeakParametersError || OutputTooLongError)!void`
Apply PBKDF2 to generate a key from a password.

## Error Sets

- Error
- HasherError
- KdfError
