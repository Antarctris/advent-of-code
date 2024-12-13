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
    return "Day 6: Guard Gallivant";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var map = grid.ByteGrid.parse(allocator, input);
    defer map.deinit();

    var history = std.AutoHashMap(grid.Vec2, [4]bool).init(allocator);
    defer history.deinit();

    var current = map.locationOfScalar('^').?;
    var direction_index: usize = 0;
    var next = current.translate(grid.CardinalDirections[0]);
    while (map.isInBounds(next)) {
        addDirection(&history, current, direction_index);
        if (map.get(next) == '#') {
            direction_index = @mod(direction_index + 1, 4);
        } else {
            current = next;
        }
        next = current.translate(grid.CardinalDirections[direction_index]);
    }
    addDirection(&history, current, direction_index);

    return history.count();
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var map = grid.ByteGrid.parse(allocator, input);
    defer map.deinit();

    var history = std.AutoHashMap(grid.Vec2, [4]bool).init(allocator);
    defer history.deinit();

    var obstructions: u64 = 0;

    var current = map.locationOfScalar('^').?;
    var direction_index: usize = 0;
    var next = current.translate(grid.CardinalDirections[0]);
    while (map.isInBounds(next)) {
        addDirection(&history, current, direction_index);
        if (map.get(next) != '#' and map.get(next) != 'O') {
            map.set(next, '#');
            obstructions += @intFromBool(checkLoop(allocator, map, history, current, @mod(direction_index + 1, 4)));
            map.set(next, 'O'); // Set regardless of loop or not, since we shall not test it again!
        }
        if (map.get(next) == '#') {
            direction_index = @mod(direction_index + 1, 4);
        } else {
            current = next;
        }
        next = current.translate(grid.CardinalDirections[direction_index]);
    }
    addDirection(&history, current, direction_index);

    return obstructions;
}

fn checkLoop(
    allocator: Allocator,
    map: grid.ByteGrid,
    origin_history: std.AutoHashMap(grid.Vec2, [4]bool),
    point: grid.Vec2,
    direction_idx: usize,
) bool {
    var recent_history = std.AutoHashMap(grid.Vec2, [4]bool).init(allocator);
    defer recent_history.deinit();

    var current = point;
    var direction_index = direction_idx;
    var next = current.translate(grid.CardinalDirections[direction_index]);
    while (map.isInBounds(next)) {
        if ((origin_history.contains(current) and origin_history.get(current).?[direction_index]) or
            (recent_history.contains(current) and recent_history.get(current).?[direction_index])) return true;
        addDirection(&recent_history, current, direction_index);
        if (map.get(next) == '#') {
            direction_index = @mod(direction_index + 1, 4);
        } else {
            current = next;
        }
        next = current.translate(grid.CardinalDirections[direction_index]);
    }
    return false;
}

fn addDirection(
    history: *std.AutoHashMap(grid.Vec2, [4]bool),
    current: grid.Vec2,
    direction_index: usize,
) void {
    const entry = history.get(current) orelse .{ false, false, false, false };
    history.put(current, .{
        direction_index == 0 or entry[0],
        direction_index == 1 or entry[1],
        direction_index == 2 or entry[2],
        direction_index == 3 or entry[3],
    }) catch unreachable;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(41, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(6, result);
}

const sample_1: []const u8 =
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
    \\
;
