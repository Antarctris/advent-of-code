const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

const util = @import("util");
const grid = util.grid;
const Solution = @import("./solution.zig");

// interface
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day 13: Claw Contraption";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    var tokens_spend: u64 = 0;

    var machine_iterator = mem.tokenizeSequence(u8, input, "\n\n");
    while (machine_iterator.next()) |machine_str| {
        const m = ClawMachine.parse(machine_str);
        const a = @divFloor(m.b.determinant(m.p), m.b.determinant(m.a));
        const b = @divFloor(m.a.determinant(m.p), m.a.determinant(m.b));
        if (m.p.equals(m.a.times(a).translate(m.b.times(b)))) {
            tokens_spend += @intCast(3 * a + b);
        }
    }

    return tokens_spend;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    var tokens_spend: u64 = 0;

    var machine_iterator = mem.tokenizeSequence(u8, input, "\n\n");
    while (machine_iterator.next()) |machine_str| {
        var m = ClawMachine.parse(machine_str);
        m.p = m.p.translate(grid.SE.times(10000000000000));
        const a = @divFloor(m.b.determinant(m.p), m.b.determinant(m.a));
        const b = @divFloor(m.a.determinant(m.p), m.a.determinant(m.b));
        if (m.p.equals(m.a.times(a).translate(m.b.times(b)))) {
            tokens_spend += @intCast(3 * a + b);
        }
    }

    return tokens_spend;
}

const ClawMachine = struct {
    a: grid.Vec2,
    b: grid.Vec2,
    p: grid.Vec2,

    pub fn parse(input: []const u8) ClawMachine {
        var number_iterator = util.mem.tokenizeNumbers(i64, input);
        return .{
            .a = grid.Vec2{ .x = number_iterator.next().?, .y = number_iterator.next().? },
            .b = grid.Vec2{ .x = number_iterator.next().?, .y = number_iterator.next().? },
            .p = grid.Vec2{ .x = number_iterator.next().?, .y = number_iterator.next().? },
        };
    }
};

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(480, result);
}

const sample_1: []const u8 =
    \\Button A: X+94, Y+34
    \\Button B: X+22, Y+67
    \\Prize: X=8400, Y=5400
    \\
    \\Button A: X+26, Y+66
    \\Button B: X+67, Y+21
    \\Prize: X=12748, Y=12176
    \\
    \\Button A: X+17, Y+86
    \\Button B: X+84, Y+37
    \\Prize: X=7870, Y=6450
    \\
    \\Button A: X+69, Y+23
    \\Button B: X+27, Y+71
    \\Prize: X=18641, Y=10279
    \\
    \\
;
