const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

// For debug only stuff
const builtin = @import("builtin");
const dbg = builtin.mode == .Debug;

const util = @import("util");
const Solution = @import("./solution.zig");

// interface
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day 17: Chronospatial Computer";
}

const ChronospatialComputer = struct {
    allocator: Allocator,
    reg_a: u64,
    reg_b: u64,
    reg_c: u64,
    instr_ptr: u64 = 0,
    instr_mem: []const u3,
    out: std.ArrayList(u8),

    fn init(allocator: Allocator, a: u64, b: u64, c: u64, instr_str: []const u8) ChronospatialComputer {
        return .{
            .allocator = allocator,
            .reg_a = a,
            .reg_b = b,
            .reg_c = c,
            .instr_mem = util.parseNumbersScalar(allocator, u3, 10, instr_str, ','),
            .out = std.ArrayList(u8).init(allocator),
        };
    }

    fn deinit(self: *ChronospatialComputer) void {
        self.allocator.free(self.instr_mem);
        self.out.deinit();
    }

    fn run(self: *ChronospatialComputer) []const u8 {
        while (self.op()) {}
        return self.out.items[0 .. self.out.items.len - 1];
    }

    fn op(self: *ChronospatialComputer) bool {
        if (self.instr_ptr >= self.instr_mem.len) return false;
        const literal_operand = self.instr_mem[self.instr_ptr + 1];
        const combo_operand: u64 = switch (literal_operand) {
            0...3 => |d| d,
            4 => self.reg_a,
            5 => self.reg_b,
            6 => self.reg_c,
            7 => unreachable,
        };
        switch (self.instr_mem[self.instr_ptr]) {
            0 => {
                self.reg_a = @divTrunc(self.reg_a, @as(u64, 1) << @intCast(combo_operand));
            },
            1 => {
                self.reg_b ^= literal_operand;
            },
            2 => {
                self.reg_b = combo_operand % 8;
            },
            3 => {
                if (self.reg_a != 0) {
                    self.instr_ptr = literal_operand;
                    return true;
                }
            },
            4 => {
                self.reg_b ^= self.reg_c;
            },
            5 => {
                _ = self.out.writer().write(&.{ @intCast('0' + (combo_operand % 8)), ',' }) catch unreachable;
            },
            6 => {
                self.reg_b = @divTrunc(self.reg_a, @as(u64, 1) << @intCast(combo_operand));
            },
            7 => {
                self.reg_c = @divTrunc(self.reg_a, @as(u64, 1) << @intCast(combo_operand));
            },
        }
        self.instr_ptr += 2;
        return true;
    }
};

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');

    var cc = ChronospatialComputer.init(
        allocator,
        std.fmt.parseInt(u64, line_iterator.next().?[12..], 10) catch unreachable,
        std.fmt.parseInt(u64, line_iterator.next().?[12..], 10) catch unreachable,
        std.fmt.parseInt(u64, line_iterator.next().?[12..], 10) catch unreachable,
        line_iterator.next().?[9..],
    );
    defer cc.deinit();

    const out = cc.run();

    std.debug.print("{s}\n", .{out});

    return 0;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');

    _ = line_iterator.next(); // Ignore value of a
    const b: u64 = std.fmt.parseInt(u64, line_iterator.next().?[12..], 10) catch unreachable;
    const c: u64 = std.fmt.parseInt(u64, line_iterator.next().?[12..], 10) catch unreachable;
    const instr_str: []const u8 = line_iterator.next().?[9..];

    // This can only solve if a is divided by 8 each step
    // and if the last operation is the only jump, returning to 0.
    if (!(mem.count(u8, instr_str, "0,") == 1 and mem.count(u8, instr_str, "0,3") == 1 and
        mem.endsWith(u8, instr_str, "3,0")))
    {
        std.debug.print("This solution can only solve if '0,3' is the only modification of a and the instructions end with '3,0'\n", .{});
        return null;
    }

    var out = std.ArrayList(u8).initCapacity(allocator, instr_str.len) catch unreachable;
    defer out.deinit();

    var a: u64 = 0;
    var find: u64 = 0;
    while (!mem.eql(u8, instr_str, out.items)) {
        find += 1;
        a *= 8;
        if (a > 0) a -= 1; // Counter increment in next loop to check full range
        while (!mem.eql(u8, instr_str[instr_str.len - (find * 2 - 1) ..], out.items)) {
            out.clearRetainingCapacity();
            a += 1;
            var cc = ChronospatialComputer.init(allocator, a, b, c, instr_str);
            defer cc.deinit();
            out.appendSliceAssumeCapacity(cc.run());
        }
        if (dbg and !builtin.is_test) std.debug.print("Found a={d} for {s}\n", .{ a, out.items });
    }
    return a;
}

//2,4 b = a % 8
//1,5 b ^= 5
//7,5 c = a / 1 << b
//1,6 b ^= 6
//4,2 b ^= c
//5,5 out b % 8     <-- only value truncated by next operation is used
//0,3 a = a / 8
//3,0 jnz 0
/// My original solution solving only exactly my input
pub fn part_two_orig(allocator: Allocator, input: []const u8) ?u64 {
    _ = input;

    const target: [16]u3 = .{ 2, 4, 1, 5, 7, 5, 1, 6, 4, 2, 5, 5, 0, 3, 3, 0 };
    var out = std.ArrayList(u3).initCapacity(allocator, 16) catch unreachable;
    defer out.deinit();

    var index: u64 = 0;
    var find: u64 = 0;
    while (!mem.eql(u3, &target, out.items)) {
        index *= 8;
        if (index > 0) index -= 1;
        find += 1;
        while (!mem.eql(u3, target[target.len - find ..], out.items)) {
            out.clearRetainingCapacity();
            index += 1;
            var a: u64 = index;
            var b: u64 = 0;
            var c: u64 = 0;
            while (a != 0) {
                b = a % 8;
                b ^= 5;
                c = @divTrunc(a, @as(u64, 1) << @intCast(b));
                b ^= 6;
                b ^= c;
                out.appendAssumeCapacity(@intCast(b % 8));
                a = @divTrunc(a, 8);
            }
        }
        if (dbg) std.debug.print("Found index {d} for {any}\n", .{ index, out.items });
    }

    return index;
}

test "part_1.sample_1" {
    var line_iterator = mem.tokenizeScalar(u8, sample_1, '\n');

    var cc = ChronospatialComputer.init(
        std.testing.allocator,
        std.fmt.parseInt(u64, line_iterator.next().?[12..], 10) catch unreachable,
        std.fmt.parseInt(u64, line_iterator.next().?[12..], 10) catch unreachable,
        std.fmt.parseInt(u64, line_iterator.next().?[12..], 10) catch unreachable,
        line_iterator.next().?[9..],
    );
    defer cc.deinit();

    const out: []const u8 = cc.run();

    try std.testing.expectEqualStrings("4,6,3,5,6,3,5,2,1,0", out);
}

test "part_2.sample_2" {
    const result = part_two(std.testing.allocator, sample_2) orelse return error.SkipZigTest;
    try std.testing.expectEqual(117440, result);
}

const sample_1: []const u8 =
    \\Register A: 729
    \\Register B: 0
    \\Register C: 0
    \\
    \\Program: 0,1,5,4,3,0
;

const sample_2: []const u8 =
    \\Register A: 2024
    \\Register B: 0
    \\Register C: 0
    \\
    \\Program: 0,3,5,4,3,0
    \\
;
