# std.crypto.tls

Plaintext:

- type: ContentType
- legacy_record_version: u16 = 0x0303,
- length: u16,
  - The length (in bytes) of the following TLSPlaintext.fragment. The length MUST NOT exceed 2^14 bytes.
- fragment: opaque
  - the data being transmitted

Ciphertext

- ContentType opaque_type = application_data; /\* 23 \*/
- ProtocolVersion legacy_record_version = 0x0303; /\* TLS v1.2 \*/
- uint16 length;
- opaque encrypted_record\[TLSCiphertext.length\];

Handshake:

- type: HandshakeType
- length: u24
- data: opaque

ServerHello:

- ProtocolVersion legacy_version = 0x0303;
- Random random;
- opaque legacy_session_id_echo\<0..32\>;
- CipherSuite cipher_suite;
- uint8 legacy_compression_method = 0;
- Extension extensions\<6..2^16-1\>;

Extension:

- ExtensionType extension_type;
- opaque extension_data\<0..2^16-1\>;

## Types

- Alert
- ApplicationCipher
- ApplicationCipherT
- CertificateType
- ChangeCipherSpecType
- CipherSuite
- Client
- CompressionMethod
- ContentType
- Decoder
- ExtensionType
- HandshakeCipher
- HandshakeCipherT
- HandshakeType
- KeyUpdateRequest
- NamedGroup
- ProtocolVersion
- PskKeyExchangeMode
- SignatureScheme

## Values

|                                 |     |     |
|---------------------------------|-----|-----|
| close_notify_alert              |     |     |
| hello_retry_request_sequence    |     |     |
| max_ciphertext_inner_record_len |     |     |
| max_ciphertext_len              |     |     |
| max_ciphertext_record_len       |     |     |
| record_header_len               |     |     |

## Functions

`pub fn array( comptime Len: type, comptime Elem: type, elems: anytype, ) [@divExact(@bitSizeOf(Len), 8) + @divExact(@bitSizeOf(Elem), 8) * elems.len]u8`

`pub fn emptyHash(comptime Hash: type) [Hash.digest_length]u8`

`pub fn extension(et: ExtensionType, bytes: anytype) [2 + 2 + bytes.len]u8`

`pub fn hkdfExpandLabel( comptime Hkdf: type, key: [Hkdf.prk_length]u8, label: []const u8, context: []const u8, comptime len: usize, ) [len]u8`

`pub fn hmac(comptime Hmac: type, message: []const u8, key: [Hmac.key_length]u8) [Hmac.mac_length]u8`

`pub fn hmacExpandLabel( comptime Hmac: type, secret: []const u8, label_then_seed: []const []const u8, comptime len: usize, ) [len]u8`

`pub fn int(comptime Int: type, val: Int) [@divExact(@bitSizeOf(Int), 8)]u8`
