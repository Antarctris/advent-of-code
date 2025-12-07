const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

const util = @import("util");
const grid = util.grid;
const Solution = @import("./solution.zig");

// interface
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day 7: Laboratories";
}

pub fn part_one(allocator: Allocator, input: []const u8) !Solution.Result {
    var tachyon_manifold_diagram = grid.ByteGrid.parse(allocator, input);
    defer tachyon_manifold_diagram.deinit();

    var tachyon_splits: u64 = 0;

    for (tachyon_manifold_diagram.width..tachyon_manifold_diagram.bytes.len) |i| {
        const a: usize = i - tachyon_manifold_diagram.width;
        if (tachyon_manifold_diagram.bytes[a] == '|' or tachyon_manifold_diagram.bytes[a] == 'S') {
            if (tachyon_manifold_diagram.bytes[i] == '.') {
                tachyon_manifold_diagram.bytes[i] = '|';
            }
            if (tachyon_manifold_diagram.bytes[i] == '^') {
                if (@mod(i, tachyon_manifold_diagram.width) != 0) {
                    if (tachyon_manifold_diagram.bytes[i - 1] == '.') {
                        tachyon_manifold_diagram.bytes[i - 1] = '|';
                    }
                }
                if (@mod(i + 1, tachyon_manifold_diagram.width) != 0) {
                    if (tachyon_manifold_diagram.bytes[i + 1] == '.') {
                        tachyon_manifold_diagram.bytes[i + 1] = '|';
                    }
                }
                tachyon_splits += 1;
            }
        }
    }

    return Solution.Result.number(tachyon_splits);
}

pub fn part_two(allocator: Allocator, input: []const u8) !Solution.Result {
    var tachyon_manifold_diagram = grid.ByteGrid.parse(allocator, input);
    defer tachyon_manifold_diagram.deinit();

    var timeline_memo = std.AutoHashMap(usize, u64).init(allocator);
    defer timeline_memo.deinit();

    const timeline_start = std.mem.indexOfScalar(u8, tachyon_manifold_diagram.bytes, 'S').? + tachyon_manifold_diagram.width;
    const timeline_count = try discoverTimelines(&timeline_memo, tachyon_manifold_diagram.bytes, tachyon_manifold_diagram.width, timeline_start);

    return Solution.Result.number(timeline_count);
}

pub fn discoverTimelines(timeline_memo: *std.AutoHashMap(usize, u64), tachyon_manifold_diagram: []const u8, diagram_width: usize, timeline_index: usize) !u64 {
    if (timeline_memo.get(timeline_index)) |memo| {
        return memo;
    }
    var current_timeline = timeline_index;
    while (tachyon_manifold_diagram[current_timeline] == '.') {
        if (current_timeline + diagram_width >= tachyon_manifold_diagram.len) return 1;
        current_timeline += diagram_width;
    }
    if (tachyon_manifold_diagram[current_timeline] == '^') {
        var l: u64 = 0;
        if (@mod(current_timeline, diagram_width) != 0 and tachyon_manifold_diagram[current_timeline - 1] == '.') {
            l = try discoverTimelines(timeline_memo, tachyon_manifold_diagram, diagram_width, current_timeline - 1);
        }
        var r: u64 = 0;
        if (@mod(current_timeline + 1, diagram_width) != 0 and tachyon_manifold_diagram[current_timeline + 1] == '.') {
            r = try discoverTimelines(timeline_memo, tachyon_manifold_diagram, diagram_width, current_timeline + 1);
        }
        const timelines = l + r;
        try timeline_memo.put(timeline_index, timelines);
        return timelines;
    }
    return error.RecursionFailed;
}

test "part_1.sample_1" {
    var result = try part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(21, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = try part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(40, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\.......S.......
    \\...............
    \\.......^.......
    \\...............
    \\......^.^......
    \\...............
    \\.....^.^.^.....
    \\...............
    \\....^.^...^....
    \\...............
    \\...^.^...^.^...
    \\...............
    \\..^...^.....^..
    \\...............
    \\.^.^.^.^.^...^.
    \\...............
;
