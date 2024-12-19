const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

const util = @import("util");
const Solution = @import("./solution.zig");

// interface
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day ";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    _ = input;
    return null;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    _ = input;
    return null;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(null, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(null, result);
}

const sample_1: []const u8 =
    \\
;
