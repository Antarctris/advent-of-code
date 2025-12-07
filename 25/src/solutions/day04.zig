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
    return "Day 4: Printing Department";
}

pub fn part_one(allocator: Allocator, input: []const u8) !Solution.Result {
    var paperrolls = try grid.ByteGrid.parse(allocator, input);
    defer paperrolls.deinit();

    var accessible_rolls: u64 = 0;

    for (0..paperrolls.height) |y| {
        for (0..paperrolls.width) |x| {
            const pos = grid.Vec2{ .x = @intCast(x), .y = @intCast(y) };
            if (paperrolls.get(pos) != '@') continue;
            var neighbor_rolls: u64 = 0;
            for (grid.OctagonalDirections) |d| {
                const n = pos.translate(d);
                if (paperrolls.isInBounds(n) and paperrolls.get(n) == '@') {
                    neighbor_rolls += 1;
                }
            }
            if (neighbor_rolls < 4) {
                accessible_rolls += 1;
            }
        }
    }

    return Solution.Result.number(accessible_rolls);
}

pub fn part_two(allocator: Allocator, input: []const u8) !Solution.Result {
    var paperrolls = try grid.ByteGrid.parse(allocator, input);
    defer paperrolls.deinit();

    var removed_rolls: u64 = 0;

    var last: u64 = 1;
    while (removed_rolls != last) {
        last = removed_rolls;
        for (0..paperrolls.height) |y| {
            for (0..paperrolls.width) |x| {
                const pos = grid.Vec2{ .x = @intCast(x), .y = @intCast(y) };
                if (paperrolls.get(pos) != '@') continue;
                var neighbor_rolls: u64 = 0;
                for (grid.OctagonalDirections) |d| {
                    const n = pos.translate(d);
                    if (paperrolls.isInBounds(n) and paperrolls.get(n) == '@') {
                        neighbor_rolls += 1;
                    }
                }
                if (neighbor_rolls < 4) {
                    paperrolls.set(pos, '.');
                    removed_rolls += 1;
                }
            }
        }
    }

    return Solution.Result.number(removed_rolls);
}

test "part_1.sample_1" {
    var result = try part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(13, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = try part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(43, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\..@@.@@@@.
    \\@@@.@.@.@@
    \\@@@@@.@.@@
    \\@.@@@@..@.
    \\@@.@@@@.@@
    \\.@@@@@@@.@
    \\.@.@.@.@@@
    \\@.@@@.@@@@
    \\.@@@@@@@@.
    \\@.@.@@@.@.
;
