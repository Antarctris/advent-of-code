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
    var hands_one = std.PriorityQueue(Hand, *const fn (card: u8) u32, handLessThan).init(allocator, cardValue);
    defer hands_one.deinit();
    var hands_two = std.PriorityQueue(Hand, *const fn (card: u8) u32, handLessThan).init(allocator, cardValueJoker);
    defer hands_two.deinit();
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        hands_one.add(Hand.FromSlice(line, false)) catch unreachable;
        hands_two.add(Hand.FromSlice(line, true)) catch unreachable;
    }

    // Part One
    var total_one: u64 = 0;
    var rank_one: u64 = 1;
    while (hands_one.removeOrNull()) |hand| : (rank_one += 1) {
        total_one += hand.bid * rank_one;
    }

    var total_two: u64 = 0;
    var rank_two: u64 = 1;
    while (hands_two.removeOrNull()) |hand| : (rank_two += 1) {
        total_two += hand.bid * rank_two;
    }

    return .{ total_one, total_two };
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

const sample_1: []const u8 =
    \\32T3K 765
    \\T55J5 684
    \\KK677 28
    \\KTJJT 220
    \\QQQJA 483
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(6440, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(5905, solution[1]);
}
