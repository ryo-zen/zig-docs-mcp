# std.json.Scanner.default_max_value_len

For security, the maximum size allocated to store a single string or number value is limited to 4MiB by default. This limit can be specified by calling `nextAllocMax()` instead of `nextAlloc()`.

## Source Code

```
pub const default_max_value_len = 4 * 1024 * 1024
```
