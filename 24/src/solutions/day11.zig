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
    return "Day 11: Plutonian Pebbles";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var stones = parseInitialStones(allocator, input);
    defer stones.deinit();
    return blinkAndCountMemo(allocator, stones, 25);
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var stones = parseInitialStones(allocator, input);
    defer stones.deinit();
    return blinkAndCountMemo(allocator, stones, 75);
}
fn parseInitialStones(allocator: Allocator, input: []const u8) std.ArrayList(u64) {
    var stones = std.ArrayList(u64).initCapacity(allocator, 1 << 17) catch unreachable;
    var stone_iterator = mem.tokenizeAny(u8, input, " \n");
    while (stone_iterator.next()) |stone| {
        stones.appendAssumeCapacity(std.fmt.parseInt(u64, stone, 10) catch unreachable);
    }
    return stones;
}

fn blinkAndCountMemo(allocator: Allocator, stones: std.ArrayList(u64), blink: u64) u64 {
    var memo = std.AutoHashMap(Memo, u64).init(allocator);
    memo.ensureTotalCapacity(1 << 17) catch unreachable;
    defer memo.deinit();

    var sum: u64 = 0;
    for (stones.items) |stone| {
        sum += blinkAndCountMemoria(stone, blink, &memo);
    }

    return sum;
}

fn blinkAndCountMemoria(stone: u64, blink: u64, memo: *std.AutoHashMap(Memo, u64)) u64 {
    if (blink == 0) {
        memo.put(Memo{ .stone = stone, .blink = blink }, 1) catch unreachable;
        return 1;
    }
    if (memo.get(Memo{ .stone = stone, .blink = blink })) |value| return value;
    memo.put(Memo{ .stone = stone, .blink = 0 }, 1) catch unreachable;
    var result: u64 = 0;
    const count = countDigits(stone);
    if (stone == 0) {
        result = blinkAndCountMemoria(1, blink - 1, memo);
        for (0..@intCast(blink)) |i| {
            memo.put(
                Memo{ .stone = 0, .blink = blink - i },
                memo.get(Memo{ .stone = 1, .blink = blink - i - 1 }).?,
            ) catch unreachable;
        }
    } else if (count % 2 == 0) {
        const b = std.math.pow(u64, 10, count / 2);
        const l = stone / b;
        const r = stone - l * b;
        result = blinkAndCountMemoria(l, blink - 1, memo) + blinkAndCountMemoria(r, blink - 1, memo);
        for (0..@intCast(blink)) |i| {
            memo.put(
                Memo{ .stone = stone, .blink = blink - i },
                memo.get(Memo{ .stone = l, .blink = blink - i - 1 }).? +
                    memo.get(Memo{ .stone = r, .blink = blink - i - 1 }).?,
            ) catch unreachable;
        }
    } else {
        result = blinkAndCountMemoria(stone * 2024, blink - 1, memo);
        for (0..@intCast(blink)) |i| {
            memo.put(
                Memo{ .stone = stone, .blink = blink - i },
                memo.get(Memo{ .stone = stone * 2024, .blink = blink - i - 1 }).?,
            ) catch unreachable;
        }
    }
    return if (result != 0) result else unreachable;
}

const Memo = struct {
    stone: u64,
    blink: u64,
};

fn blinkAndCount(stones: *std.ArrayList(u64), blink: usize) u64 {
    for (0..blink) |_| {
        var index: usize = 0;
        while (index < stones.items.len) {
            if (stones.items[index] == 0) {
                stones.items[index] = 1;
                index += 1;
                continue;
            }

            const count = countDigits(stones.items[index]);
            if (count % 2 == 0) {
                const b = std.math.pow(u64, 10, count / 2);
                const l = stones.items[index] / b; // 10 * count / 2
                const r = stones.items[index] - l * b;
                stones.items[index] = l;
                stones.insert(index + 1, r) catch unreachable;
                index += 2;
                continue;
            }

            stones.items[index] *= 2024;
            index += 1;
        }
    }
    return @intCast(stones.items.len);
}

fn countDigits(n: u64) u64 {
    var count: u64 = 0;
    var left: u64 = n;
    while (left != 0) {
        count += 1;
        left /= 10;
    }
    return count;
}

test "part_1.sample_0" {
    var stones = parseInitialStones(std.testing.allocator, sample_0);
    defer stones.deinit();
    const result = blinkAndCountMemo(std.testing.allocator, stones, 1);
    try std.testing.expectEqual(7, result);
}

test "part_1.sample_1.1" {
    var stones = parseInitialStones(std.testing.allocator, sample_1);
    defer stones.deinit();
    const result = blinkAndCountMemo(std.testing.allocator, stones, 6);
    try std.testing.expectEqual(22, result);
}

test "part_1.sample_1.2" {
    const result = part_one(std.testing.allocator, sample_1);
    try std.testing.expectEqual(55312, result);
}

const sample_0: []const u8 =
    \\0 1 10 99 999
    \\
;

const sample_1: []const u8 =
    \\125 17
    \\
;
