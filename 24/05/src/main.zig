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
    var context = std.AutoHashMap(u64, void).init(allocator);
    defer context.deinit();

    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) break;
        var num_iterator = mem.splitScalar(u8, line, '|');
        const a = std.fmt.parseInt(u32, num_iterator.next().?, 10) catch unreachable;
        const b = std.fmt.parseInt(u32, num_iterator.next().?, 10) catch unreachable;
        context.put(appendNumbers(a, b), {}) catch unreachable;
    }

    var sum_one: u64 = 0;
    var sum_two: u64 = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const update = util.parseNumbersScalar(allocator, u32, 10, line, ',');
        defer allocator.free(update);
        if (std.sort.isSorted(u32, update, context, cmpByHashMap)) {
            sum_one += update[(update.len) / 2];
        } else {
            std.sort.heap(u32, update, context, cmpByHashMap);
            sum_two += update[(update.len) / 2];
        }
    }

    return .{ sum_one, sum_two };
}

fn cmpByHashMap(context: std.AutoHashMap(u64, void), a: u32, b: u32) bool {
    return context.contains(appendNumbers(a, b));
}

fn appendNumbers(a: u32, b: u32) u64 {
    return (@as(u64, a) << 32) + b;
}

const sample_1: []const u8 =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(143, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(123, solution[1]);
}
