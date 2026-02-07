# std.crypto.Certificate.Parsed

### Fields

    certificate: Certificate

    issuer_slice: Slice

    subject_slice: Slice

    common_name_slice: Slice

    signature_slice: Slice

    signature_algorithm: Algorithm

    pub_key_algo: PubKeyAlgo

    pub_key_slice: Slice

    message_slice: Slice

    subject_alt_name_slice: Slice

    validity: Validity

    version: Version

## Types

- PubKeyAlgo
- Slice
- Validity

## Functions

`pub fn commonName(p: Parsed) []const u8`  

`pub fn issuer(p: Parsed) []const u8`  

`pub fn message(p: Parsed) []const u8`  

`pub fn pubKey(p: Parsed) []const u8`  

`pub fn signature(p: Parsed) []const u8`  

`pub fn slice(p: Parsed, s: Slice) []const u8`  

`pub fn subject(p: Parsed) []const u8`  

`pub fn subjectAltName(p: Parsed) []const u8`  

`pub fn verify(parsed_subject: Parsed, parsed_issuer: Parsed, now_sec: i64) VerifyError!void`  
This function verifies:

- That the subject's issuer is indeed the provided issuer.
- The time validity of the subject.
- The signature.

`pub fn verifyHostName(parsed_subject: Parsed, host_name: []const u8) VerifyHostNameError!void`  

## Error Sets

- VerifyError
- VerifyHostNameError
