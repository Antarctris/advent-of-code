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
    return "Day 10: Hoof It";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var hiking_map = grid.ByteGrid.parse(allocator, input);
    defer hiking_map.deinit();

    const starting_positions = hiking_map.locationsOfScalar(allocator, '0');
    defer allocator.free(starting_positions);

    var total_trailhead_peaks_scores: u64 = 0;

    for (starting_positions) |pos| {
        var peaks = std.AutoHashMap(grid.Vec2, void).init(allocator);
        defer peaks.deinit();
        _ = followTrails(hiking_map, &peaks, pos);
        total_trailhead_peaks_scores += peaks.count();
    }

    return total_trailhead_peaks_scores;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var hiking_map = grid.ByteGrid.parse(allocator, input);
    defer hiking_map.deinit();

    const starting_positions = hiking_map.locationsOfScalar(allocator, '0');
    defer allocator.free(starting_positions);

    var total_trailhead_trail_scores: u64 = 0;

    for (starting_positions) |pos| {
        var peaks = std.AutoHashMap(grid.Vec2, void).init(allocator);
        defer peaks.deinit();
        total_trailhead_trail_scores += followTrails(hiking_map, &peaks, pos);
    }

    return total_trailhead_trail_scores;
}

fn followTrails(map: grid.ByteGrid, peaks: *std.AutoHashMap(grid.Vec2, void), position: grid.Vec2) u64 {
    if (map.get(position).? == '9') {
        peaks.put(position, {}) catch unreachable;
        return 1;
    }
    var score: u64 = 0;
    for (grid.CardinalDirections) |d| {
        const next = position.translate(d);
        if (map.isInBounds(next)) {
            if (map.get(next).? == map.get(position).? + 1) {
                score += followTrails(map, peaks, next);
            }
        }
    }
    return score;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(36, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(81, result);
}

const sample_1: []const u8 =
    \\89010123
    \\78121874
    \\87430965
    \\96549874
    \\45678903
    \\32019012
    \\01329801
    \\10456732
    \\
;
