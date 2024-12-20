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
    return "Day 4: Scratchcards";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');

    var total_points: u32 = 0;

    var line: usize = 0;
    while (line_iterator.next()) |line_slice| : (line += 1) {
        const value_start = 2 + (mem.indexOfScalar(u8, line_slice, ':') orelse unreachable);
        const card = line_slice[value_start..];

        // Using a StringHashMap(void) was 4 times slower
        var winning_numbers = std.ArrayList(u16).init(allocator);
        defer winning_numbers.deinit();

        var index: usize = 0;
        while (card[index] != '|') : (index += 3) {
            winning_numbers.append(u16FromSlice(card[index .. index + 2])) catch unreachable;
        }
        index += 2;
        var points: u32 = 0;
        while (index < card.len) : (index += 3) {
            if (mem.indexOfScalar(u16, winning_numbers.items, u16FromSlice(card[index .. index + 2]))) |_| {
                if (points == 0) {
                    points = 1;
                } else {
                    points <<= 1;
                }
            }
        }

        total_points += points;
    }

    return total_points;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');

    var cards = std.ArrayList(u32).init(allocator);
    defer cards.deinit();
    var total_cards: u32 = 0;

    var line: usize = 0;
    while (line_iterator.next()) |line_slice| : (line += 1) {
        if (line < cards.items.len) {
            cards.items[line] += 1;
        } else {
            cards.append(1) catch unreachable;
        }

        const value_start = 2 + (mem.indexOfScalar(u8, line_slice, ':') orelse unreachable);
        const card = line_slice[value_start..];

        var winning_numbers = std.ArrayList(u16).init(allocator);
        defer winning_numbers.deinit();

        var index: usize = 0;
        while (card[index] != '|') : (index += 3) {
            winning_numbers.append(u16FromSlice(card[index .. index + 2])) catch unreachable;
        }
        index += 2;
        var winner_count: u32 = 0;
        while (index < card.len) : (index += 3) {
            if (mem.indexOfScalar(u16, winning_numbers.items, u16FromSlice(card[index .. index + 2]))) |_| {
                winner_count += 1;
                const card_won = line + winner_count;
                if (card_won < cards.items.len) {
                    cards.items[card_won] += cards.items[line];
                } else {
                    cards.append(cards.items[line]) catch unreachable;
                }
            }
        }

        total_cards += cards.items[line];
    }

    return total_cards;
}

fn u16FromSlice(input: []const u8) u16 {
    return (@as(u16, input[1]) << 8) + input[0];
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(13, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(30, result);
}

const sample_1: []const u8 =
    \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
    \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
    \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
    \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
    \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
;
