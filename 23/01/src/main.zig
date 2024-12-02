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
    var solution_one: u32 = 0;
    var solution_two: u32 = 0;
    var line_iterator = mem.split(u8, input, "\n");
    while (line_iterator.next()) |line| {
        if (line.len < 1) continue;
        var tens_one: u32 = 0;
        var unit_one: u32 = 0;
        var tens_two: u32 = 0;
        var unit_two: u32 = 0;
        for (line, 0..) |char, index| {
            if (isDigit(char)) {
                unit_one = char - '0'; // Convert to actual number
                unit_two = unit_one;
            } else if (isDigitFromWord(line[index..])) |d| {
                unit_two = d;
            }
            if (tens_one == 0 and unit_one > 0) {
                tens_one = unit_one * 10;
            }
            if (tens_two == 0 and unit_two > 0) {
                tens_two = unit_two * 10;
            }
        }
        solution_one += tens_one + unit_one;
        solution_two += tens_two + unit_two;
    }
    return .{ solution_one, solution_two };
}

fn isDigit(char: u8) bool {
    return switch (char) {
        '0'...'9' => true,
        else => false,
    };
}

fn isDigitFromWord(line: []const u8) ?u32 {
    if (mem.startsWith(u8, line, "one")) {
        return 1;
    } else if (mem.startsWith(u8, line, "two")) {
        return 2;
    } else if (mem.startsWith(u8, line, "three")) {
        return 3;
    } else if (mem.startsWith(u8, line, "four")) {
        return 4;
    } else if (mem.startsWith(u8, line, "five")) {
        return 5;
    } else if (mem.startsWith(u8, line, "six")) {
        return 6;
    } else if (mem.startsWith(u8, line, "seven")) {
        return 7;
    } else if (mem.startsWith(u8, line, "eight")) {
        return 8;
    } else if (mem.startsWith(u8, line, "nine")) {
        return 9;
    }
    return null;
}

const sample_1: []const u8 =
    \\1abc2
    \\pqr3stu8vwx
    \\a1b2c3d4e5f
    \\treb7uchet
    \\
;

const sample_2: []const u8 =
    \\two1nine
    \\eightwothree
    \\abcone2threexyz
    \\xtwone3four
    \\4nineeightseven2
    \\zoneight234
    \\7pqrstsixteen
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(142, solution[0]);
}

test "part_2.sample_2" {
    const solution = solveChallenge(std.testing.allocator, sample_2);
    try std.testing.expectEqual(281, solution[1]);
}
