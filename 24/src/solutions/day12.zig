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
    return "Day 12: Garden Groups";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    return calculatePerimeterPrice(allocator, input, countEdges);
}

fn countEdges(allocator: Allocator, edges: std.AutoHashMap(Edge, void)) u64 {
    _ = allocator;
    return edges.count();
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    return calculatePerimeterPrice(allocator, input, countEdgesDiscount);
}

fn countEdgesDiscount(allocator: Allocator, edges: std.AutoHashMap(Edge, void)) u64 {
    var ordered = std.PriorityQueue(Edge, void, edgeOrder).init(allocator, {});
    defer ordered.deinit();
    ordered.ensureTotalCapacity(edges.count()) catch unreachable;

    var edge_iterator = edges.keyIterator();
    while (edge_iterator.next()) |edge| {
        ordered.add(edge.*) catch unreachable;
    }

    if (ordered.count() > 0) {
        var count: u64 = 1;
        var last: Edge = ordered.remove();
        while (ordered.removeOrNull()) |current| {
            if (last.direction != current.direction or
                last.node.manhattanDistance(current.node) > 1)
            {
                count += 1;
            }
            last = current;
        }

        return count;
    }
    return 0;
}

fn calculatePerimeterPrice(allocator: Allocator, input: []const u8, count: *const fn (allocator: Allocator, std.AutoHashMap(Edge, void)) u64) ?u64 {
    var map = grid.ByteGrid.parse(allocator, input);
    defer map.deinit();

    var regions = std.ArrayList(Region).init(allocator);
    defer regions.deinit();
    defer for (0..regions.items.len) |i| regions.items[i].deinit();

    var done = std.AutoHashMap(grid.Vec2, void).init(allocator);
    defer done.deinit();

    var workload_extern = std.AutoArrayHashMap(grid.Vec2, void).init(allocator);
    defer workload_extern.deinit();
    workload_extern.put(grid.Vec2.Zero, {}) catch unreachable;

    while (workload_extern.popOrNull()) |origin| {
        var region = Region.init(allocator);
        region.crop = map.get(origin.key).?;

        var workload_region = std.AutoArrayHashMap(grid.Vec2, void).init(allocator);
        defer workload_region.deinit();
        workload_region.put(origin.key, {}) catch unreachable;

        while (workload_region.popOrNull()) |node_kv| {
            const node = node_kv.key;
            _ = workload_extern.swapRemove(node);
            done.put(node, {}) catch unreachable;
            region.contained.put(node, {}) catch unreachable;
            for (0..4) |direction| {
                const next = node.translate(grid.CardinalDirections[direction]);
                if (map.get(next) == null or map.get(next).? != region.crop) {
                    region.edges.put(Edge{ .node = node, .direction = @intCast(direction) }, {}) catch unreachable;
                    if (!map.isInBounds(next) or done.contains(next)) continue;
                    workload_extern.put(next, {}) catch unreachable;
                } else {
                    if (done.contains(next)) continue;
                    workload_region.put(next, {}) catch unreachable;
                }
            }
        }

        regions.append(region) catch unreachable;
    }
    var perimeter_prices: u64 = 0;
    for (regions.items) |region| {
        perimeter_prices += region.contained.count() * count(allocator, region.edges);
    }

    return perimeter_prices;
}

const Region = struct {
    allocator: Allocator,
    contained: std.AutoHashMap(grid.Vec2, void),
    edges: std.AutoHashMap(Edge, void),
    crop: u8,

    pub fn init(allocator: Allocator) Region {
        return .{
            .allocator = allocator,
            .contained = std.AutoHashMap(grid.Vec2, void).init(allocator),
            .edges = std.AutoHashMap(Edge, void).init(allocator),
            .crop = 0,
        };
    }

    pub fn deinit(self: *Region) void {
        self.contained.deinit();
        self.edges.deinit();
    }
};

const Edge = struct {
    node: grid.Vec2,
    direction: u2,
};

fn edgeOrder(ctx: void, a: Edge, b: Edge) std.math.Order {
    _ = ctx;
    if (a.direction != b.direction)
        return std.math.order(a.direction, b.direction);
    if (a.direction % 2 == 0) {
        if (a.node.y != b.node.y) {
            return std.math.order(a.node.y, b.node.y);
        } else {
            return std.math.order(a.node.x, b.node.x);
        }
    } else {
        if (a.node.x != b.node.x) {
            return std.math.order(a.node.x, b.node.x);
        } else {
            return std.math.order(a.node.y, b.node.y);
        }
    }
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(1930, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(1206, result);
}

const sample_1: []const u8 =
    \\RRRRIICCFF
    \\RRRRIICCCF
    \\VVRRRCCFFF
    \\VVRCCCJFFF
    \\VVVVCJJCFE
    \\VVIVCCJJEE
    \\VVIIICJJEE
    \\MIIIIIJJEE
    \\MIIISIJEEE
    \\MMMISSJEEE
    \\
;
