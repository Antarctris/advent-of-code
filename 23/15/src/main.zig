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

    var boxes: [256]std.AutoArrayHashMap(u64, u4) = undefined;
    for (0..boxes.len) |i| {
        boxes[i] = std.AutoArrayHashMap(u64, u4).init(allocator);
    }
    defer for (0..boxes.len) |i| {
        boxes[i].deinit();
    };

    // Remove last char (\n) from input, as it messes up the indexing of d
    var step_iterator = mem.tokenizeScalar(u8, input[0 .. input.len - 1], ',');
    while (step_iterator.next()) |step| {
        if (step.len == 0) continue;
        sum_one += hash256(step);
        if (util.intFromDigit(step[step.len - 1])) |d| {
            const key0 = hash256(step[0 .. step.len - 2]);
            const key1 = hashBig(step[0 .. step.len - 2]);
            boxes[key0].put(key1, d) catch unreachable;
        } else {
            const key0 = hash256(step[0 .. step.len - 1]);
            const key1 = hashBig(step[0 .. step.len - 1]);
            _ = boxes[key0].orderedRemove(key1);
        }
    }
    for (boxes, 1..) |box, box_number| {
        for (box.keys(), 1..) |lens_key, lens_number| {
            sum_two += box_number * lens_number * box.get(lens_key).?;
        }
    }

    return .{ sum_one, sum_two };
}

fn hashBig(string: []const u8) u64 {
    return std.hash.Wyhash.hash(0, string);
}

fn hash256(string: []const u8) u8 {
    var accumulator: u64 = 0;
    for (string) |c| {
        accumulator = @mod((accumulator + c) * 17, 256);
    }
    return @intCast(accumulator);
}

const sample_1: []const u8 =
    \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(1320, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(145, solution[1]);
}
