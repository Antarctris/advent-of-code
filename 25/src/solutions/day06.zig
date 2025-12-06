const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

const util = @import("util");
const Solution = @import("./solution.zig");

// interface
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day 6: Trash Compactor";
}

pub fn part_one(allocator: Allocator, input: []const u8) Solution.Result {
    _ = allocator;
    var line_iterator = std.mem.tokenizeScalar(u8, input, '\n');
    var col_iterator_array: [5]std.mem.TokenIterator(u8, .scalar) = undefined;
    var li: usize = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        col_iterator_array[li] = std.mem.tokenizeScalar(u8, line, ' ');
        li += 1;
    }
    const col_iterators = col_iterator_array[0..li];

    var sum: u64 = 0;
    while (col_iterators[0].next()) |n_str| {
        var n: u64 = std.fmt.parseInt(u64, n_str, 10) catch unreachable;
        const op: u8 = (col_iterators[col_iterators.len - 1].next() orelse unreachable)[0];
        for (1..col_iterators.len - 1) |i| {
            const c = std.fmt.parseInt(u64, col_iterators[i].next() orelse unreachable, 10) catch unreachable;
            n = if (op == '+') (n + c) else (n * c);
        }
        sum += n;
    }

    return Solution.Result.number(sum);
}

pub fn part_two(allocator: Allocator, input: []const u8) Solution.Result {
    var grid0 = util.grid.ByteGrid.parse(allocator, input);
    defer grid0.deinit();
    var gridT = grid0.columnsToRows();
    defer gridT.deinit();

    const w = gridT.width - 1;
    var sum: u64 = 0;
    var current: u64 = 0;
    var op: u8 = 0;
    for (0..gridT.height) |i| {
        const row = gridT.row(i);
        if (isWhitespace(row)) {
            sum += current;
            op = 0;
            continue;
        }
        if (op == 0) {
            op = row[w];
            current = std.fmt.parseInt(u64, std.mem.trim(u8, row[0..w], " "), 10) catch unreachable;
        } else {
            const n = std.fmt.parseInt(u64, std.mem.trim(u8, row[0..w], " "), 10) catch unreachable;
            current = if (op == '+') (current + n) else (current * n);
        }
    }
    sum += current;

    return Solution.Result.number(sum);
}

pub fn isWhitespace(str: []const u8) bool {
    for (str) |c| {
        if (c != ' ') return false;
    }
    return true;
}

test "part_1.sample_1" {
    var result = part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(4277556, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(3263827, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\123 328  51 64 
    \\ 45 64  387 23 
    \\  6 98  215 314
    \\*   +   *   +  
    \\
;
