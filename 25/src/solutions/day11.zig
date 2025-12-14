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
    return "Day 11: Reactor";
}

pub fn part_one(allocator: Allocator, input: []const u8) !Solution.Result {
    var map = std.AutoHashMap(u64, []const u8).init(allocator);
    defer map.deinit();

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        try map.put(k(line[0..3]), line[5..]);
    }

    var memo = std.AutoHashMap(u64, u64).init(allocator);
    defer memo.deinit();

    const routes = try countRoutesRec(&memo, &map, k("you"), k("out"));

    return Solution.Result.number(routes);
}

pub fn part_two(allocator: Allocator, input: []const u8) !Solution.Result {
    var map = std.AutoHashMap(u64, []const u8).init(allocator);
    defer map.deinit();

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        try map.put(k(line[0..3]), line[5..]);
    }

    var memo = std.AutoHashMap(u64, u64).init(allocator);
    defer memo.deinit();

    const svr_to_fft = try countRoutesRec(&memo, &map, k("svr"), k("fft"));
    memo.clearRetainingCapacity();
    const fft_to_dac = try countRoutesRec(&memo, &map, k("fft"), k("dac"));
    memo.clearRetainingCapacity();
    const dac_to_out = try countRoutesRec(&memo, &map, k("dac"), k("out"));
    const bad_routes: u64 = svr_to_fft * fft_to_dac * dac_to_out;

    return Solution.Result.number(bad_routes);
}

fn k(str: []const u8) u64 {
    var acc: u64 = 0;
    acc += @as(u64, str[0]) << 16;
    acc += @as(u64, str[1]) << 8;
    acc += @as(u64, str[2]);
    return acc;
}

fn countRoutesRec(memo: *std.AutoHashMap(u64, u64), map: *std.AutoHashMap(u64, []const u8), node: u64, end: u64) !u64 {
    if (node == end) return 1;
    if (memo.get(node)) |m| return m;
    const outputs = map.get(node) orelse return 0;
    var sum: u64 = 0;
    var i: usize = 0;
    while (i <= outputs.len) {
        const out = k(outputs[i .. i + 3]);
        sum += try countRoutesRec(memo, map, out, end);
        i += 4;
    }
    try memo.put(node, sum);
    return sum;
}

test "part_1.sample_1" {
    var result = try part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(5, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_2" {
    var result = try part_two(std.testing.allocator, sample_2);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(2, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\aaa: you hhh
    \\you: bbb ccc
    \\bbb: ddd eee
    \\ccc: ddd eee fff
    \\ddd: ggg
    \\eee: out
    \\fff: out
    \\ggg: out
    \\hhh: ccc fff iii
    \\iii: out
;

const sample_2: []const u8 =
    \\svr: aaa bbb
    \\aaa: fft
    \\fft: ccc
    \\bbb: tty
    \\tty: ccc
    \\ccc: ddd eee
    \\ddd: hub
    \\hub: fff
    \\eee: dac
    \\dac: fff
    \\fff: ggg hhh
    \\ggg: out
    \\hhh: out
;
