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
    return "Day 5: Print Queue";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var context = std.AutoHashMap(u64, void).init(allocator);
    defer context.deinit();

    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) break;
        var num_iterator = mem.splitScalar(u8, line, '|');
        const a = std.fmt.parseInt(u32, num_iterator.next().?, 10) catch unreachable;
        const b = std.fmt.parseInt(u32, num_iterator.next().?, 10) catch unreachable;
        context.put(appendNumbers(a, b), {}) catch unreachable;
    }

    var sum_one: u64 = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const update = util.parseNumbersScalar(allocator, u32, 10, line, ',');
        defer allocator.free(update);
        if (std.sort.isSorted(u32, update, context, cmpByHashMap)) {
            sum_one += update[(update.len) / 2];
        }
    }

    return sum_one;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var context = std.AutoHashMap(u64, void).init(allocator);
    defer context.deinit();

    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) break;
        var num_iterator = mem.splitScalar(u8, line, '|');
        const a = std.fmt.parseInt(u32, num_iterator.next().?, 10) catch unreachable;
        const b = std.fmt.parseInt(u32, num_iterator.next().?, 10) catch unreachable;
        context.put(appendNumbers(a, b), {}) catch unreachable;
    }

    var sum_two: u64 = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const update = util.parseNumbersScalar(allocator, u32, 10, line, ',');
        defer allocator.free(update);
        if (!std.sort.isSorted(u32, update, context, cmpByHashMap)) {
            std.sort.heap(u32, update, context, cmpByHashMap);
            sum_two += update[(update.len) / 2];
        }
    }

    return sum_two;
}

fn cmpByHashMap(context: std.AutoHashMap(u64, void), a: u32, b: u32) bool {
    return context.contains(appendNumbers(a, b));
}

fn appendNumbers(a: u32, b: u32) u64 {
    return (@as(u64, a) << 32) + b;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(143, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(123, result);
}

const sample_1: []const u8 =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
    \\
;
