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
    return "Day 6: Wait For It";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    var line_iterator = std.mem.tokenizeScalar(u8, input, '\n');
    var time_iterator = std.mem.tokenizeScalar(u8, line_iterator.next().?[9..], ' ');
    var dist_iterator = std.mem.tokenizeScalar(u8, line_iterator.next().?[9..], ' ');

    var combinations: u64 = 1;
    while (time_iterator.next()) |time_str| {
        if (dist_iterator.next()) |dist_str| {
            const time: u64 = std.fmt.parseInt(u64, time_str, 10) catch unreachable;
            const dist: u64 = std.fmt.parseInt(u64, dist_str, 10) catch unreachable;
            var margin: u32 = 0;
            for (0..time) |t| {
                margin += if (t * (time - t) > dist) 1 else 0;
            }
            if (margin > 0) {
                combinations *= margin;
            }
        }
    }

    return combinations;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = std.mem.splitScalar(u8, input, '\n');
    const time_str = trimInlineScalar(u8, allocator, line_iterator.next().?[9..], ' ');
    defer allocator.free(time_str);
    const dist_str = trimInlineScalar(u8, allocator, line_iterator.next().?[9..], ' ');
    defer allocator.free(dist_str);

    const time: u64 = std.fmt.parseInt(u64, time_str, 10) catch unreachable;
    const dist: u64 = std.fmt.parseInt(u64, dist_str, 10) catch unreachable;
    var margin: u64 = time;
    for (0..time) |t| {
        if (t * (time - t) > dist) {
            // Margin is symmetric, therefore when I found how many are NOT included I can
            // subtract double of that. Further if I wait the whole time, thats also not
            // working therefore I account that one, too.
            margin -= 2 * (t - 1) + 1;
            break;
        }
    }

    return margin;
}

fn trimInlineScalar(T: type, allocator: Allocator, input: []const T, scalar: T) []T {
    var accumulator = std.ArrayList(T).init(allocator);
    defer accumulator.deinit();
    var iterator = std.mem.tokenizeScalar(T, input, scalar);
    while (iterator.next()) |token| {
        accumulator.appendSlice(token) catch unreachable;
    }
    return allocator.dupe(T, accumulator.items) catch unreachable;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(288, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(71503, result);
}

const sample_1: []const u8 =
    \\Time:      7  15   30
    \\Distance:  9  40  200
    \\
;
