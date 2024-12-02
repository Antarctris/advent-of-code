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

fn lessThan(context: void, a: u64, b: u64) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

pub fn solveChallenge(allocator: Allocator, input: []const u8) [2]u64 {
    var line_iterator = mem.splitScalar(u8, input, '\n');

    var l = std.PriorityQueue(u64, void, lessThan).init(allocator, {});
    defer l.deinit();
    var r = std.PriorityQueue(u64, void, lessThan).init(allocator, {});
    defer r.deinit();
    var rc = std.AutoHashMap(u64, u64).init(allocator);
    defer rc.deinit();

    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        var lr_tokens = mem.tokenize(u8, line, " ");
        const l_value = std.fmt.parseInt(u64, lr_tokens.next().?, 10) catch unreachable;
        l.add(l_value) catch unreachable;
        const r_value = std.fmt.parseInt(u64, lr_tokens.next().?, 10) catch unreachable;
        r.add(r_value) catch unreachable;
        rc.put(r_value, 1 + (rc.get(r_value) orelse 0)) catch unreachable;
    }

    var solution_one: u64 = 0;
    var solution_two: u64 = 0;
    while (l.removeOrNull()) |lv| {
        if (r.removeOrNull()) |rv| {
            solution_one += @max(lv, rv) - @min(lv, rv);
        }
        solution_two += lv * (rc.get(lv) orelse 0);
    }
    return .{ solution_one, solution_two };
}

const sample_1: []const u8 =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(11, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(31, solution[1]);
}
