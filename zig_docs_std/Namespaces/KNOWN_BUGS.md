# Known Bugs in std.process (Zig 0.16 dev)

## posixGetUserInfo - Missing `io` parameter

**Affected Version:** Zig 0.16.0-dev.2193+fc517bd01

**Location:** `/lib/std/process.zig:146`

**Bug:**
```zig
var file_reader = file.reader(&buffer);  // ❌ Missing io parameter
```

**Should be:**
```zig
var file_reader = file.reader(io, &buffer);  // ✅ Correct
```

**Impact:** The `posixGetUserInfo(io, name)` function fails to compile because it doesn't pass the required `io` parameter to `File.reader()`.

**Workaround:** This function cannot be used in this dev version. The bug is in the stdlib itself, not user code.

**Status:** Likely fixed in newer dev builds. This is a development version issue.

**Discovered:** 2026-02-09 during documentation testing

---

## Notes

This bug was discovered while creating comprehensive tests for the std.process documentation. All other std.process functions work correctly in this version.
