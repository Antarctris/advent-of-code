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

fn trimInlineScalar(T: type, allocator: Allocator, input: []const T, scalar: T) []T {
    var accumulator = std.ArrayList(T).init(allocator);
    defer accumulator.deinit();
    var iterator = std.mem.tokenizeScalar(T, input, scalar);
    while (iterator.next()) |token| {
        accumulator.appendSlice(token) catch unreachable;
    }
    return allocator.dupe(T, accumulator.items) catch unreachable;
}

pub fn solveChallenge(allocator: Allocator, input: []const u8) [2]u64 {
    var line_iterator = std.mem.splitScalar(u8, input, '\n');
    var time_iterator = std.mem.tokenizeScalar(u8, line_iterator.next().?[9..], ' ');
    var dist_iterator = std.mem.tokenizeScalar(u8, line_iterator.next().?[9..], ' ');
    var combinations: u64 = 1;
    while (time_iterator.next()) |time_str| {
        if (dist_iterator.next()) |dist_str| {
            const time: u64 = std.fmt.parseInt(u64, time_str, 10) catch unreachable;
            const dist: u64 = std.fmt.parseInt(u64, dist_str, 10) catch unreachable;
            var margin: u32 = 0;
            for (0..time) |t| {
                margin += if (t * (time - t) > dist) 1 else 0;
            }
            if (margin > 0) {
                combinations *= margin;
            }
        }
    }

    line_iterator.reset();
    const time_str = trimInlineScalar(u8, allocator, line_iterator.next().?[9..], ' ');
    defer allocator.free(time_str);
    const dist_str = trimInlineScalar(u8, allocator, line_iterator.next().?[9..], ' ');
    defer allocator.free(dist_str);

    const time: u64 = std.fmt.parseInt(u64, time_str, 10) catch unreachable;
    const dist: u64 = std.fmt.parseInt(u64, dist_str, 10) catch unreachable;
    var margin: u64 = time;
    for (0..time) |t| {
        if (t * (time - t) > dist) {
            // Margin is symmetric, therefore when I found how many are NOT included I can
            // subtract double of that. Further if I wait the whole time, thats also not
            // working therefore I account that one, too.
            margin -= 2 * (t - 1) + 1;
            break;
        }
    }

    return .{ combinations, margin };
}

const sample_1: []const u8 =
    \\Time:      7  15   30
    \\Distance:  9  40  200
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(288, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(71503, solution[1]);
}
