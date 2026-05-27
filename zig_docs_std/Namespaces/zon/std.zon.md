# std.zon

## Overview

`std.zon` provides ZON parsing and stringification. ZON means Zig Object Notation: a textual data format whose grammar is a subset of Zig outside of `nan` and `inf` literals.

Source: `/path/to/zig-0.16.0/lib/std/zon.zig`

## Public API

- `std.zon.parse` - parser namespace imported from `zon/parse.zig`.
- `std.zon.stringify` - stringification namespace imported from `zon/stringify.zig`.
- `std.zon.Serializer` - serializer type imported from `zon/Serializer.zig`.

## Supported Values

Supported primitive syntax includes:

- boolean literals
- number literals, including `nan` and `inf`
- character literals
- enum literals
- `null` literals
- string literals
- multiline string literals

Supported container syntax includes anonymous struct literals and anonymous tuple literals.

## Notes

ZON may not contain type names. ZON has no pointer syntax, but parsers allocate as needed to match the requested Zig types, and serializers traverse pointers.
