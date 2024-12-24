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
    return "Day 23: LAN Party";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var edges = std.StringHashMap(std.StringArrayHashMap(void)).init(allocator);
    defer edges.deinit();
    defer {
        var edge_iterator = edges.iterator();
        while (edge_iterator.next()) |map| {
            map.value_ptr.deinit();
        }
    }

    var t_nodes = std.StringArrayHashMap(void).init(allocator);
    defer t_nodes.deinit();

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        const a = line[0..2];
        const b = line[3..5];

        var a_edges = edges.get(a) orelse std.StringArrayHashMap(void).init(allocator);
        a_edges.put(b, {}) catch unreachable;
        edges.put(a, a_edges) catch unreachable;
        if (mem.startsWith(u8, a, "t")) t_nodes.put(a, {}) catch unreachable;

        var b_edges = edges.get(b) orelse std.StringArrayHashMap(void).init(allocator);
        b_edges.put(a, {}) catch unreachable;
        edges.put(b, b_edges) catch unreachable;
        if (mem.startsWith(u8, b, "t")) t_nodes.put(b, {}) catch unreachable;
    }

    var t_done = std.StringHashMap(void).init(allocator);
    defer t_done.deinit();

    var total_t_cliques: u64 = 0;

    var t_iterator = t_nodes.iterator();
    while (t_iterator.next()) |kv| {
        var total: u64 = 0;
        const node = kv.key_ptr.*;
        var t_neighbors = edges.get(node).?;
        for (t_neighbors.keys()) |tn| {
            if (t_done.contains(tn)) continue;
            var tn_neighbors = edges.get(tn).?;
            for (tn_neighbors.keys()) |tnn| {
                if (t_done.contains(tnn)) continue;
                if (t_neighbors.contains(tnn)) total += 1;
            }
        }
        total /= 2;
        total_t_cliques += total;
        t_done.put(node, {}) catch unreachable;
    }
    return total_t_cliques;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var edges = std.StringHashMap(std.StringArrayHashMap(void)).init(allocator);
    defer edges.deinit();
    defer {
        var edge_iterator = edges.iterator();
        while (edge_iterator.next()) |map| {
            map.value_ptr.deinit();
        }
    }

    var nodes = std.StringArrayHashMap(void).init(allocator);
    defer nodes.deinit();

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        const a = line[0..2];
        const b = line[3..5];

        var a_edges = edges.get(a) orelse std.StringArrayHashMap(void).init(allocator);
        a_edges.put(b, {}) catch unreachable;
        edges.put(a, a_edges) catch unreachable;
        nodes.put(a, {}) catch unreachable;

        var b_edges = edges.get(b) orelse std.StringArrayHashMap(void).init(allocator);
        b_edges.put(a, {}) catch unreachable;
        edges.put(b, b_edges) catch unreachable;
        nodes.put(b, {}) catch unreachable;
    }

    var maximum_clique: [][]const u8 = allocator.alloc([]const u8, 0) catch unreachable;
    defer allocator.free(maximum_clique);
    var current_clique = std.StringArrayHashMap(void).init(allocator);
    defer current_clique.deinit();

    var t_iterator = nodes.iterator();
    while (t_iterator.next()) |kv| {
        current_clique.clearRetainingCapacity();
        current_clique.put(kv.key_ptr.*, {}) catch unreachable;
        findMaximumCliqueRecursive(
            allocator,
            edges,
            &current_clique,
            &maximum_clique,
            edges.get(kv.key_ptr.*).?.keys(),
        );
    }

    if (!builtin.is_test) {
        std.mem.sort([]const u8, maximum_clique, {}, lessThan);
        for (maximum_clique) |node| {
            std.debug.print("{s},", .{node});
        }
        std.debug.print("\n", .{});
    }
    return 0;
}

fn findMaximumCliqueRecursive(
    allocator: Allocator,
    edges: std.StringHashMap(std.StringArrayHashMap(void)),
    current_clique: *std.StringArrayHashMap(void),
    maximum_clique: *[][]const u8,
    remaining: [][]const u8,
) void {
    if (current_clique.count() > maximum_clique.*.len) {
        allocator.free(maximum_clique.*);
        maximum_clique.* = allocator.dupe([]const u8, current_clique.keys()) catch unreachable;
    }

    for (remaining, 1..) |neighbor, r| {
        var isClique = true;
        for (current_clique.keys()) |member| {
            if (!edges.get(member).?.contains(neighbor)) {
                isClique = false;
                break;
            }
        }
        if (isClique) {
            current_clique.put(neighbor, {}) catch unreachable;
            findMaximumCliqueRecursive(allocator, edges, current_clique, maximum_clique, remaining[r..]);
        }

        _ = current_clique.orderedRemove(neighbor);
    }
}

fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(7, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    // co,de,ka,ta
    try std.testing.expectEqual(0, result);
}

const sample_1: []const u8 =
    \\kh-tc
    \\qp-kh
    \\de-cg
    \\ka-co
    \\yn-aq
    \\qp-ub
    \\cg-tb
    \\vc-aq
    \\tb-ka
    \\wh-tc
    \\yn-cg
    \\kh-ub
    \\ta-co
    \\de-co
    \\tc-td
    \\tb-wq
    \\wh-td
    \\ta-ka
    \\td-qp
    \\aq-cg
    \\wq-ub
    \\ub-vc
    \\de-ta
    \\wq-aq
    \\wq-vc
    \\wh-yn
    \\ka-de
    \\kh-ta
    \\co-tc
    \\wh-qp
    \\tb-vc
    \\td-yn
    \\
;
