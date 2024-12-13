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
    return "Day 4: Ceres Search";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var map = util.grid.ByteGrid.parse(allocator, input);
    defer map.deinit();
    return countDirections(map, "XMAS", &util.grid.OctagonalDirections);
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var map = util.grid.ByteGrid.parse(allocator, input);
    defer map.deinit();
    return findXMAS(map);
}

fn findXMAS(map: util.grid.ByteGrid) u64 {
    var count: u64 = 0;
    for (1..map.height - 1) |y| {
        var p = util.grid.Vec2{ .x = 1, .y = @intCast(y) };
        while (p.x < map.width - 1) : (p = p.translate(util.grid.E)) {
            if (map.get(p) == 'A') {
                for (0..4) |i| {
                    const directions = util.grid.OrdinalDirections;
                    if (map.get(p.translate(directions[i])) == 'M' and
                        map.get(p.translate(directions[i].inverse())) == 'S' and
                        map.get(p.translate(directions[@mod(i + 1, 4)])) == 'M' and
                        map.get(p.translate(directions[@mod(i + 1, 4)].inverse())) == 'S')
                    {
                        //std.debug.print("{any} : {d}\n", .{ p, i });
                        count += 1;
                        break;
                    }
                }
            }
        }
    }
    return count;
}

fn countDirections(map: grid.ByteGrid, needle: []const u8, directions: []const grid.Vec2) u64 {
    var sum: u64 = 0;
    for (0..map.height) |y| {
        var index = grid.Vec2{ .x = 0, .y = @intCast(y) };
        while (index.x < map.width) : (index = index.translate(grid.E)) {
            sum += countDirectionsAt(map, index, needle, directions);
        }
    }
    return sum;
}

fn countDirectionsAt(map: grid.ByteGrid, point: grid.Vec2, needle: []const u8, directions: []const grid.Vec2) u64 {
    var sum: u64 = 0;
    for (directions) |direction| {
        if (map.isInBounds(point.translate(direction.times(@intCast(needle.len - 1))))) {
            var p = point;
            var i: usize = 0;
            while (i < needle.len and map.get(p) == needle[i]) {
                i += 1;
                p = p.translate(direction);
            }
            sum += @intFromBool(i == needle.len);
        }
    }
    return sum;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(18, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(9, result);
}

const sample_1: []const u8 =
    \\MMMSXXMASM
    \\MSAMXMSMSA
    \\AMXSXMAAMM
    \\MSAMASMSMX
    \\XMASAMXAMM
    \\XXAMMXXAMA
    \\SMSMSASXSS
    \\SAXAMASAAA
    \\MAMMMXMMMM
    \\MXMXAXMASX
    \\
;
