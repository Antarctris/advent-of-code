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
    return "Day 1: Secret Entrance";
}

pub fn part_one(allocator: Allocator, input: []const u8) !Solution.Result {
    _ = allocator;

    var result: u64 = 0;
    var dial: i64 = 50;

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const op: i64 = if (line[0] == 'R') 1 else -1;
        const n: i64 = try std.fmt.parseInt(i64, line[1..], 10);
        dial += op * n;
        dial = @mod(dial, 100);
        if (dial == 0) {
            result += 1;
        }
    }

    return Solution.Result.number(result);
}

pub fn part_two(allocator: Allocator, input: []const u8) !Solution.Result {
    _ = allocator;
    var result: u64 = 0;
    var dial: i64 = 50;

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const op: i64 = if (line[0] == 'R') 1 else -1;
        const n: i64 = try std.fmt.parseInt(i64, line[1..], 10);
        result += @intCast(@divFloor(n, 100));
        const old = dial;
        dial += op * @mod(n, 100);
        // Only accounting for negative, if not starting at 0, since that 0 was
        // already accounted for
        if ((old != 0 and dial < 1) or dial > 99) {
            result += 1;
        }
        dial = @mod(dial, 100);
    }

    return Solution.Result.number(result);
}

test "part_1.sample_1" {
    var result = try part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(3, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = try part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(6, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_2" {
    var result = try part_two(std.testing.allocator, sample_2);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(28, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\L68
    \\L30
    \\R48
    \\L5
    \\R60
    \\L55
    \\L1
    \\L99
    \\R14
    \\L82
;

// 1, 1, 5, 1, 1, 5, 1, 1, 5, 1, 1, 5
const sample_2: []const u8 =
    \\R50
    \\R100
    \\R500
    \\R150
    \\R100
    \\R500
    \\L50
    \\L100
    \\L500
    \\L150
    \\L100
    \\L500
;
