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

    const scalars = map.scalars(allocator);
    defer allocator.free(scalars);

    var antinodes_one = std.AutoHashMap(grid.Vec2, void).init(allocator);
    defer antinodes_one.deinit();
    var antinodes_two = std.AutoHashMap(grid.Vec2, void).init(allocator);
    defer antinodes_two.deinit();

    for (scalars) |c| {
        if (c == '.') continue;
        const locations = map.locationsOf(allocator, &.{c});
        defer allocator.free(locations);
        var a_index: usize = 0;
        while (a_index < locations.len - 1) : (a_index += 1) {
            var b_index: usize = a_index + 1;
            while (b_index < locations.len) : (b_index += 1) {
                const a = locations[a_index];
                const b = locations[b_index];

                antinodes_two.put(a, {}) catch unreachable;
                antinodes_two.put(b, {}) catch unreachable;

                const ab = b.translate(a.inverse());
                var antinode_ab = b.translate(ab);
                if (map.isInBounds(antinode_ab)) antinodes_one.put(antinode_ab, {}) catch unreachable;
                while (map.isInBounds(antinode_ab)) : (antinode_ab = antinode_ab.translate(ab)) {
                    antinodes_two.put(antinode_ab, {}) catch unreachable;
                }

                const ba = a.translate(b.inverse());
                var antinode_ba = a.translate(ba);
                if (map.isInBounds(antinode_ba)) antinodes_one.put(antinode_ba, {}) catch unreachable;
                while (map.isInBounds(antinode_ba)) : (antinode_ba = antinode_ba.translate(ba)) {
                    antinodes_two.put(antinode_ba, {}) catch unreachable;
                }
            }
        }
    }

    return .{ antinodes_one.count(), antinodes_two.count() };
}

const sample_1: []const u8 =
    \\............
    \\........0...
    \\.....0......
    \\.......0....
    \\....0.......
    \\......A.....
    \\............
    \\............
    \\........A...
    \\.........A..
    \\............
    \\............
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(14, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(34, solution[1]);
}
