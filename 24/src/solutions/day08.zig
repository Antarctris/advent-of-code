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
    return "Day 8: Resonant Collinearity";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var map = grid.ByteGrid.parse(allocator, input);
    defer map.deinit();

    const scalars = map.scalars(allocator);
    defer allocator.free(scalars);

    var antinodes_one = std.AutoHashMap(grid.Vec2, void).init(allocator);
    defer antinodes_one.deinit();

    for (scalars) |c| {
        if (c == '.') continue;
        const locations = map.locationsOf(allocator, &.{c});
        defer allocator.free(locations);
        var a_index: usize = 0;
        while (a_index < locations.len - 1) : (a_index += 1) {
            var b_index: usize = a_index + 1;
            while (b_index < locations.len) : (b_index += 1) {
                const a = locations[a_index];
                const b = locations[b_index];

                const ab = b.translate(a.inverse());
                const antinode_ab = b.translate(ab);
                if (map.isInBounds(antinode_ab)) antinodes_one.put(antinode_ab, {}) catch unreachable;

                const ba = a.translate(b.inverse());
                const antinode_ba = a.translate(ba);
                if (map.isInBounds(antinode_ba)) antinodes_one.put(antinode_ba, {}) catch unreachable;
            }
        }
    }

    return antinodes_one.count();
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var map = grid.ByteGrid.parse(allocator, input);
    defer map.deinit();

    const scalars = map.scalars(allocator);
    defer allocator.free(scalars);

    var antinodes_two = std.AutoHashMap(grid.Vec2, void).init(allocator);
    defer antinodes_two.deinit();

    for (scalars) |c| {
        if (c == '.') continue;
        const locations = map.locationsOf(allocator, &.{c});
        defer allocator.free(locations);
        var a_index: usize = 0;
        while (a_index < locations.len - 1) : (a_index += 1) {
            var b_index: usize = a_index + 1;
            while (b_index < locations.len) : (b_index += 1) {
                const a = locations[a_index];
                const b = locations[b_index];

                antinodes_two.put(a, {}) catch unreachable;
                antinodes_two.put(b, {}) catch unreachable;

                const ab = b.translate(a.inverse());
                var antinode_ab = b.translate(ab);
                while (map.isInBounds(antinode_ab)) : (antinode_ab = antinode_ab.translate(ab)) {
                    antinodes_two.put(antinode_ab, {}) catch unreachable;
                }

                const ba = a.translate(b.inverse());
                var antinode_ba = a.translate(ba);
                while (map.isInBounds(antinode_ba)) : (antinode_ba = antinode_ba.translate(ba)) {
                    antinodes_two.put(antinode_ba, {}) catch unreachable;
                }
            }
        }
    }

    return antinodes_two.count();
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(14, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(34, result);
}

const sample_1: []const u8 =
    \\............
    \\........0...
    \\.....0......
    \\.......0....
    \\....0.......
    \\......A.....
    \\............
    \\............
    \\........A...
    \\.........A..
    \\............
    \\............
    \\
;
