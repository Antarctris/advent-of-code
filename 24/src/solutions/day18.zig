const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

// For debug only stuff
const builtin = @import("builtin");
const dbg = builtin.mode == .Debug;

const util = @import("util");
const graph = util.graph;
const grid = util.grid;
const Solution = @import("./solution.zig");

// interface
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day 18: RAM Run";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    const result = ram_run(allocator, input, 71, 1024);
    return result;
}

pub fn ram_run(allocator: Allocator, input: []const u8, size: u64, bytelimit: ?u64) ?u64 {
    var corrupted_memory = std.AutoHashMap(grid.Vec2, void).init(allocator);
    defer corrupted_memory.deinit();

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        if (bytelimit != null and corrupted_memory.count() >= bytelimit.?) break;
        var coordinate_iterator = mem.tokenizeScalar(u8, line, ',');
        corrupted_memory.put(grid.Vec2{
            .x = std.fmt.parseInt(i64, coordinate_iterator.next().?, 10) catch unreachable,
            .y = std.fmt.parseInt(i64, coordinate_iterator.next().?, 10) catch unreachable,
        }, {}) catch unreachable;
    }

    var memory_graph = graph
        .Graph(grid.Vec2, Memory, traverse_buf_size, traverseMemory, isEnd)
        .init(allocator, Memory{ .space = size, .corrupted = corrupted_memory });
    defer memory_graph.deinit();

    const result = memory_graph.dijkstra(allocator, .cost, &.{grid.Vec2{ .x = 0, .y = 0 }}) catch unreachable;

    return result.cost;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    const size: u64 = 71;
    var corrupted_memory = std.AutoHashMap(grid.Vec2, void).init(allocator);
    defer corrupted_memory.deinit();

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        var coordinate_iterator = mem.tokenizeScalar(u8, line, ',');
        corrupted_memory.put(grid.Vec2{
            .x = std.fmt.parseInt(i64, coordinate_iterator.next().?, 10) catch unreachable,
            .y = std.fmt.parseInt(i64, coordinate_iterator.next().?, 10) catch unreachable,
        }, {}) catch unreachable;
        if (corrupted_memory.count() >= 1024) break;
    }

    var last: grid.Vec2 = undefined;
    var path: u64 = 0;
    while (path != std.math.maxInt(u64)) {
        const line = line_iterator.next().?;
        var coordinate_iterator = mem.tokenizeScalar(u8, line, ',');
        last = grid.Vec2{
            .x = std.fmt.parseInt(i64, coordinate_iterator.next().?, 10) catch unreachable,
            .y = std.fmt.parseInt(i64, coordinate_iterator.next().?, 10) catch unreachable,
        };
        corrupted_memory.put(last, {}) catch unreachable;

        var memory_graph = graph
            .Graph(grid.Vec2, Memory, traverse_buf_size, traverseMemory, isEnd)
            .init(allocator, Memory{ .space = size, .corrupted = corrupted_memory });
        defer memory_graph.deinit();
        const result = memory_graph.dijkstra(allocator, .cost, &.{grid.Vec2{ .x = 0, .y = 0 }}) catch unreachable;

        path = result.cost;
    }

    if (dbg) std.debug.print("{d},{d}\n", .{ last.x, last.y });

    return 0;
}

const Memory = struct {
    space: u64,
    corrupted: std.AutoHashMap(grid.Vec2, void),

    fn isInBounds(self: Memory, v: grid.Vec2) bool {
        return v.x >= 0 and v.y >= 0 and v.x < self.space and v.y < self.space;
    }
};

const traverse_buf_size: usize = 4;

fn traverseMemory(memory: Memory, buf: []struct { grid.Vec2, u64 }, a: grid.Vec2) []struct { grid.Vec2, u64 } {
    var i: usize = 0;
    for (grid.CardinalDirections) |d| {
        const n = a.translate(d);
        if (memory.isInBounds(n) and !memory.corrupted.contains(n)) {
            buf[i] = .{ n, 1 };
            i += 1;
        }
    }
    return buf[0..i];
}

fn isEnd(context: Memory, a: grid.Vec2) bool {
    return a.x == context.space - 1 and a.y == context.space - 1;
}

test "part_1.sample_1" {
    const result = ram_run(std.testing.allocator, sample_1, 7, 12) orelse return error.SkipZigTest;
    try std.testing.expectEqual(22, result);
}

const sample_1: []const u8 =
    \\5,4
    \\4,2
    \\4,5
    \\3,0
    \\2,1
    \\6,3
    \\2,4
    \\1,5
    \\0,6
    \\3,3
    \\2,6
    \\5,1
    \\1,2
    \\5,5
    \\2,5
    \\6,5
    \\1,4
    \\0,4
    \\6,4
    \\1,1
    \\6,1
    \\1,0
    \\0,5
    \\1,6
    \\2,0
    \\
;
