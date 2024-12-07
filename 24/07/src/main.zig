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
    var sum_one: u64 = 0;
    var sum_two: u64 = 0;

    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;

        const separator = mem.indexOfScalar(u8, line, ':').?;
        const target = std.fmt.parseInt(u64, line[0..separator], 10) catch unreachable;
        const components = util.parseNumbersScalar(allocator, u64, 10, line[separator + 1 ..], ' ');
        defer allocator.free(components);

        sum_one += if (isEquationTrue(false, target, components[0], components[1..])) target else 0;
        sum_two += if (isEquationTrue(true, target, components[0], components[1..])) target else 0;
    }

    return .{ sum_one, sum_two };
}

pub fn isEquationTrue(concatenation: bool, target: u64, accumulator: u64, components: []const u64) bool {
    if (components.len == 0) {
        return target == accumulator;
    }
    return isEquationTrue(concatenation, target, accumulator + components[0], components[1..]) or
        isEquationTrue(concatenation, target, accumulator * components[0], components[1..]) or
        (concatenation and isEquationTrue(concatenation, target, concatNumbers(accumulator, components[0]), components[1..]));
}

fn concatNumbers(a: u64, b: u64) u64 {
    var pow: u64 = 10;
    while (b >= pow) pow *= 10;
    return a * pow + b;
}

const sample_1: []const u8 =
    \\190: 10 19
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(3749, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(11387, solution[1]);
}
