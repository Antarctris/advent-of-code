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
    return "Day 1: Historian Hysteria";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.splitScalar(u8, input, '\n');

    var l = std.PriorityQueue(u64, void, lessThan).init(allocator, {});
    defer l.deinit();
    var r = std.PriorityQueue(u64, void, lessThan).init(allocator, {});
    defer r.deinit();

    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        var lr_tokens = mem.tokenize(u8, line, " ");
        const l_value = std.fmt.parseInt(u64, lr_tokens.next().?, 10) catch unreachable;
        l.add(l_value) catch unreachable;
        const r_value = std.fmt.parseInt(u64, lr_tokens.next().?, 10) catch unreachable;
        r.add(r_value) catch unreachable;
    }

    var similarity_score: u64 = 0;
    while (l.removeOrNull()) |lv| {
        if (r.removeOrNull()) |rv| {
            similarity_score += @max(lv, rv) - @min(lv, rv);
        }
    }
    return similarity_score;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.splitScalar(u8, input, '\n');

    var l = std.PriorityQueue(u64, void, lessThan).init(allocator, {});
    defer l.deinit();
    var r = std.AutoHashMap(u64, u64).init(allocator);
    defer r.deinit();

    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        var lr_tokens = mem.tokenize(u8, line, " ");
        const l_value = std.fmt.parseInt(u64, lr_tokens.next().?, 10) catch unreachable;
        l.add(l_value) catch unreachable;
        const r_value = std.fmt.parseInt(u64, lr_tokens.next().?, 10) catch unreachable;
        r.put(r_value, 1 + (r.get(r_value) orelse 0)) catch unreachable;
    }

    var similarity_score: u64 = 0;
    while (l.removeOrNull()) |lv| {
        similarity_score += lv * (r.get(lv) orelse 0);
    }
    return similarity_score;
}

fn lessThan(context: void, a: u64, b: u64) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;

    try std.testing.expectEqual(11, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;

    try std.testing.expectEqual(31, result);
}

const sample_1: []const u8 =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
    \\
;
