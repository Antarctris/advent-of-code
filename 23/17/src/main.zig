const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const util = @import("util");
const grid = util.grid;

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

pub fn digitToValue(c: u8) u8 {
    return c - '0';
}

pub fn solveChallenge(allocator: Allocator, input: []const u8) [2]u64 {
    var map = grid.ByteGrid.parse(allocator, input);
    defer map.deinit();
    map.mutateBytes(digitToValue);

    const leastHeatLoss = getLeastHeatLoss(allocator, map, 0, 3);
    const leastHeatLossUltra = getLeastHeatLoss(allocator, map, 4, 10);

    return .{ leastHeatLoss, leastHeatLossUltra };
}

pub fn getLeastHeatLoss(allocator: Allocator, map: grid.ByteGrid, comptime travel_min: u8, comptime travel_max: u8) u64 {
    var weights = std.AutoHashMap(u64, void).init(allocator);
    weights.ensureUnusedCapacity(50000) catch unreachable;
    defer weights.deinit();
    var queue = std.PriorityQueue(Node, void, orderNodes).init(allocator, {});
    queue.ensureUnusedCapacity(10000) catch unreachable;
    defer queue.deinit();

    const origin0 = Node{ .location = grid.Vec2.Zero, .weight = 0, .direction = 1, .travelled = 0 };
    const origin1 = Node{ .location = grid.Vec2.Zero, .weight = 0, .direction = 2, .travelled = 0 };

    weights.put(hash(origin0), {}) catch unreachable;
    weights.put(hash(origin1), {}) catch unreachable;

    queue.add(origin0) catch unreachable;
    queue.add(origin1) catch unreachable;

    while (queue.removeOrNull()) |node| {
        if (node.location.x == map.width - 1 and node.location.y == map.height - 1) {
            if (node.travelled < travel_min) continue;
            return node.weight;
        }

        const directions: [3]u2 = .{ node.direction, node.direction +% 3, node.direction +% 1 };
        for (directions) |d| {
            const next_location = node.location.translate(grid.CardinalDirections[d]);

            if (!map.isInBounds(next_location)) continue;
            if (d == node.direction and node.travelled == travel_max) continue;
            if (d != node.direction and node.travelled < travel_min) continue;

            const next = Node{
                .location = next_location,
                .weight = node.weight + map.get(next_location).?,
                .direction = d,
                .travelled = if (d == node.direction) node.travelled + 1 else 1,
            };
            if (!weights.contains(hash(next))) {
                weights.put(hash(next), {}) catch unreachable;
                queue.add(next) catch unreachable;
            }
        }
    }
    return std.math.maxInt(u64);
}

const Node = struct {
    location: grid.Vec2,
    weight: u32,
    direction: u2,
    travelled: u8,
};

fn hash(node: Node) u64 {
    const x: u8 = @intCast(node.location.x);
    const y: u8 = @intCast(node.location.y);
    return (((((((@as(u64, x) << 8) + y) << 32) + node.weight) << 2) + node.direction) << 8) + node.travelled;
}

fn orderNodes(context: void, a: Node, b: Node) std.math.Order {
    _ = context;
    return std.math.order(a.weight, b.weight);
}

const sample_1: []const u8 =
    \\2413432311323
    \\3215453535623
    \\3255245654254
    \\3446585845452
    \\4546657867536
    \\1438598798454
    \\4457876987766
    \\3637877979653
    \\4654967986887
    \\4564679986453
    \\1224686865563
    \\2546548887735
    \\4322674655533
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(102, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(94, solution[1]);
}
