const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

// For debug only stuff
const builtin = @import("builtin");
const dbg = builtin.mode == .Debug;

const util = @import("util");
const grid = util.grid;
const Solution = @import("./solution.zig");

// interface
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day 20: Race Condition";
}

const two_ps_cheats = blk: {
    var _array: [4]grid.Vec2 = undefined;
    var index = 0;
    for (grid.CardinalDirections) |d| {
        _array[index] = d.times(2);
        index += 1;
    }
    break :blk _array;
};

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var track = grid.ByteGrid.parse(allocator, input);
    defer track.deinit();
    const end = track.locationOfScalar('E');

    var memo = std.AutoHashMap(grid.Vec2, u64).init(allocator);
    defer memo.deinit();

    var good_cheats_found: u64 = 0;

    var current: ?grid.Vec2 = end;
    var cost: u64 = 0;
    while (current) |node| {
        memo.put(node, cost) catch unreachable;

        if (cost > 102) {
            for (two_ps_cheats) |d| {
                if (memo.get(node.translate(d))) |cheat_target_cost| {
                    if (cheat_target_cost <= cost - 102) good_cheats_found += 1;
                }
            }
        }

        if (track.get(node).? == 'S') {
            current = null;
        } else {
            for (grid.CardinalDirections) |d| {
                const next = node.translate(d);
                if (track.get(next).? != '#' and !memo.contains(next)) {
                    current = next;
                    break;
                }
            }
            cost += 1;
        }
    }

    return good_cheats_found;
}

const twenty_ps_cheats = blk: {
    @setEvalBranchQuota(2000); // Default of 1000 not enough here.
    // The lozenge without its center has 4 fans of vertices, where the count of elements
    // of each fan can be found as sum to n. Further 4 vertices are removed since
    // manhatten distance of 1 cannot actually be a cheat.
    const size = 4 * util.math.sumTo(usize, 21) - 4; // 4 * 210 - 4 = 836
    var _array: [size]grid.Vec2 = undefined;
    var index = 0;
    var y: i64 = -20;
    while (y < 21) : (y += 1) {
        var x: i64 = -20;
        while (x < 21) : (x += 1) {
            const dist = @abs(x) + @abs(y);
            if (dist > 1 and dist < 21) {
                _array[index] = grid.Vec2{ .x = x, .y = y };
                index += 1;
            }
        }
    }
    break :blk _array;
};

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var track = grid.ByteGrid.parse(allocator, input);
    defer track.deinit();
    const end = track.locationOfScalar('E');

    var memo = std.AutoHashMap(grid.Vec2, u64).init(allocator);
    defer memo.deinit();

    var good_cheats_found: u64 = 0;

    var current: ?grid.Vec2 = end;
    var cost: u64 = 0;
    while (current) |node| {
        // Go from end to start, and memorize each node with its steps to the end. When
        // checking for cheats, checking the memorized nodes is sufficient, as all other nodes
        // are invalid or lead to a point even further away from the end.
        memo.put(node, cost) catch unreachable;

        if (cost > 100 + 2) { // Plus 2 as it is the mininum required to perform a cheat
            for (twenty_ps_cheats) |d| {
                // Test every possibility to cheat on current node
                if (memo.get(node.translate(d))) |cheat_target_cost| {
                    if (cheat_target_cost + 100 + @abs(d.x) + @abs(d.y) <= cost) good_cheats_found += 1;
                }
            }
        }

        if (track.get(node).? == 'S') {
            current = null;
        } else {
            for (grid.CardinalDirections) |d| {
                const next = node.translate(d);
                if (track.get(next).? != '#' and !memo.contains(next)) {
                    current = next;
                    break;
                }
            }
            cost += 1;
        }
    }

    return good_cheats_found;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(0, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(0, result);
}

const sample_1: []const u8 =
    \\###############
    \\#...#...#.....#
    \\#.#.#.#.#.###.#
    \\#S#...#.#.#...#
    \\#######.#.#.###
    \\#######.#.#...#
    \\#######.#.###.#
    \\###..E#...#...#
    \\###.#######.###
    \\#...###...#...#
    \\#.#####.#.###.#
    \\#.#...#.#.#...#
    \\#.#.#.#.#.#.###
    \\#...#...#...###
    \\###############
    \\
;
