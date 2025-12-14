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

const Gate = struct {
    a: []const u8,
    op: op,
    b: []const u8,
    t: []const u8,
};

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var calculated = std.StringArrayHashMap(bool).init(allocator);
    defer calculated.deinit();

    var waiting_gates = std.ArrayList(Gate).init(allocator);
    defer waiting_gates.deinit();

    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (line.len == 0) break;
        calculated.put(line[0..3], line[5] == '1') catch unreachable;
    }
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        var data_iterator = mem.tokenizeAny(u8, line, " ->");
        waiting_gates.append(Gate{
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
    var gates = std.ArrayList(Gate).init(allocator);
    defer gates.deinit();

    var line_iterator = mem.splitScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        // Skip all inputs, for this part only the gates are needed
        if (line.len == 0) break;
    }
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        var data_iterator = mem.tokenizeAny(u8, line, " ->");
        gates.append(Gate{
            .a = data_iterator.next().?,
            .op = op.fromString(data_iterator.next().?),
            .b = data_iterator.next().?,
            .t = data_iterator.next().?,
        }) catch unreachable;
    }

    var wrong = std.StringArrayHashMap(void).init(allocator);
    defer wrong.deinit();

    // Basic idea is a ripple carry adder and we check whether the gates are set
    // up correctly according to the gate-structure of a typical ripple carry adder.
    for (gates.items) |gate| {
        // Output-gates should always be XOR (except the last one)
        if (gate.t[0] == 'z' and gate.op != .x and !mem.eql(u8, gate.t, "z45")) {
            wrong.put(gate.t, {}) catch unreachable;
        }

        // XOR gates should always be connected to either output or input
        if (gate.op == .x and
            std.mem.indexOfScalar(u8, "xyz", gate.t[0]) == null and
            std.mem.indexOfScalar(u8, "xyz", gate.a[0]) == null and
            std.mem.indexOfScalar(u8, "xyz", gate.b[0]) == null)
        {
            wrong.put(gate.t, {}) catch unreachable;
        }

        // Every AND gate (except the first one) should only route to OR gates.
        if (gate.op == .a and !mem.eql(u8, gate.a, "x00") and !mem.eql(u8, gate.b, "x00")) {
            for (gates.items) |other| {
                if ((mem.eql(u8, gate.t, other.a) or mem.eql(u8, gate.t, other.b)) and other.op != .o) {
                    wrong.put(gate.t, {}) catch unreachable;
                }
            }
        }

        // An XOR gate should never route to an OR gate.
        if (gate.op == .x) {
            for (gates.items) |other| {
                if ((mem.eql(u8, gate.t, other.a) or mem.eql(u8, gate.t, other.b)) and other.op == .o) {
                    wrong.put(gate.t, {}) catch unreachable;
                }
            }
        }
    }

    const wrong_gate_outputs = wrong.keys();

    std.mem.sort([]const u8, wrong_gate_outputs, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lessThan);

    for (wrong_gate_outputs) |out| {
        std.debug.print("{s},", .{out});
    }
    std.debug.print("\n", .{});

    return 0;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(2024, result);
}

test "part_2.sample_2" {
    const result = part_two(std.testing.allocator, sample_2) orelse return error.SkipZigTest;
    try std.testing.expectEqual(0, result);
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

const sample_2: []const u8 =
    \\x00: 0
    \\x01: 1
    \\x02: 0
    \\x03: 1
    \\x04: 0
    \\x05: 1
    \\y00: 0
    \\y01: 0
    \\y02: 1
    \\y03: 1
    \\y04: 0
    \\y05: 1
    \\
    \\x00 AND y00 -> z05
    \\x01 AND y01 -> z02
    \\x02 AND y02 -> z01
    \\x03 AND y03 -> z03
    \\x04 AND y04 -> z04
    \\x05 AND y05 -> z00
;
