const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const util = @import("util");

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

const directions = util.grid.CardinalDirections;

pub fn solveChallenge(allocator: Allocator, input: []const u8) [2]u64 {
    var map = util.grid.CharGrid.init(allocator, input);
    defer map.deinit();

    var history = std.AutoHashMap(util.grid.Point, [4]bool).init(allocator);
    defer history.deinit();

    var obstructions: u64 = 0;

    var current = map.pointOf("^").?;
    var direction_index: usize = 0;
    var next = current.translate(directions[0]);
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
        next = current.translate(directions[direction_index]);
    }
    addDirection(&history, current, direction_index);

    return .{ history.count(), obstructions };
}

fn checkLoop(
    allocator: Allocator,
    map: util.grid.CharGrid,
    origin_history: std.AutoHashMap(util.grid.Point, [4]bool),
    point: util.grid.Point,
    direction_idx: usize,
) bool {
    var recent_history = std.AutoHashMap(util.grid.Point, [4]bool).init(allocator);
    defer recent_history.deinit();

    var current = point;
    var direction_index = direction_idx;
    var next = current.translate(directions[direction_index]);
    while (map.isInBounds(next)) {
        if ((origin_history.contains(current) and origin_history.get(current).?[direction_index]) or
            (recent_history.contains(current) and recent_history.get(current).?[direction_index])) return true;
        addDirection(&recent_history, current, direction_index);
        if (map.get(next) == '#') {
            direction_index = @mod(direction_index + 1, 4);
        } else {
            current = next;
        }
        next = current.translate(directions[direction_index]);
    }
    return false;
}

fn addDirection(
    history: *std.AutoHashMap(util.grid.Point, [4]bool),
    current: util.grid.Point,
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
// 3, 6
// 6, 7
// 7, 7
// 1, 8
// 3, 8
// 7, 9

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(41, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(6, solution[1]);
}
