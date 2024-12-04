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

pub fn solveChallenge(allocator: Allocator, input: []const u8) [2]u64 {
    var map0 = util.grid.CharGrid.init(allocator, input);
    defer map0.deinit();
    const sum_one = map0.countDirections("XMAS", &util.grid.OctagonalDirections);
    const sum_two = findXMAS(map0);

    return .{ sum_one, sum_two };
}

fn findXMAS(map: util.grid.CharGrid) u64 {
    var count: u64 = 0;
    for (1..map.height - 1) |y| {
        var p = util.grid.Point{ .x = 1, .y = @intCast(y) };
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

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(18, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(9, solution[1]);
}
