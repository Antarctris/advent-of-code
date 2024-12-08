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
    var map0 = grid.ByteGrid.parse(allocator, input);
    defer map0.deinit();
    tiltMap(map0, util.grid.N);
    const sum_one = getNorthWeight(map0);

    var map1 = grid.ByteGrid.parse(allocator, input);
    defer map1.deinit();
    var history = std.AutoHashMap(u64, u64).init(allocator);
    defer history.deinit();
    var steps: u64 = 0;
    while (!history.contains(map1.hash())) : (steps += 1) {
        history.put(map1.hash(), steps) catch unreachable;
        tiltCircle(map1);
    }
    const cycle_start = history.get(map1.hash()).?;
    const cycle_len = steps - cycle_start;
    const end = @mod(1000000000 - cycle_start, cycle_len);
    for (0..end) |_| {
        tiltCircle(map1);
    }
    const sum_two = getNorthWeight(map1);

    return .{ sum_one, sum_two };
}

fn tiltMap(map: grid.ByteGrid, tilt: grid.Vec2) void {
    // Calculate major direction and start position from tilt
    const major = tilt.perpendicular().abs();
    var current_major = tilt.times(tilt.abs().dot(grid.Vec2{ .x = @intCast(map.width), .y = @intCast(map.height) }) - 1).max(grid.Vec2{ .x = 0, .y = 0 });

    while (map.isInBounds(current_major)) : (current_major = current_major.translate(major)) {
        var last_swap = current_major;
        var current_tilt = current_major;
        while (map.isInBounds(current_tilt)) : (current_tilt = current_tilt.translate(tilt.inverse())) {
            if (map.get(current_tilt) == 'O') {
                map.swapValues(current_tilt, last_swap);
                last_swap = last_swap.translate(tilt.inverse());
            }
            if (map.get(current_tilt) == '#') {
                last_swap = current_tilt.translate(tilt.inverse());
            }
        }
    }
}

fn tiltCircle(map: grid.ByteGrid) void {
    for (0..4) |i| {
        tiltMap(map, grid.CardinalDirections[@mod(4 - i, 4)]);
    }
}

fn getNorthWeight(map: grid.ByteGrid) u64 {
    var count: u64 = 0;
    for (0..map.height) |ri| {
        count += mem.count(u8, map.row(ri), "O") * (map.height - ri);
    }
    return count;
}

const sample_1: []const u8 =
    \\O....#....
    \\O.OO#....#
    \\.....##...
    \\OO.#O....O
    \\.O.....O#.
    \\O.#..O.#.#
    \\..O..#O..O
    \\.......O..
    \\#....###..
    \\#OO..#....
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(136, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(64, solution[1]);
}
