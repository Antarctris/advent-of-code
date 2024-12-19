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
    var map = grid.ByteGrid.parse(allocator, input);
    defer map.deinit();

    var energized = std.AutoHashMap(grid.Vec2, [4]bool).init(allocator);
    defer energized.deinit();

    cast_ray(map, &energized, grid.Vec2.Zero, 1);

    const default_energy = energized.count();
    var max_energy = default_energy;

    for (0..map.height) |row| {
        energized.clearRetainingCapacity();
        cast_ray(map, &energized, grid.Vec2{ .x = 0, .y = @intCast(row) }, 1);
        max_energy = @max(max_energy, energized.count());

        energized.clearRetainingCapacity();
        cast_ray(map, &energized, grid.Vec2{ .x = @intCast(map.width - 1), .y = @intCast(row) }, 3);
        max_energy = @max(max_energy, energized.count());
    }

    for (0..map.width) |col| {
        energized.clearRetainingCapacity();
        cast_ray(map, &energized, grid.Vec2{ .x = @intCast(col), .y = 0 }, 2);
        max_energy = @max(max_energy, energized.count());

        energized.clearRetainingCapacity();
        cast_ray(map, &energized, grid.Vec2{ .x = @intCast(col), .y = @intCast(map.height - 1) }, 0);
        max_energy = @max(max_energy, energized.count());
    }

    return .{ default_energy, max_energy };
}

fn cast_ray(map: grid.ByteGrid, energized: *std.AutoHashMap(grid.Vec2, [4]bool), start: grid.Vec2, initial_direction: u2) void {
    var position = start;
    var direction_index: u2 = initial_direction;
    while (map.isInBounds(position)) : (position = position.translate(grid.CardinalDirections[direction_index])) {
        const directions = energized.get(position) orelse .{ false, false, false, false };
        if (directions[direction_index]) break;
        energized.put(position, .{
            direction_index == 0 or directions[0],
            direction_index == 1 or directions[1],
            direction_index == 2 or directions[2],
            direction_index == 3 or directions[3],
        }) catch unreachable;

        if (map.get(position).? == '.') continue;
        if (map.get(position).? == '/') direction_index +%= if (@mod(direction_index, 2) == 0) 1 else 3;
        if (map.get(position).? == '\\') direction_index +%= if (@mod(direction_index, 2) == 1) 1 else 3;

        if ((map.get(position).? == '-' and @mod(direction_index, 2) == 0) or
            (map.get(position).? == '|' and @mod(direction_index, 2) == 1))
        {
            cast_ray(map, energized, position, direction_index +% 1);
            cast_ray(map, energized, position, direction_index +% 3);
            break;
        }
    }
}

const sample_1: []const u8 =
    \\.|...\....
    \\|.-.\.....
    \\.....|-...
    \\........|.
    \\..........
    \\.........\
    \\..../.\\..
    \\.-.-/..|..
    \\.|....-|.\
    \\..//.|....
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(46, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(51, solution[1]);
}
