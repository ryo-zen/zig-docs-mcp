# std.json.static.ParseOptions

Controls how to deal with various inconsistencies between the JSON document and the Zig struct type passed in. For duplicate fields or unknown fields, set options in this struct. For missing fields, give the Zig struct fields default values.

### Fields

    duplicate_field_behavior: enum {
  use_first,
  @"error",
  use_last,
    } = .@"error"

Behaviour when a duplicate field is encountered. The default is to return `error.DuplicateField`.

    ignore_unknown_fields: bool = false

If false, finding an unknown field returns `error.UnknownField`.

    max_value_len: ?usize = null

Passed to `std.json.Scanner.nextAllocMax` or `std.json.Reader.nextAllocMax`. The default for `parseFromSlice` or `parseFromTokenSource` with a `*std.json.Scanner` input is the length of the input slice, which means `error.ValueTooLong` will never be returned. The default for `parseFromTokenSource` with a `*std.json.Reader` is `std.json.default_max_value_len`. Ignored for `parseFromValue` and `parseFromValueLeaky`.

    allocate: ?AllocWhen = null

This determines whether strings should always be copied, or if a reference to the given buffer should be preferred if possible. The default for `parseFromSlice` or `parseFromTokenSource` with a `*std.json.Scanner` input is `.alloc_if_needed`. The default with a `*std.json.Reader` input is `.alloc_always`. Ignored for `parseFromValue` and `parseFromValueLeaky`.

    parse_numbers: bool = true

When parsing to a `std.json.Value`, set this option to false to always emit JSON numbers as unparsed `std.json.Value.number_string`. Otherwise, JSON numbers are parsed as either `std.json.Value.integer`, `std.json.Value.float` or left as unparsed `std.json.Value.number_string` depending on the format and value of the JSON number. When this option is true, JSON numbers encoded as floats (see `std.json.isNumberFormattedLikeAnInteger`) may lose precision when being parsed into `std.json.Value.float`.
