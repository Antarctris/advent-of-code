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
    return "Day 8: Playground";
}

pub fn part_one(allocator: Allocator, input: []const u8) !Solution.Result {
    return try part_one_p(allocator, input, 1000);
}

pub fn part_one_p(allocator: Allocator, input: []const u8, comptime n: usize) !Solution.Result {
    const coordinate_count = mem.count(u8, input, "\n");
    var coordinates = try std.ArrayList(Vec3).initCapacity(allocator, coordinate_count);
    defer coordinates.deinit(allocator);

    var distances = std.PriorityQueue(Vec3Distance, void, distanceOrder).init(allocator, {});
    defer distances.deinit();
    try distances.ensureTotalCapacity(util.math.sumTo(usize, coordinate_count));

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        const current = try Vec3.fromStringScalar(line, ',');
        for (coordinates.items) |other| {
            try distances.add(Vec3Distance.from(current, other));
        }
        try coordinates.append(allocator, current);
    }

    var circuits = try std.ArrayList(std.ArrayList(Vec3)).initCapacity(allocator, 64);
    defer {
        for (circuits.items) |*list| {
            list.*.deinit(allocator);
        }
        circuits.deinit(allocator);
    }

    for (0..@min(distances.count(), n)) |_| {
        if (distances.removeOrNull()) |shortest| {
            var a_list: ?usize = null;
            for (0..circuits.items.len) |i| {
                if (shortest.a.isInList(circuits.items[i].items)) {
                    a_list = i;
                    break;
                }
            }
            var b_list: ?usize = null;
            for (0..circuits.items.len) |i| {
                if (shortest.b.isInList(circuits.items[i].items)) {
                    b_list = i;
                    break;
                }
            }
            if (a_list != null and b_list != null) {
                if (a_list != b_list) {
                    try circuits.items[a_list.?].appendSlice(allocator, circuits.items[b_list.?].items);
                    circuits.items[b_list.?].deinit(allocator);
                    _ = circuits.swapRemove(b_list.?);
                }
            } else if (a_list) |ai| {
                try circuits.items[ai].append(allocator, shortest.b);
            } else if (b_list) |bi| {
                try circuits.items[bi].append(allocator, shortest.a);
            } else {
                var new_circuit = try std.ArrayList(Vec3).initCapacity(allocator, 32);
                new_circuit.appendAssumeCapacity(shortest.a);
                new_circuit.appendAssumeCapacity(shortest.b);
                try circuits.append(allocator, new_circuit);
            }
        }
    }

    var groups: []u64 = try allocator.alloc(u64, circuits.items.len);
    defer allocator.free(groups);
    for (circuits.items, 0..) |c, i| {
        groups[i] = c.items.len;
    }
    mem.sort(usize, groups, {}, std.sort.desc(usize));
    const product = groups[0] * groups[1] * groups[2];

    return Solution.Result.number(product);
}

pub fn part_two(allocator: Allocator, input: []const u8) !Solution.Result {
    const coordinate_count = mem.count(u8, input, "\n");
    var coordinates = try std.ArrayList(Vec3).initCapacity(allocator, coordinate_count);
    defer coordinates.deinit(allocator);

    var distances = std.PriorityQueue(Vec3Distance, void, distanceOrder).init(allocator, {});
    defer distances.deinit();
    try distances.ensureTotalCapacity(util.math.sumTo(usize, coordinate_count));

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        const current = try Vec3.fromStringScalar(line, ',');
        for (coordinates.items) |other| {
            try distances.add(Vec3Distance.from(current, other));
        }
        try coordinates.append(allocator, current);
    }

    var circuits = try std.ArrayList(std.ArrayList(Vec3)).initCapacity(allocator, 64);
    defer {
        for (circuits.items) |*list| {
            list.*.deinit(allocator);
        }
        circuits.deinit(allocator);
    }

    var last_link: ?Vec3Distance = null;
    while (distances.removeOrNull()) |shortest| {
        var a_list: ?usize = null;
        for (0..circuits.items.len) |i| {
            if (shortest.a.isInList(circuits.items[i].items)) {
                a_list = i;
                break;
            }
        }
        var b_list: ?usize = null;
        for (0..circuits.items.len) |i| {
            if (shortest.b.isInList(circuits.items[i].items)) {
                b_list = i;
                break;
            }
        }
        if (a_list != null and b_list != null) {
            if (a_list != b_list) {
                try circuits.items[a_list.?].appendSlice(allocator, circuits.items[b_list.?].items);
                circuits.items[b_list.?].deinit(allocator);
                _ = circuits.swapRemove(b_list.?);
            }
        } else if (a_list) |ai| {
            try circuits.items[ai].append(allocator, shortest.b);
        } else if (b_list) |bi| {
            try circuits.items[bi].append(allocator, shortest.a);
        } else {
            var new_circuit = try std.ArrayList(Vec3).initCapacity(allocator, 32);
            new_circuit.appendAssumeCapacity(shortest.a);
            new_circuit.appendAssumeCapacity(shortest.b);
            try circuits.append(allocator, new_circuit);
        }
        if (circuits.items.len == 1 and circuits.items[0].items.len == coordinate_count) {
            last_link = shortest;
            break;
        }
    }

    const result: u64 = @intCast(last_link.?.a.x * last_link.?.b.x);

    return Solution.Result.number(result);
}

const Vec3 = struct {
    x: i64,
    y: i64,
    z: i64,

    pub fn fromStringScalar(str: []const u8, scalar: u8) !Vec3 {
        var str_iterator = std.mem.splitScalar(u8, str, scalar);
        return Vec3{
            .x = try std.fmt.parseInt(i64, str_iterator.next().?, 10),
            .y = try std.fmt.parseInt(i64, str_iterator.next().?, 10),
            .z = try std.fmt.parseInt(i64, str_iterator.next().?, 10),
        };
    }

    pub fn equals(self: Vec3, other: Vec3) bool {
        return (self.x == other.x and self.y == other.y and self.z == other.z);
    }

    pub fn isInList(self: Vec3, list: []const Vec3) bool {
        for (list) |other| {
            if (self.equals(other)) return true;
        }
        return false;
    }

    pub fn euclideanDistance(self: Vec3, other: Vec3) f64 {
        const a: f64 = @floatFromInt(self.x - other.x);
        const b: f64 = @floatFromInt(self.y - other.y);
        const c: f64 = @floatFromInt(self.z - other.z);
        const product_sum = a * a + b * b + c * c;
        return product_sum; // Comparison already works with only this, no need for cbrt
        //return std.math.cbrt(product_sum);
    }
};

const Vec3Distance = struct {
    d: f64,
    a: Vec3,
    b: Vec3,

    pub fn from(a: Vec3, b: Vec3) Vec3Distance {
        return Vec3Distance{
            .d = a.euclideanDistance(b),
            .a = a,
            .b = b,
        };
    }
};

fn distanceOrder(ctx: void, a: Vec3Distance, b: Vec3Distance) std.math.Order {
    _ = ctx;
    return std.math.order(a.d, b.d);
}

test "part_1.sample_1" {
    var result = try part_one_p(std.testing.allocator, sample_1, 10);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(40, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = try part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(25272, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\162,817,812
    \\57,618,57
    \\906,360,560
    \\592,479,940
    \\352,342,300
    \\466,668,158
    \\542,29,236
    \\431,825,988
    \\739,650,466
    \\52,470,668
    \\216,146,977
    \\819,987,18
    \\117,168,530
    \\805,96,715
    \\346,949,466
    \\970,615,88
    \\941,993,340
    \\862,61,35
    \\984,92,344
    \\425,690,689
    \\
;
