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
    return "Day 3: Mull It Over";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    return parseAndCalculate(input, false);
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    return parseAndCalculate(input, true);
}

pub fn parseAndCalculate(line: []const u8, toggle: bool) u64 {
    var line_total: u64 = 0;
    var enabled: bool = true;
    var state: u8 = 0;
    var a: u64 = 0;
    var b: u64 = 0;
    for (line) |c| {
        if (c == '\n') continue;
        if ((enabled and c == 'm') or (toggle and c == 'd')) {
            state = c;
            continue;
        }
        switch (state) {
            'm' => state = if (c == 'u') 'u' else 0,
            'u' => state = if (c == 'l') 'l' else 0,
            'l' => {
                if (c == '(') {
                    a = 0;
                    state = 'A';
                } else {
                    state = 0;
                }
            },
            'A' => {
                if (util.intFromDigit(c)) |d| {
                    a = a * 10 + d;
                    if (a > 999) state = 0;
                } else if (c == ',') {
                    b = 0;
                    state = 'B';
                } else {
                    state = 0;
                }
            },
            'B' => {
                if (util.intFromDigit(c)) |d| {
                    b = b * 10 + d;
                    if (b > 999) state = 0;
                } else {
                    if (c == ')') {
                        line_total += a * b;
                    }
                    state = 0;
                }
            },
            'd' => state = if (c == 'o') 'o' else 0,
            'o' => state = if (c == 'n') 'n' else if (c == '(') 'E' else 0,
            'n' => state = if (c == '\'') '\'' else 0,
            '\'' => state = if (c == 't') 't' else 0,
            't' => state = if (c == '(') 'D' else 0,
            'E' => {
                if (c == ')') {
                    enabled = true;
                }
                state = 0;
            },
            'D' => {
                if (c == ')') {
                    enabled = false;
                }
                state = 0;
            },
            else => state = 0,
        }
    }
    return line_total;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(161, result);
}

test "part_2.sample_2" {
    const result = part_two(std.testing.allocator, sample_2) orelse return error.SkipZigTest;
    try std.testing.expectEqual(48, result);
}

const sample_1: []const u8 =
    \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
    \\
;

const sample_2: []const u8 =
    \\xmul(2,4)&mul[3,7]!muldon't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
    \\
;
