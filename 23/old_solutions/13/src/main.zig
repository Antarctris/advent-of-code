const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const grid = @import("util").grid;
const umem = @import("util").mem;

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
    var map_iterator = mem.split(u8, input, "\n\n");
    var solution_one: u64 = 0;
    var solution_two: u64 = 0;
    while (map_iterator.next()) |map_str| {
        if (map_str.len == 0) continue;
        const row_major = grid.ByteGrid.parse(allocator, map_str);
        defer row_major.deinit();
        const col_major = row_major.columnsToRows();
        defer col_major.deinit();

        if (indexOfRowMirror(row_major, 0)) |i| {
            solution_one += 100 * i;
        } else if (indexOfRowMirror(col_major, 0)) |i| {
            solution_one += i;
        }

        if (indexOfRowMirror(row_major, 1)) |i| {
            solution_two += 100 * i;
        } else if (indexOfRowMirror(col_major, 1)) |i| {
            solution_two += i;
        } else {
            print("\n{s}\n", .{map_str});
        }
    }

    return .{ solution_one, solution_two };
}

pub fn indexOfRowMirror(map: grid.ByteGrid, tolerance: usize) ?usize {
    var optional_mirror: ?usize = null;
    var deviations: usize = 0;
    var row_index: usize = 1;
    while (row_index <= map.height) : (row_index += 1) {
        if (optional_mirror) |gm| {
            const lm = gm - 1;
            if (lm + gm < row_index or row_index == map.height) {
                if (deviations == tolerance) return optional_mirror; // FINISHED
            } else if (umem.eqlTolerance(u8, map.row(lm + gm - row_index), map.row(row_index), tolerance)) |f| {
                deviations += f;
                if (deviations <= tolerance) {
                    continue;
                }
            }

            // Only get here if not equal or tolerance exceeded
            row_index = gm;
            optional_mirror = null;
            deviations = 0;
        } else if (row_index < map.height) {
            if (umem.eqlTolerance(u8, map.row(row_index - 1), map.row(row_index), tolerance)) |f| {
                deviations = f;
                optional_mirror = row_index;
            }
        }
    }
    return if (deviations == tolerance) optional_mirror else null;
}

const sample_1: []const u8 =
    \\#.##..##.
    \\..#.##.#.
    \\##......#
    \\##......#
    \\..#.##.#.
    \\..##..##.
    \\#.#.##.#.
    \\
    \\#...##..#
    \\#....#..#
    \\..##..###
    \\#####.##.
    \\#####.##.
    \\..##..###
    \\#....#..#
    \\
;

const sample_2: []const u8 =
    \\##.####
    \\..#....
    \\###....
    \\#.#....
    \\#.#....
    \\..#....
    \\###.##.
    \\#..####
    \\#.#####
    \\###....
    \\#..####
    \\.######
    \\##.####
    \\.#.....
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(405, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(400, solution[1]);
}

test "part_2.sample_2" {
    const solution = solveChallenge(std.testing.allocator, sample_2);
    try std.testing.expectEqual(6, solution[1]);
}
