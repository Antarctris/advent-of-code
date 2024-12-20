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
    return "Day 7: Camel Cards";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    var hands = std.PriorityQueue(Hand, *const fn (card: u8) u32, handLessThan).init(allocator, cardValue);
    defer hands.deinit();
    while (line_iterator.next()) |line| {
        hands.add(Hand.FromSlice(line, false)) catch unreachable;
    }

    var total: u64 = 0;
    var rank: u64 = 1;
    while (hands.removeOrNull()) |hand| : (rank += 1) {
        total += hand.bid * rank;
    }

    return total;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    var hands = std.PriorityQueue(Hand, *const fn (card: u8) u32, handLessThan).init(allocator, cardValueJoker);
    defer hands.deinit();
    while (line_iterator.next()) |line| {
        hands.add(Hand.FromSlice(line, true)) catch unreachable;
    }

    var total: u64 = 0;
    var rank: u64 = 1;
    while (hands.removeOrNull()) |hand| : (rank += 1) {
        total += hand.bid * rank;
    }

    return total;
}

fn cardValue(card: u8) u32 {
    return switch (card) {
        '2'...'9' => card - '0',
        'T' => 10,
        'J' => 11,
        'Q' => 12,
        'K' => 13,
        'A' => 14,
        else => unreachable,
    };
}

fn cardValueJoker(card: u8) u32 {
    return if (card == 'J') 1 else cardValue(card);
}

const HandType = enum(u8) {
    highcard,
    onepair,
    twopair,
    triple,
    house,
    quadruple,
    quintuple,

    fn Determine(input: [5]u8, useJoker: bool) HandType {
        var jokers: u8 = 0;
        var pairA: ?u8 = null;
        var pairB: ?u8 = null;
        var triple: ?u8 = null;
        var result: HandType = HandType.highcard;
        for (input, 0..) |card, index| {
            if (useJoker == true and card == 'J') {
                if (jokers == 0) {
                    jokers = @intCast(std.mem.count(u8, input[index..], input[index .. index + 1]));
                }
                continue;
            }
            if (pairA == card) continue;
            if (pairB == card) continue;
            if (triple == card) continue;
            const count = std.mem.count(u8, input[index..], input[index .. index + 1]);

            const r: HandType = switch (count) {
                5 => HandType.quintuple,
                4 => HandType.quadruple,
                3 => three: {
                    if (pairA) |_| break :three HandType.house;
                    triple = card;
                    break :three HandType.triple;
                },
                2 => two: {
                    if (triple) |_| break :two HandType.house;
                    if (pairA) |_| {
                        pairB = card;
                        break :two HandType.twopair;
                    } else {
                        pairA = card;
                        break :two HandType.onepair;
                    }
                },
                else => result,
            };
            if (@intFromEnum(r) > @intFromEnum(result)) {
                result = r;
            }
        }
        if (useJoker) {
            result = switch (jokers) {
                0 => result,
                1 => switch (result) {
                    HandType.quintuple, HandType.quadruple => HandType.quintuple,
                    HandType.house, HandType.triple => HandType.quadruple,
                    HandType.twopair => HandType.house,
                    HandType.onepair => HandType.triple,
                    else => HandType.onepair,
                },
                2 => switch (result) {
                    HandType.highcard => HandType.triple,
                    HandType.onepair, HandType.twopair => HandType.quadruple,
                    else => HandType.quintuple,
                },
                3 => switch (result) {
                    HandType.highcard => HandType.quadruple,
                    else => HandType.quintuple,
                },
                else => HandType.quintuple,
            };
        }
        return result;
    }
};

const Hand = struct {
    hand: [5]u8,
    type: HandType,
    bid: u64,

    fn FromSlice(input: []const u8, useJoker: bool) Hand {
        const hand: [5]u8 = .{ input[0], input[1], input[2], input[3], input[4] };
        return .{
            .hand = hand,
            .type = HandType.Determine(hand, useJoker),
            .bid = std.fmt.parseInt(u64, input[6..], 10) catch unreachable,
        };
    }
};

fn handLessThan(valueFn: *const fn (u8) u32, a: Hand, b: Hand) std.math.Order {
    if (a.type == b.type) {
        var index: usize = 0;
        while (a.hand[index] == b.hand[index]) {
            index += 1;
        }
        return std.math.order(valueFn(a.hand[index]), valueFn(b.hand[index]));
    }
    return std.math.order(@intFromEnum(a.type), @intFromEnum(b.type));
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(6440, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(5905, result);
}

const sample_1: []const u8 =
    \\32T3K 765
    \\T55J5 684
    \\KK677 28
    \\KTJJT 220
    \\QQQJA 483
    \\
;
