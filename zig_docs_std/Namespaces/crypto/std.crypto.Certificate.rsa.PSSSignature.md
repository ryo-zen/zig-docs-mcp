# std.crypto.Certificate.rsa.PSSSignature

RFC 3447 8.1 RSASSA-PSS

## Functions

`pub fn concatVerify( comptime modulus_len: usize, sig: [modulus_len]u8, msg: []const []const u8, public_key: PublicKey, comptime Hash: type, ) VerifyError!void`  

`pub fn fromBytes(comptime modulus_len: usize, msg: []const u8) [modulus_len]u8`  

`pub fn verify( comptime modulus_len: usize, sig: [modulus_len]u8, msg: []const u8, public_key: PublicKey, comptime Hash: type, ) VerifyError!void`  

## Error Sets

- VerifyError
