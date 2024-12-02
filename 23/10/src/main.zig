const std = @import("std");
const mem = std.mem;

const grid = @import("util").grid;

const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

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
    try stdout.print("\nInitialize allocator and input...", .{});

    // Initialze allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Read input
    const path: []const u8 = mem.span(std.os.argv[1]);
    const input = try readInputFile(allocator, path);

    try stdout.print(" ...done.\nStarting challenge subroutine.\n", .{});

    // Run challenge subroutine
    const solution = solveChallenge(allocator, input);

    // Print solution
    try stdout.print("Solution\nPart 1: {d}\nPart 2: {d}", .{ solution[0], solution[1] });
}

pub fn solveChallenge(allocator: Allocator, input: []const u8) [2]u64 {
    // Init map
    var map = grid.CharGrid.init(allocator, input);
    defer map.deinit();

    // Find start, assuming start is always a corner
    var corner = map.pointOf("S").?;
    var direction: grid.Point = switch (map.get(corner.translate(grid.N)) orelse 0) {
        '|', 'F', '7' => grid.N,
        else => grid.S,
    };
    var current = corner.translate(direction);
    var steps: u64 = 1;
    var area: i64 = 0;
    loop: while (true) {
        while (mem.indexOfScalar(u8, "-|", map.get(current).?)) |_| {
            current = current.translate(direction);
            steps += 1;
            continue;
        }

        direction = switch (map.get(current).?) {
            '7' => if (direction.equals(grid.N)) grid.W else grid.S,
            'J' => if (direction.equals(grid.S)) grid.W else grid.N,
            'L' => if (direction.equals(grid.S)) grid.E else grid.N,
            'F' => if (direction.equals(grid.N)) grid.E else grid.S,
            else => {
                area += corner.determinant(current);
                break :loop;
            },
        };

        area += corner.determinant(current);
        corner = current;
        current = current.translate(direction);
        steps += 1;
    }
    area = @divFloor(area, 2); // https://en.wikipedia.org/wiki/Shoelace_formula#Other_formulas_2

    const solution_a = steps / 2;
    const solution_b = @abs(area) - steps / 2 + 1; // https://en.wikipedia.org/wiki/Pick%27s_theorem

    return .{ solution_a, solution_b };
}

const sample_1: []const u8 =
    \\..F7.
    \\.FJ|.
    \\SJ.L7
    \\|F--J
    \\LJ...
    \\
;

const sample_2: []const u8 =
    \\FF7FSF7F7F7F7F7F---7
    \\L|LJ||||||||||||F--J
    \\FL-7LJLJ||||||LJL-77
    \\F--JF--7||LJLJ7F7FJ-
    \\L---JF-JLJ.||-FJLJJ7
    \\|F|F-JF---7F7-L7L|7|
    \\|FFJF7L7F-JF7|JL---7
    \\7-L-JL7||F7|L7F-7F7|
    \\L.L7LFJ|||||FJL7||LJ
    \\L7JLJL-JLJLJL--JLJ.L
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(8, solution[0]);
}

test "part_2.sample_2" {
    const solution = solveChallenge(std.testing.allocator, sample_2);
    try std.testing.expectEqual(10, solution[1]);
}
