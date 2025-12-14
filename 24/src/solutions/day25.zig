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
    return "Day 25: Code Chronicle";
}

const Vec5 = @Vector(8, u8);
const Vec5_Zero: Vec5 = @splat(0);

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var locks = std.ArrayList(Vec5).initCapacity(allocator, 1000) catch unreachable;
    defer locks.deinit();
    var keys = std.ArrayList(Vec5).initCapacity(allocator, 1000) catch unreachable;
    defer keys.deinit();

    var entry_iterator = mem.splitSequence(u8, input, "\n\n");
    while (entry_iterator.next()) |entry_str| {
        var line_iterator = mem.splitScalar(u8, entry_str, '\n');
        _ = line_iterator.next();
        var entry = Vec5_Zero;
        inline for (0..5) |_| {
            const line = line_iterator.next().?;
            inline for (0..5) |i| {
                entry[i] += if (line[i] == '#') 1 else 0;
            }
        }
        const last = line_iterator.next().?;
        if (last[0] == '#') {
            keys.appendAssumeCapacity(entry);
        } else {
            locks.appendAssumeCapacity(entry);
        }
    }

    var combinations: u64 = 0;
    for (locks.items) |lock| {
        for (keys.items) |key| {
            if (@reduce(.And, (lock + key) < @as(Vec5, @splat(6)))) {
                combinations += 1;
            }
        }
    }

    return combinations;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    _ = input;
    return null;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(3, result);
}

const sample_1: []const u8 =
    \\#####
    \\.####
    \\.####
    \\.####
    \\.#.#.
    \\.#...
    \\.....
    \\
    \\#####
    \\##.##
    \\.#.##
    \\...##
    \\...#.
    \\...#.
    \\.....
    \\
    \\.....
    \\#....
    \\#....
    \\#...#
    \\#.#.#
    \\#.###
    \\#####
    \\
    \\.....
    \\.....
    \\#.#..
    \\###..
    \\###.#
    \\###.#
    \\#####
    \\
    \\.....
    \\.....
    \\.....
    \\#....
    \\#.#..
    \\#.#.#
    \\#####
;
