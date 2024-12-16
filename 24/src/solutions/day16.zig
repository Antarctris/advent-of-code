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
    return "Day 16: Reindeer Maze";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var maze = grid.ByteGrid.parse(allocator, input);
    defer maze.deinit();

    var visited = std.AutoHashMap(Node, u64).init(allocator);
    defer visited.deinit();

    var queue = std.PriorityQueue(WeightedNode, void, orderNodes).init(allocator, {});
    defer queue.deinit();

    const startPosition = Node{ .p = maze.locationOfScalar('S').?, .d = 1 };
    queue.add(WeightedNode{ .n = startPosition, .w = 0 }) catch unreachable;
    visited.put(startPosition, 0) catch unreachable;

    while (queue.removeOrNull()) |w_node| {
        const next = WeightedNode{ .n = Node{ .p = w_node.n.p.translate(grid.CardinalDirections[w_node.n.d]), .d = w_node.n.d }, .w = w_node.w + 1 };
        if (maze.get(next.n.p).? == 'E') {
            return next.w;
        }
        if (maze.get(next.n.p).? != '#' and (visited.get(next.n) == null or next.w < visited.get(next.n).?)) {
            visited.put(next.n, next.w) catch unreachable;
            queue.add(next) catch unreachable;
        }
        const rotRight = WeightedNode{ .n = Node{ .p = w_node.n.p, .d = w_node.n.d +% 1 }, .w = w_node.w + 1000 };
        if (visited.get(rotRight.n) == null or rotRight.w < visited.get(rotRight.n).?) {
            visited.put(rotRight.n, rotRight.w) catch unreachable;
            queue.add(rotRight) catch unreachable;
        }
        const rotLeft = WeightedNode{ .n = Node{ .p = w_node.n.p, .d = w_node.n.d +% 3 }, .w = w_node.w + 1000 };
        if (visited.get(rotLeft.n) == null or rotLeft.w < visited.get(rotLeft.n).?) {
            visited.put(rotLeft.n, rotLeft.w) catch unreachable;
            queue.add(rotLeft) catch unreachable;
        }
    }

    return null;
}

fn orderNodes(ctx: void, a: WeightedNode, b: WeightedNode) std.math.Order {
    _ = ctx;
    return std.math.order(a.w, b.w);
}

const Node = struct {
    p: grid.Vec2,
    d: u2,
};

const WeightedNode = struct {
    n: Node,
    w: u64,
};

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var maze = grid.ByteGrid.parse(allocator, input);
    defer maze.deinit();

    var visited = std.AutoHashMap(Node, NodeWeight).init(allocator);
    defer visited.deinit();

    var queue = std.PriorityQueue(WeightedNode, void, orderNodes).init(allocator, {});
    defer queue.deinit();

    const startPosition = Node{ .p = maze.locationOfScalar('S').?, .d = 1 };
    queue.add(WeightedNode{ .n = startPosition, .w = 0 }) catch unreachable;
    visited.put(startPosition, NodeWeight{ .w = 0 }) catch unreachable;

    var shortest_route: u64 = std.math.maxInt(u64);
    var endPositions = std.AutoArrayHashMap(Node, void).init(allocator);
    defer endPositions.deinit();

    while (queue.removeOrNull()) |w_node| {
        if (w_node.w > shortest_route) break;
        if (maze.get(w_node.n.p).? == 'E') {
            shortest_route = w_node.w;
            endPositions.put(w_node.n, {}) catch unreachable;
        }
        const forward = WeightedNode{ .n = Node{ .p = w_node.n.p.translate(grid.CardinalDirections[w_node.n.d]), .d = w_node.n.d }, .w = w_node.w + 1 };
        const rotRight = WeightedNode{ .n = Node{ .p = w_node.n.p, .d = w_node.n.d +% 1 }, .w = w_node.w + 1000 };
        const rotLeft = WeightedNode{ .n = Node{ .p = w_node.n.p, .d = w_node.n.d +% 3 }, .w = w_node.w + 1000 };
        const moves: [3]WeightedNode = .{ forward, rotLeft, rotRight };
        for (moves) |next| {
            if (maze.get(next.n.p).? == '#') continue;
            if (visited.get(next.n) == null or next.w < visited.get(next.n).?.w) {
                var nodeweight = NodeWeight{ .w = next.w };
                nodeweight.addNode(w_node.n);
                visited.put(next.n, nodeweight) catch unreachable;
                queue.add(next) catch unreachable;
            }
            if (visited.get(next.n) != null and next.w == visited.get(next.n).?.w) {
                var nw: NodeWeight = visited.get(next.n).?;
                nw.addNode(w_node.n);
                visited.putAssumeCapacity(next.n, nw);
            }
        }
    }
    var bestSpots = std.AutoHashMap(grid.Vec2, void).init(allocator);
    defer bestSpots.deinit();

    while (endPositions.popOrNull()) |node| {
        bestSpots.put(node.key.p, {}) catch unreachable;
        for (0..visited.get(node.key).?.prev_len) |i| {
            endPositions.put(visited.get(node.key).?.prev[i], {}) catch unreachable;
        }
    }

    return bestSpots.count();
}

const NodeWeight = struct {
    w: u64,
    prev_len: usize = 0,
    prev: [6]Node = undefined,

    pub fn addNode(self: *NodeWeight, node: Node) void {
        self.prev[self.prev_len] = node;
        self.prev_len += 1;
    }
};

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(11048, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(64, result);
}

const sample_1: []const u8 =
    \\#################
    \\#...#...#...#..E#
    \\#.#.#.#.#.#.#.#.#
    \\#.#.#.#...#...#.#
    \\#.#.#.#.###.#.#.#
    \\#...#.#.#.....#.#
    \\#.#.#.#.#.#####.#
    \\#.#...#.#.#.....#
    \\#.#.#####.#.###.#
    \\#.#.#.......#...#
    \\#.#.###.#####.###
    \\#.#.#...#.....#.#
    \\#.#.#.#####.###.#
    \\#.#.#.........#.#
    \\#.#.#.#########.#
    \\#S#.............#
    \\#################
    \\
;
