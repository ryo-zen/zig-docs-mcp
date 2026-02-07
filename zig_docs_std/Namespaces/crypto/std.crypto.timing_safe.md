# std.crypto.timing_safe

Please see this accepted proposal for the long-term plans regarding constant-time operations in Zig: https://github.com/ziglang/zig/issues/1776

## Functions

`pub fn add(comptime T: type, a: []const T, b: []const T, result: []T, endian: Endian) bool`  
Add two integers serialized as arrays of the same size, in constant time. The result is stored into `result`, and `true` is returned if an overflow occurred.

`pub fn classify(ptr: anytype) void`  
Mark a value as sensitive or secret, helping to detect potential side-channel vulnerabilities.

`pub fn compare(comptime T: type, a: []const T, b: []const T, endian: Endian) Order`  
Compare two integers serialized as arrays of the same size, in constant time. Returns .lt if a\<b, .gt if a\>b and .eq if a=b

`pub fn declassify(ptr: anytype) void`  
Mark a value as non-sensitive or public, indicating it's safe from side-channel attacks.

`pub fn eql(comptime T: type, a: T, b: T) bool`  
Compares two arrays in constant time (for a given length) and returns whether they are equal. This function was designed to compare short cryptographic secrets (MACs, signatures). For all other applications, use mem.eql() instead.

`pub fn sub(comptime T: type, a: []const T, b: []const T, result: []T, endian: Endian) bool`  
Subtract two integers serialized as arrays of the same size, in constant time. The result is stored into `result`, and `true` is returned if an underflow occurred.
