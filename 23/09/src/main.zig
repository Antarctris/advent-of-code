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
    var line_iterator = mem.splitScalar(u8, input, '\n');
    var sum_one: i64 = 0;
    var sum_two: i64 = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        sum_one += getNextinSequence(allocator, line, false);
        sum_two += getNextinSequence(allocator, line, true);
    }
    return .{ @intCast(sum_one), @intCast(sum_two) };
}

fn sequenceOfSame(sequence: []i64) bool {
    if (sequence.len < 2) return true;
    for (1..sequence.len) |i| {
        if (sequence[i] != sequence[0]) return false;
    }
    return true;
}

fn getNextinSequence(allocator: Allocator, line: []const u8, reverse: bool) i64 {
    var stack = std.ArrayList(std.ArrayList(i64)).init(allocator);
    defer stack.deinit();

    var sequence = std.ArrayList(i64).init(allocator);
    defer sequence.deinit();

    var token_iterator = mem.tokenizeScalar(u8, line, ' ');
    while (token_iterator.next()) |token| {
        const n: i64 = std.fmt.parseInt(i64, token, 10) catch unreachable;
        if (reverse) {
            sequence.insert(0, n) catch unreachable;
        } else {
            sequence.append(n) catch unreachable;
        }
    }
    while (!sequenceOfSame(sequence.items)) {
        var derivative = std.ArrayList(i64).init(allocator);
        for (0..sequence.items.len - 1) |i| {
            derivative.append(sequence.items[i + 1] - sequence.items[i]) catch unreachable;
        }
        stack.append(sequence) catch unreachable;
        sequence = derivative;
    }
    while (stack.items.len > 0) {
        var current = stack.pop();
        current.append(current.items[current.items.len - 1] + sequence.items[sequence.items.len - 1]) catch unreachable;
        sequence.deinit();
        sequence = current;
    }
    const next: i64 = sequence.items[sequence.items.len - 1];
    //std.debug.print("{s} => {d}\n", .{ line, next });
    return next;
}

const sample_1: []const u8 =
    \\0 3 6 9 12 15
    \\1 3 6 10 15 21
    \\10 13 16 21 30 45
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(114, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(2, solution[1]);
}
