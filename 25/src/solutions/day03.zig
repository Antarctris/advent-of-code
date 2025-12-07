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
    return "Day 3: Lobby";
}

pub fn part_one(allocator: Allocator, input: []const u8) !Solution.Result {
    _ = allocator;

    var result: u64 = 0;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        var left = line[0];
        var right = line[1];
        for (2..line.len) |i| {
            if (right > left) {
                left = right;
                right = line[i];
            } else if (line[i] > right) {
                right = line[i];
            }
        }
        result += (left - '0') * 10 + (right - '0');
    }

    return Solution.Result.number(result);
}

pub fn part_two(allocator: Allocator, input: []const u8) !Solution.Result {
    _ = allocator;

    var result: u64 = 0;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        result += try findLargestNumber(12, line);
    }

    return Solution.Result.number(result);
}

// I could have used this to replace my original solution of part 1, but I
// think this would be slower for part 1, therefore I left it as is.
fn findLargestNumber(comptime num_of_digits: usize, num_str: []const u8) !u64 {
    var num_idx: [num_of_digits]usize = undefined;
    var num_val: [num_of_digits]u8 = undefined;
    num_idx[0] = findTopDigit(num_str[0 .. num_str.len - (num_of_digits - 1)]);
    for (1..num_of_digits) |i| {
        const min_idx: usize = num_idx[i - 1] + 1;
        const max_idx: usize = num_str.len - (num_of_digits - 1) + i;
        num_idx[i] = min_idx + findTopDigit(num_str[min_idx..max_idx]);
    }
    for (0..12) |i| {
        num_val[i] = num_str[num_idx[i]];
    }
    return try std.fmt.parseInt(u64, &num_val, 10);
}

fn findTopDigit(number_str: []const u8) usize {
    var r: usize = 0;
    for (0..number_str.len) |i| {
        if (number_str[i] > number_str[r]) {
            r = i;
        }
    }
    return r;
}

test "part_1.sample_1" {
    var result = try part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(357, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = try part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(3121910778619, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\987654321111111
    \\811111111111119
    \\234234234234278
    \\818181911112111
;
