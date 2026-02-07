# std.crypto.Certificate

### Fields

    buffer: []const u8

    index: u32

## Types

- Algorithm
- AlgorithmCategory
- Attribute
- Bundle
- ExtensionId
- GeneralNameTag
- NamedCurve
- Parsed
- Version

## Namespaces

- der
- rsa

## Functions

`pub fn contents(cert: Certificate, elem: der.Element) []const u8`  

`pub fn parse(cert: Certificate) ParseError!Parsed`  

`pub fn parseAlgorithm(bytes: []const u8, element: der.Element) ParseEnumError!Algorithm`  

`pub fn parseAlgorithmCategory(bytes: []const u8, element: der.Element) ParseEnumError!AlgorithmCategory`  

`pub fn parseAttribute(bytes: []const u8, element: der.Element) ParseEnumError!Attribute`  

`pub fn parseBitString(cert: Certificate, elem: der.Element) !der.Element.Slice`  

`pub fn parseExtensionId(bytes: []const u8, element: der.Element) ParseEnumError!ExtensionId`  

`pub fn parseNamedCurve(bytes: []const u8, element: der.Element) ParseEnumError!NamedCurve`  

`pub fn parseTime(cert: Certificate, elem: der.Element) ParseTimeError!u64`  
Returns number of seconds since epoch.

`pub fn parseTimeDigits(text: *const [2]u8, min: u8, max: u8) !u8`  

`pub fn parseVersion(bytes: []const u8, version_elem: der.Element) ParseVersionError!Version`  

`pub fn parseYear4(text: *const [4]u8) !u16`  

`pub fn verify(subject: Certificate, issuer: Certificate, now_sec: i64) !void`  

## Error Sets

- ParseBitStringError
- ParseEnumError
- ParseError
- ParseTimeError
- ParseVersionError
