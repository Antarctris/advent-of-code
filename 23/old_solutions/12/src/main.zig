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

const SpringRowContext = struct {
    pub fn hash(ctx: SpringRowContext, key: SpringRow) u64 {
        _ = ctx;
        var hasher = std.hash.Wyhash.init(0);
        std.hash.autoHashStrat(&hasher, key, std.hash.Strategy.Shallow); // I asumed I would need Deep. Why is Shallow sufficient?
        return hasher.final();
    }

    pub fn eql(ctx: SpringRowContext, a: SpringRow, b: SpringRow) bool {
        _ = ctx;
        return mem.eql(u8, a.array, b.array) and mem.eql(u64, a.series, b.series);
    }
};

const SpringRow = struct {
    array: []const u8,
    series: []usize,
};

pub fn solveChallenge(allocator: Allocator, input: []const u8) [2]u64 {
    var rows_short = std.ArrayList(SpringRow).init(allocator);
    defer rows_short.deinit();

    var rows_long = std.ArrayList(SpringRow).init(allocator);
    defer rows_long.deinit();

    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const i = mem.indexOf(u8, line, " ").?;
        const series_count = mem.count(u8, line[i + 1 ..], ",") + 1;
        var series_short: []u64 = allocator.alloc(u64, series_count) catch unreachable;
        var series_long: []u64 = allocator.alloc(u64, series_count * 5) catch unreachable;
        var series_iterator = mem.splitScalar(u8, line[i + 1 ..], ',');
        var index: usize = 0;
        while (series_iterator.next()) |series_entry| : (index += 1) {
            series_short[index] = std.fmt.parseInt(usize, series_entry, 10) catch unreachable;
            series_long[index + series_count * 0] = series_short[index];
            series_long[index + series_count * 1] = series_short[index];
            series_long[index + series_count * 2] = series_short[index];
            series_long[index + series_count * 3] = series_short[index];
            series_long[index + series_count * 4] = series_short[index];
        }
        rows_short.append(SpringRow{ .array = line[0..i], .series = series_short }) catch unreachable;
        const array_long = std.fmt.allocPrint(allocator, "{0s}?{0s}?{0s}?{0s}?{0s}", .{line[0..i]}) catch unreachable;
        rows_long.append(SpringRow{ .array = array_long, .series = series_long }) catch unreachable;
    }
    defer while (rows_short.popOrNull()) |row| {
        allocator.free(row.series);
    };
    defer while (rows_long.popOrNull()) |row| {
        allocator.free(row.array);
        allocator.free(row.series);
    };

    var memo = std.HashMap(SpringRow, u64, SpringRowContext, std.hash_map.default_max_load_percentage).init(allocator);
    line_iterator.reset();
    defer memo.deinit();

    var count_short: usize = 0;
    for (rows_short.items) |row| {
        const count: usize = countSolutionsOfSpringRow(row, &memo);
        count_short += count;
        //print("{s} => {d}\n", .{ line_iterator.next().?, count });
    }

    var count_long: usize = 0;
    for (rows_long.items) |row| {
        count_long += countSolutionsOfSpringRow(row, &memo);
    }

    return .{ count_short, count_long };
}

// TODO: refactor this completely
// A far better breakdown of the problem into recursive algorithm step can be found here:
// https://github.com/hb0nes/aoc_2023/blob/main/twelve_dp/src/main.rs
pub fn countSolutionsOfSpringRow(row: SpringRow, memo: *std.HashMap(SpringRow, u64, SpringRowContext, std.hash_map.default_max_load_percentage)) u64 {
    if (memo.get(row)) |value| return value;
    if (mem.count(u8, row.array, "#") > util.mem.sum(usize, row.series)) return (memo.getOrPutValue(row, 0) catch unreachable).value_ptr.*;
    var count: u64 = 0;
    const upperBound = mem.indexOf(u8, row.array[0 .. row.array.len - row.series[0]], "#") orelse row.array.len - row.series[0];
    var index: usize = 0;
    while (index <= upperBound) {
        if (util.mem.indexOfAnySeriesPos(u8, row.array[0 .. upperBound + row.series[0]], index, "?#", row.series[0])) |i| {
            const iSubsequent = i + row.series[0];
            if (row.series.len == 1) {
                count += @intFromBool(mem.indexOfPos(u8, row.array, iSubsequent, "#") == null);
            } else if (iSubsequent < row.array.len and row.array[iSubsequent] != '#' and row.array[iSubsequent + 1 ..].len >= row.series[1]) {
                count += countSolutionsOfSpringRow(SpringRow{ .array = row.array[iSubsequent + 1 ..], .series = row.series[1..] }, memo);
            }
            index = i + 1;
            continue;
        }
        break;
    }
    return (memo.getOrPutValue(row, count) catch unreachable).value_ptr.*;
}

const sample_1: []const u8 =
    \\???.### 1,1,3
    \\.??..??...?##. 1,1,3
    \\?#?#?#?#?#?#?#? 1,3,1,6
    \\????.#...#... 4,1,1
    \\????.######..#####. 1,6,5
    \\?###???????? 3,2,1
    \\
;

const sample_2: []const u8 =
    \\?????????????????# 1,3,1,2,2,1
    \\
;

const sample_3: []const u8 =
    \\?????#?#.?#? 4,3
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(21, solution[0]);
}

test "part_1.sample_2" {
    const solution = solveChallenge(std.testing.allocator, sample_2);
    try std.testing.expectEqual(56, solution[0]);
}

test "part_1.sample_3" {
    const solution = solveChallenge(std.testing.allocator, sample_3);
    try std.testing.expectEqual(1, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(525152, solution[1]);
}
