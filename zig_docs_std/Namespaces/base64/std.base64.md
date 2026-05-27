# std.base64

## Overview

`std.base64` provides Base64 encoders and decoders as specified by RFC 4648.

Source: `/path/to/zig-0.16.0/lib/std/base64.zig`

## Public API

### Errors and Codec Description

- `std.base64.Error` - `error.InvalidCharacter`, `error.InvalidPadding`, or `error.NoSpaceLeft`.
- `std.base64.Codecs` - groups an alphabet, padding character, encoder, decoder, and ignored-character decoder factory.

### Built-In Codecs

- `std.base64.standard_alphabet_chars` - RFC 4648 standard alphabet.
- `std.base64.standard` - standard Base64 with `=` padding.
- `std.base64.standard_no_pad` - standard Base64 without padding.
- `std.base64.url_safe_alphabet_chars` - URL-safe alphabet using `-` and `_`.
- `std.base64.url_safe` - URL-safe Base64 with `=` padding.
- `std.base64.url_safe_no_pad` - URL-safe Base64 without padding.

### Encoder and Decoders

- `std.base64.Base64Encoder` - initialized with an alphabet and optional padding character.
- `std.base64.Base64Decoder` - decoder for one alphabet and padding mode.
- `std.base64.Base64DecoderWithIgnore` - decoder that can skip configured ignored bytes, commonly whitespace.

## Common Pattern

```zig
const std = @import("std");

const input = "hello";
var encoded: [std.base64.standard.Encoder.calcSize(input.len)]u8 = undefined;
const out = std.base64.standard.Encoder.encode(&encoded, input);

var decoded: [input.len]u8 = undefined;
try std.base64.standard.Decoder.decode(&decoded, out);
```

Allocate or size destination buffers using the encoder and decoder size helpers before calling encode or decode.
