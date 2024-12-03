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
    var total_one: u64 = 0;
    var total_two: u64 = 0;
    total_one += parseAndCalculate(input, false);
    total_two += parseAndCalculate(input, true);
    return .{ total_one, total_two };
}

pub fn parseAndCalculate(line: []const u8, toggle: bool) u64 {
    var line_total: u64 = 0;
    var enabled: bool = true;
    var state: u8 = 0;
    var a: u64 = 0;
    var b: u64 = 0;
    for (line) |c| {
        if ((enabled and c == 'm') or (toggle and c == 'd')) {
            state = c;
            continue;
        }
        switch (state) {
            'm' => state = if (c == 'u') 'u' else 0,
            'u' => state = if (c == 'l') 'l' else 0,
            'l' => {
                if (c == '(') {
                    a = 0;
                    state = 'A';
                } else {
                    state = 0;
                }
            },
            'A' => {
                if (util.intFromDigit(c)) |d| {
                    a = a * 10 + d;
                    if (a > 999) state = 0;
                } else if (c == ',') {
                    b = 0;
                    state = 'B';
                } else {
                    state = 0;
                }
            },
            'B' => {
                if (util.intFromDigit(c)) |d| {
                    b = b * 10 + d;
                    if (b > 999) state = 0;
                } else {
                    if (c == ')') {
                        line_total += a * b;
                    }
                    state = 0;
                }
            },
            'd' => state = if (c == 'o') 'o' else 0,
            'o' => state = if (c == 'n') 'n' else if (c == '(') 'E' else 0,
            'n' => state = if (c == '\'') '\'' else 0,
            '\'' => state = if (c == 't') 't' else 0,
            't' => state = if (c == '(') 'D' else 0,
            'E' => {
                if (c == ')') {
                    enabled = true;
                }
                state = 0;
            },
            'D' => {
                if (c == ')') {
                    enabled = false;
                }
                state = 0;
            },
            else => state = 0,
        }
    }
    return line_total;
}

const sample_1: []const u8 =
    \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
    \\
;

const sample_2: []const u8 =
    \\xmul(2,4)&mul[3,7]!muldon't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(161, solution[0]);
}

test "part_2.sample_2" {
    const solution = solveChallenge(std.testing.allocator, sample_2);
    try std.testing.expectEqual(48, solution[1]);
}
