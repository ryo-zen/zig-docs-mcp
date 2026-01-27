const std = @import("std");
pub fn main() void {
    const list = std.array_list.Managed(u8);
    _ = list;
}
