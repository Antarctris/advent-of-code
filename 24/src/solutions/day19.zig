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
    return "Day 19: Linen Layout";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');

    var towels = std.ArrayList([]const u8).initCapacity(allocator, 500) catch unreachable;
    defer towels.deinit();
    var towel_iterator = mem.tokenizeSequence(u8, line_iterator.next().?, ", ");
    while (towel_iterator.next()) |towel| {
        towels.appendAssumeCapacity(towel);
    }

    var design_memo = std.StringHashMap(bool).init(allocator);
    defer design_memo.deinit();

    var working_designs: u64 = 0;
    while (line_iterator.next()) |design| {
        if (matchTowelToDesign(towels.items, &design_memo, design)) working_designs += 1;
    }

    return working_designs;
}

fn matchTowelToDesign(towels: [][]const u8, design_memo: *std.StringHashMap(bool), design: []const u8) bool {
    if (design_memo.get(design)) |r| return r;
    if (design.len == 0) return true;
    var result = false;
    for (towels) |towel| {
        if (mem.startsWith(u8, design, towel)) {
            result = matchTowelToDesign(towels, design_memo, design[towel.len..]);
            if (result) break;
        }
    }
    design_memo.put(design, result) catch unreachable;
    return result;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');

    var towels = std.ArrayList([]const u8).initCapacity(allocator, 500) catch unreachable;
    defer towels.deinit();
    var towel_iterator = mem.tokenizeSequence(u8, line_iterator.next().?, ", ");
    while (towel_iterator.next()) |towel| {
        towels.appendAssumeCapacity(towel);
    }

    var design_memo = std.StringHashMap(u64).init(allocator);
    defer design_memo.deinit();

    var design_options: u64 = 0;
    while (line_iterator.next()) |design| {
        design_options += countTowelDesignOptions(towels.items, &design_memo, design);
    }

    return design_options;
}

fn countTowelDesignOptions(towels: [][]const u8, design_memo: *std.StringHashMap(u64), design: []const u8) u64 {
    if (design_memo.get(design)) |r| return r;
    if (design.len == 0) return 1;
    var result: u64 = 0;
    for (towels) |towel| {
        if (mem.startsWith(u8, design, towel)) {
            result += countTowelDesignOptions(towels, design_memo, design[towel.len..]);
        }
    }
    design_memo.put(design, result) catch unreachable;
    return result;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(6, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(16, result);
}

const sample_1: []const u8 =
    \\r, wr, b, g, bwu, rb, gb, br
    \\
    \\brwrr
    \\bggr
    \\gbbr
    \\rrbgbr
    \\ubwu
    \\bwurrg
    \\brgr
    \\bbrgwb
    \\
;
