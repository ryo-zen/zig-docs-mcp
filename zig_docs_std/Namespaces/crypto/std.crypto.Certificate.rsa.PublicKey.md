# std.crypto.Certificate.rsa.PublicKey

### Fields

    n: Modulus

    e: Fe

## Functions

`pub fn fromBytes(pub_bytes: []const u8, modulus_bytes: []const u8) FromBytesError!PublicKey`

`pub fn parseDer(pub_key: []const u8) ParseDerError!struct { modulus: []const u8, exponent: []const u8 }`

## Error Sets

- FromBytesError
- ParseDerError
