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
    return "Day 24: Crossed Wires";
}

const op = enum {
    a,
    o,
    x,

    pub fn fromString(str: []const u8) op {
        if (mem.eql(u8, "AND", str)) {
            return .a;
        }
        if (mem.eql(u8, "OR", str)) {
            return .o;
        }
        if (mem.eql(u8, "XOR", str)) {
            return .x;
        }
        std.debug.print("\n{s}\n", .{str});
        unreachable;
    }
};

const Entry = struct {
    a: []const u8,
    op: op,
    b: []const u8,
    t: []const u8,
};

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var calculated = std.StringArrayHashMap(bool).init(allocator);
    defer calculated.deinit();

    var waiting_gates = std.ArrayList(Entry).init(allocator);
    defer waiting_gates.deinit();

    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) break;
        calculated.put(line[0..3], line[5] == '1') catch unreachable;
    }
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        var data_iterator = mem.tokenizeAny(u8, line, " ->");
        waiting_gates.append(Entry{
            .a = data_iterator.next().?,
            .op = op.fromString(data_iterator.next().?),
            .b = data_iterator.next().?,
            .t = data_iterator.next().?,
        }) catch unreachable;
    }

    while (waiting_gates.items.len > 0) {
        var index: usize = 0;
        while (index < waiting_gates.items.len) {
            const entry = waiting_gates.items[index];
            if (calculated.get(entry.a)) |a| {
                if (calculated.get(entry.b)) |b| {
                    calculated.put(entry.t, switch (entry.op) {
                        .a => a and b,
                        .o => a or b,
                        .x => a != b,
                    }) catch unreachable;
                    _ = waiting_gates.swapRemove(index);
                    continue;
                }
            }
            index += 1;
        }
    }

    const keys = allocator.dupe([]const u8, calculated.keys()) catch unreachable;
    defer allocator.free(keys);
    std.sort.heap([]const u8, keys, {}, greaterThan);

    var result: u64 = 0;
    for (keys) |key| {
        if (!mem.startsWith(u8, key, "z")) break;
        result = (result << 1) | @as(u64, if (calculated.get(key).?) 1 else 0);
    }

    return result;
}

fn greaterThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .gt;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    _ = allocator;
    _ = input;
    return null;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(2024, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(null, result);
}

const sample_1: []const u8 =
    \\x00: 1
    \\x01: 0
    \\x02: 1
    \\x03: 1
    \\x04: 0
    \\y00: 1
    \\y01: 1
    \\y02: 1
    \\y03: 1
    \\y04: 1
    \\
    \\ntg XOR fgs -> mjb
    \\y02 OR x01 -> tnw
    \\kwq OR kpj -> z05
    \\x00 OR x03 -> fst
    \\tgd XOR rvg -> z01
    \\vdt OR tnw -> bfw
    \\bfw AND frj -> z10
    \\ffh OR nrd -> bqk
    \\y00 AND y03 -> djm
    \\y03 OR y00 -> psh
    \\bqk OR frj -> z08
    \\tnw OR fst -> frj
    \\gnj AND tgd -> z11
    \\bfw XOR mjb -> z00
    \\x03 OR x00 -> vdt
    \\gnj AND wpb -> z02
    \\x04 AND y00 -> kjc
    \\djm OR pbm -> qhw
    \\nrd AND vdt -> hwm
    \\kjc AND fst -> rvg
    \\y04 OR y02 -> fgs
    \\y01 AND x02 -> pbm
    \\ntg OR kjc -> kwq
    \\psh XOR fgs -> tgd
    \\qhw XOR tgd -> z09
    \\pbm OR djm -> kpj
    \\x03 XOR y03 -> ffh
    \\x00 XOR y04 -> ntg
    \\bfw OR bqk -> z06
    \\nrd XOR fgs -> wpb
    \\frj XOR qhw -> z04
    \\bqk OR frj -> z07
    \\y03 OR x01 -> nrd
    \\hwm AND bqk -> z03
    \\tgd XOR rvg -> z12
    \\tnw OR pbm -> gnj
    \\
;
