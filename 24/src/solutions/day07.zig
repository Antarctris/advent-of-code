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
    return "Day 7: Bridge Repair";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var sum_one: u64 = 0;

    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;

        const separator = mem.indexOfScalar(u8, line, ':').?;
        const target = std.fmt.parseInt(u64, line[0..separator], 10) catch unreachable;
        const components = util.parseNumbersScalar(allocator, u64, 10, line[separator + 1 ..], ' ');
        defer allocator.free(components);

        sum_one += if (isEquationTrue(false, target, components[0], components[1..])) target else 0;
    }

    return sum_one;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var sum_two: u64 = 0;

    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;

        const separator = mem.indexOfScalar(u8, line, ':').?;
        const target = std.fmt.parseInt(u64, line[0..separator], 10) catch unreachable;
        const components = util.parseNumbersScalar(allocator, u64, 10, line[separator + 1 ..], ' ');
        defer allocator.free(components);

        sum_two += if (isEquationTrue(true, target, components[0], components[1..])) target else 0;
    }

    return sum_two;
}

pub fn isEquationTrue(concatenation: bool, target: u64, accumulator: u64, components: []const u64) bool {
    if (components.len == 0) {
        return target == accumulator;
    }
    return isEquationTrue(concatenation, target, accumulator + components[0], components[1..]) or
        isEquationTrue(concatenation, target, accumulator * components[0], components[1..]) or
        (concatenation and isEquationTrue(concatenation, target, concatNumbers(accumulator, components[0]), components[1..]));
}

fn concatNumbers(a: u64, b: u64) u64 {
    var pow: u64 = 10;
    while (b >= pow) pow *= 10;
    return a * pow + b;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(3749, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(11387, result);
}

const sample_1: []const u8 =
    \\190: 10 19
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
    \\
;
