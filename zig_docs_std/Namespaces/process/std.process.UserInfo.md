# std.process.UserInfo

📚 **[See Comprehensive Examples & Tests](../../Examples/)**

## Overview

`std.process.UserInfo` is a structure that stores the User ID (UID) and Group ID (GID) of a user. It is typically returned by `std.process.posixGetUserInfo()`.

---

## Fields

`uid: std.posix.uid_t`
------
The numerical User ID.

`gid: std.posix.gid_t`
------
The numerical Group ID of the user's primary group.

---

## Usage Example

```zig
const info = try std.process.posixGetUserInfo(init.io, "root");
std.debug.print("UID: {d}, GID: {d}\n", .{ info.uid, info.gid });
```

---

## See Also

- **std.process.posixGetUserInfo** - The function used to look up user information by name on POSIX systems.
- **std.process.SpawnOptions** - Uses `uid` and `gid` to set child process identity.
