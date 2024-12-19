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
    _ = allocator;
    const limit = CubeSet{ .red = 12, .green = 13, .blue = 14 };
    var sum_one: u32 = 0;
    var sum_two: u32 = 0;
    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const colon_index = mem.indexOfScalar(u8, line, ':') orelse unreachable;
        var draw_iterator = mem.splitSequence(u8, line[colon_index + 2 ..], "; "); // 2: colon and whitespace
        var draw_contained = true;
        var minimumGameCubeSet = CubeSet{ .red = 0, .green = 0, .blue = 0 };
        while (draw_iterator.next()) |draw_str| {
            const draw = CubeSet.fromDraw(draw_str);
            draw_contained = draw_contained and limit.contains(draw);
            minimumGameCubeSet = minimumGameCubeSet.maximum(draw);
        }
        if (draw_contained) {
            sum_one += std.fmt.parseInt(u8, line[5..colon_index], 10) catch unreachable;
        }
        sum_two += minimumGameCubeSet.power();
    }
    return .{ sum_one, sum_two };
}

const CubeSet = struct {
    red: u32,
    green: u32,
    blue: u32,

    pub fn fromDraw(draw: []const u8) CubeSet {
        var color_iterator = mem.splitSequence(u8, draw, ", ");
        var red: u32 = 0;
        var green: u32 = 0;
        var blue: u32 = 0;
        while (color_iterator.next()) |color| {
            if (mem.eql(u8, color[color.len - 3 ..], "red")) {
                red = std.fmt.parseInt(u8, color[0 .. color.len - 4], 10) catch unreachable;
            } else if (mem.eql(u8, color[color.len - 5 ..], "green")) {
                green = std.fmt.parseInt(u8, color[0 .. color.len - 6], 10) catch unreachable;
            } else if (mem.eql(u8, color[color.len - 4 ..], "blue")) {
                blue = std.fmt.parseInt(u8, color[0 .. color.len - 5], 10) catch unreachable;
            }
        }
        return CubeSet{
            .red = red,
            .green = green,
            .blue = blue,
        };
    }

    pub fn contains(self: CubeSet, other: CubeSet) bool {
        return other.red <= self.red and other.green <= self.green and other.blue <= self.blue;
    }

    pub fn maximum(self: CubeSet, other: CubeSet) CubeSet {
        return CubeSet{
            .red = @max(self.red, other.red),
            .green = @max(self.green, other.green),
            .blue = @max(self.blue, other.blue),
        };
    }

    pub fn power(self: CubeSet) u32 {
        return self.red * self.green * self.blue;
    }
};

const sample_1: []const u8 =
    \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
    \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
    \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
    \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(8, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(2286, solution[1]);
}
