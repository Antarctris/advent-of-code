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
    var sum_one: u32 = 0;
    var sum_two: u32 = 0;
    var line_iterator = mem.splitScalar(u8, input, '\n');

    var cards = std.ArrayList(u32).init(allocator);
    defer cards.deinit();

    var line: usize = 0;
    while (line_iterator.next()) |line_slice| : (line += 1) {
        if (line_slice.len == 0) continue;
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
        var points: u32 = 0;
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
                if (points == 0) {
                    points = 1;
                } else {
                    points <<= 1;
                }
            }
        }

        //std.debug.print("Card {d}, {d}, wins {d}\n", .{ line + 1, cards.items[line], winner_count });
        sum_one += points;
        sum_two += cards.items[line];
    }

    return .{ sum_one, sum_two };
}

fn u16FromSlice(input: []const u8) u16 {
    return (@as(u16, input[1]) << 8) + input[0];
}

const sample_1: []const u8 =
    \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
    \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
    \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
    \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
    \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(13, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(30, solution[1]);
}
