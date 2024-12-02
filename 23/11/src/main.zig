const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const grid = @import("util").grid;

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
    const solution: [2]u64 = solveChallenge(allocator, input, 2, 1000000);

    // Print solution
    try stdout.print("Solution:\nPart 1: {d}\nPart 2: {d}\n", .{ solution[0], solution[1] });
}

pub fn solveChallenge(allocator: Allocator, input: []const u8, factor_a: u64, factor_b: u64) [2]u64 {
    var map = grid.CharGrid.init(allocator, input);
    defer map.deinit();

    var empty_cols = std.AutoArrayHashMap(u64, void).init(allocator);
    defer empty_cols.deinit();
    for (0..map.width) |i| {
        empty_cols.put(@intCast(i), {}) catch unreachable;
    }
    var empty_rows: u64 = 0;

    var galaxies_one = std.ArrayList(grid.Point).init(allocator);
    defer galaxies_one.deinit();

    var galaxies_two = std.ArrayList(grid.Point).init(allocator);
    defer galaxies_two.deinit();

    // Read galaxies and expand space
    for (0..map.height) |y| {
        var empty: bool = true;
        for (0..map.width) |x| {
            var p = grid.Point{ .x = @intCast(x), .y = @intCast(y) };
            if (map.get(p).? == '#') {
                _ = empty_cols.fetchOrderedRemove(@intCast(x));
                empty = false;
                galaxies_one.append(p.translate(grid.Point{ .x = 0, .y = @intCast(empty_rows * (factor_a - 1)) })) catch unreachable;
                galaxies_two.append(p.translate(grid.Point{ .x = 0, .y = @intCast(empty_rows * (factor_b - 1)) })) catch unreachable;
            }
        }
        if (empty) {
            empty_rows += 1;
        }
    }
    var last: i64 = std.math.maxInt(i64);
    while (empty_cols.popOrNull()) |col| {
        for (0..galaxies_one.items.len) |i| {
            if (galaxies_one.items[i].x > col.key and galaxies_one.items[i].x < last) {
                galaxies_one.items[i] = galaxies_one.items[i].translate(grid.Point{ .x = @intCast((empty_cols.keys().len + 1) * (factor_a - 1)), .y = 0 });
                galaxies_two.items[i] = galaxies_two.items[i].translate(grid.Point{ .x = @intCast((empty_cols.keys().len + 1) * (factor_b - 1)), .y = 0 });
            }
        }
        last = @intCast(col.key);
    }

    // Sum manhattan distances between all galaxies
    var galaxies_one_sum: u64 = 0;
    var galaxies_two_sum: u64 = 0;
    for (0..galaxies_one.items.len) |ai| {
        for (ai + 1..galaxies_one.items.len) |bi| {
            galaxies_one_sum += galaxies_one.items[ai].manhattanDistance(galaxies_one.items[bi]);
            galaxies_two_sum += galaxies_two.items[ai].manhattanDistance(galaxies_two.items[bi]);
        }
    }

    return .{ galaxies_one_sum, galaxies_two_sum };
}

const example_input: []const u8 =
    \\...#......
    \\.......#..
    \\#.........
    \\..........
    \\......#...
    \\.#........
    \\.........#
    \\..........
    \\.......#..
    \\#...#.....
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, example_input, 2, 1000000);
    try std.testing.expectEqual(374, solution[0]);
}

test "part_2.sample_1.10" {
    const solution = solveChallenge(std.testing.allocator, example_input, 1, 10);
    try std.testing.expectEqual(1030, solution[1]);
}

test "part_2.sample_1.100" {
    const solution = solveChallenge(std.testing.allocator, example_input, 1, 100);
    try std.testing.expectEqual(8410, solution[1]);
}
