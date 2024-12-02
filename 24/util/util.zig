const std = @import("std");

pub const grid = @import("grid.zig");
pub const mem = @import("mem.zig");

pub fn parseNumbers(allocator: std.mem.Allocator, comptime T: type, string: []const u8, base: u8) []T {
    var numbers = std.ArrayList(T).init(allocator);
    defer numbers.deinit();
    var iterator = std.mem.tokenizeScalar(u8, string, ' ');
    while (iterator.next()) |num_str| {
        const number = std.fmt.parseInt(T, num_str, base) catch unreachable;
        numbers.append(number) catch unreachable;
    }
    return allocator.dupe(T, numbers.items) catch unreachable;
}

pub fn isDigit(char: u8) bool {
    return intFromDigit(char) != null;
}

pub fn intFromDigit(char: u8) ?u4 {
    return switch (char) {
        '0'...'9' => @intCast(char - '0'),
        else => null,
    };
}
