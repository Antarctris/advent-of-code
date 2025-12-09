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
    return "Day 9: Movie Theater";
}

pub fn part_one(allocator: Allocator, input: []const u8) !Solution.Result {
    const red_tile_count = std.mem.count(u8, input, "\n");
    var red_tiles = try std.ArrayList(Vec2).initCapacity(allocator, red_tile_count);
    defer red_tiles.deinit(allocator);

    var max_rect: u64 = 0;

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        const current = try Vec2Utils.parseStringScalar(line, ',');
        for (red_tiles.items) |other| {
            max_rect = @max(max_rect, @reduce(.Mul, @abs(other - current) + @Vector(2, u64){ 1, 1 }));
        }
        red_tiles.appendAssumeCapacity(current);
    }

    return Solution.Result.number(max_rect);
}

pub fn part_two(allocator: Allocator, input: []const u8) !Solution.Result {
    const red_tile_count = std.mem.count(u8, input, "\n");
    var red_tiles = try std.ArrayList(Vec2).initCapacity(allocator, red_tile_count);
    defer red_tiles.deinit(allocator);

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        const current = try Vec2Utils.parseStringScalar(line, ',');
        red_tiles.appendAssumeCapacity(current);
    }

    var max_rect: u64 = 0;

    var memo = std.AutoHashMap(Vec2, bool).init(allocator);
    defer memo.deinit();

    for (0..red_tiles.items.len) |ta| {
        for (ta..red_tiles.items.len) |tb| {
            if (try rectContainedInPolygon(allocator, &memo, red_tiles.items, red_tiles.items[ta], red_tiles.items[tb])) {
                max_rect = @max(max_rect, @reduce(.Mul, @abs(red_tiles.items[tb] - red_tiles.items[ta]) + @Vector(2, u64){ 1, 1 }));
            }
        }
    }

    return Solution.Result.number(max_rect);
}

fn rectContainedInPolygon(allocator: Allocator, memo: *std.AutoHashMap(Vec2, bool), polygon: []Vec2, a: Vec2, o: Vec2) !bool {
    const min = @min(a, o);
    const max = @max(a, o);
    const edge: bool = @reduce(.Xor, a == o);

    var bounding_box = try std.ArrayList(Vec2).initCapacity(allocator, @as(usize, @intCast(@reduce(.Add, max - min))));
    defer bounding_box.deinit(allocator);
    try bounding_box.append(allocator, Vec2{ a[0], o[1] });
    try bounding_box.append(allocator, Vec2{ o[0], a[1] });

    var y = min[1] + 1;
    while (y < max[1]) : (y += 1) {
        try bounding_box.append(allocator, Vec2{ a[0], y });
        if (edge) continue;
        try bounding_box.append(allocator, Vec2{ o[0], y });
    }
    var x = min[0] + 1;
    while (x < max[0]) : (x += 1) {
        try bounding_box.append(allocator, Vec2{ x, a[1] });
        if (edge) continue;
        try bounding_box.append(allocator, Vec2{ x, o[1] });
    }

    bounding_loop: for (bounding_box.items) |v| {
        if (memo.get(v)) |m| {
            if (m) continue;
            return false;
        }
        var intersections: u64 = 0;
        for (0..polygon.len) |pi| {
            const pa = polygon[pi];
            const pb = polygon[@mod(pi + 1, polygon.len)];

            // If corner is exactly on the edge, continue outer loop
            if ((pa[0] == pb[0] and pa[0] == v[0] and v[1] >= @min(pa[1], pb[1]) and v[1] <= @max(pa[1], pb[1])) or
                (pa[1] == pb[1] and pa[1] == v[1] and v[0] >= @min(pa[0], pb[0]) and v[0] <= @max(pa[0], pb[0])))
            {
                try memo.put(v, true);
                continue :bounding_loop;
            }
            // Check for intersections in positive y direction
            // intersection with horizontal edge
            if (pa[1] == pb[1] and pa[1] > v[1] and v[0] >= @min(pa[0], pb[0]) and v[0] <= @max(pa[0], pb[0])) {
                intersections += 1;
            }
            // interscetion with vertical edge
            // needs to check surrounding edges to determine if it intersects or not
            if (pa[0] == pb[0] and pa[0] == v[0] and @min(pa[1], pb[1]) > v[1]) {
                const p0 = polygon[@mod(pi + polygon.len - 1, polygon.len)];
                const p3 = polygon[@mod(pi + 2, polygon.len)];
                if ((p0[0] > pa[0] and p3[0] < pa[0]) or (p0[0] < pa[0] and p3[0] > pa[0])) {
                    intersections += 1;
                }
            }
        }
        try memo.put(v, @mod(intersections, 2) != 0);
        if (@mod(intersections, 2) == 0) return false;
    }
    return true;
}

const Vec2 = @Vector(2, i64);
const Vec2Utils = util.math.VectorExtension(Vec2);

test "part_1.sample_1" {
    var result = try part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(50, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = try part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(24, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\7,1
    \\11,1
    \\11,7
    \\9,7
    \\9,5
    \\2,5
    \\2,3
    \\7,3
    \\
;
