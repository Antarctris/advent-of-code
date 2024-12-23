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
    return "Day 22: Monkey Market";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    var total_random_numbers: u64 = 0;

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        var n: u64 = std.fmt.parseInt(u64, line, 10) catch unreachable;
        for (0..2000) |_| {
            n = pseudoRand(n);
        }
        total_random_numbers += n;
    }
    return total_random_numbers;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var sequence_values = std.AutoHashMap(u64, u64).init(allocator);
    defer sequence_values.deinit();

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        var n: u64 = std.fmt.parseInt(u64, line, 10) catch unreachable;

        var sequence_memo = std.AutoHashMap(u64, void).init(allocator);
        defer sequence_memo.deinit();

        // Setup initial values before first complete sequence
        var last: i16 = @intCast(n % 10);
        var sequence: u64 = 0;
        n = pseudoRand(n);
        const first: i16 = @intCast(n % 10);
        sequence |= @as(u16, @bitCast(first - last));
        last = first;
        n = pseudoRand(n);
        const second: i16 = @intCast(n % 10);
        sequence = sequence << 16 | @as(u16, @bitCast(second - last));
        last = second;
        n = pseudoRand(n);
        const third: i16 = @intCast(n % 10);
        sequence = sequence << 16 | @as(u16, @bitCast(third - last));
        last = third;

        // Check all complete sequences
        for (3..2000) |_| {
            n = pseudoRand(n);
            const next: i16 = @intCast(n % 10);
            sequence = sequence << 16 | @as(u16, @bitCast(next - last));
            last = next;

            // Use sequence only on first occurence
            if (!sequence_memo.contains(sequence)) {
                sequence_memo.put(sequence, {}) catch unreachable;
                const sequence_value: u64 = sequence_values.get(sequence) orelse 0;
                const next_value: u64 = @intCast(next);
                sequence_values.put(sequence, sequence_value + next_value) catch unreachable;
            }
        }
    }
    var total_bananas: u64 = 0;
    // Find highest total sequence value
    var sequence_iterator = sequence_values.iterator();
    while (sequence_iterator.next()) |kv| {
        total_bananas = @max(total_bananas, kv.value_ptr.*);
    }
    return total_bananas;
}

fn pseudoRand(n: u64) u64 {
    var s = n;
    const a = s * 64;
    s ^= a;
    s %= 16777216;
    const b = s / 32;
    s ^= b;
    s %= 16777216;
    const c = s * 2048;
    s ^= c;
    s %= 16777216;
    return s;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(37327623, result);
}

test "part_2.sample_2" {
    const result = part_two(std.testing.allocator, sample_2) orelse return error.SkipZigTest;
    try std.testing.expectEqual(23, result);
}

const sample_1: []const u8 =
    \\1
    \\10
    \\100
    \\2024
    \\
;

const sample_2: []const u8 =
    \\1
    \\2
    \\3
    \\2024
    \\
;
