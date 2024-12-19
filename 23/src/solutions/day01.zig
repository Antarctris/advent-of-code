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
    return "Day 1: Trebuchet?!";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    var calibration_value_total: u32 = 0;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        var tens: u32 = 0;
        var unit: u32 = 0;
        for (line) |char| {
            if (util.isDigit(char)) {
                unit = char - '0'; // Convert to actual number
            }
            if (tens == 0 and unit > 0) {
                tens = unit * 10;
            }
        }
        calibration_value_total += tens + unit;
    }
    return calibration_value_total;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    var calibration_value_total: u32 = 0;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        var tens: u32 = 0;
        var unit: u32 = 0;
        for (line, 0..) |char, index| {
            if (util.isDigit(char)) {
                unit = char - '0'; // Convert to actual number
            } else if (isDigitFromWord(line[index..])) |d| {
                unit = d;
            }
            if (tens == 0 and unit > 0) {
                tens = unit * 10;
            }
        }
        calibration_value_total += tens + unit;
    }
    return calibration_value_total;
}

fn isDigitFromWord(line: []const u8) ?u32 {
    if (mem.startsWith(u8, line, "one")) {
        return 1;
    } else if (mem.startsWith(u8, line, "two")) {
        return 2;
    } else if (mem.startsWith(u8, line, "three")) {
        return 3;
    } else if (mem.startsWith(u8, line, "four")) {
        return 4;
    } else if (mem.startsWith(u8, line, "five")) {
        return 5;
    } else if (mem.startsWith(u8, line, "six")) {
        return 6;
    } else if (mem.startsWith(u8, line, "seven")) {
        return 7;
    } else if (mem.startsWith(u8, line, "eight")) {
        return 8;
    } else if (mem.startsWith(u8, line, "nine")) {
        return 9;
    }
    return null;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(142, result);
}

test "part_2.sample_2" {
    const result = part_two(std.testing.allocator, sample_2) orelse return error.SkipZigTest;
    try std.testing.expectEqual(281, result);
}

const sample_1: []const u8 =
    \\1abc2
    \\pqr3stu8vwx
    \\a1b2c3d4e5f
    \\treb7uchet
    \\
;

const sample_2: []const u8 =
    \\two1nine
    \\eightwothree
    \\abcone2threexyz
    \\xtwone3four
    \\4nineeightseven2
    \\zoneight234
    \\7pqrstsixteen
    \\
;
