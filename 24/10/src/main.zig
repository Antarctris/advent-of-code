const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const util = @import("util");
const grid = util.grid;

fn readInputFile(allocator: Allocator, path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const file_size = (try file.metadata()).size();
    const input = try allocator.alloc(u8, file_size);
    _ = try file.readAll(input);
    return input;
}

pub fn main() !void {
    assert(std.os.argv.len == 2);

    // Set up output
    const stdout = std.io.getStdOut().writer();

    // Initialze allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Read input
    const path: []const u8 = mem.span(std.os.argv[1]);
    const input = try readInputFile(allocator, path);

    // Run challenge subroutine
    const solution: [2]u64 = solveChallenge(allocator, input);

    // Print solution
    try stdout.print("Solution:\nPart 1: {d}\nPart 2: {d}\n", .{ solution[0], solution[1] });
}

pub fn solveChallenge(allocator: Allocator, input: []const u8) [2]u64 {
    var hiking_map = grid.ByteGrid.parse(allocator, input);
    defer hiking_map.deinit();

    const starting_positions = hiking_map.locationsOfScalar(allocator, '0');
    defer allocator.free(starting_positions);

    var total_trailhead_peaks_scores: u64 = 0;
    var total_trailhead_trail_scores: u64 = 0;

    for (starting_positions) |pos| {
        var peaks = std.AutoHashMap(grid.Vec2, void).init(allocator);
        defer peaks.deinit();
        total_trailhead_trail_scores += followTrails(hiking_map, &peaks, pos);
        total_trailhead_peaks_scores += peaks.count();
    }

    return .{ total_trailhead_peaks_scores, total_trailhead_trail_scores };
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

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(36, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(81, solution[1]);
}
