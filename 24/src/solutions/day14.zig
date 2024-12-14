const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

// For debug only stuff
const builtin = @import("builtin");
const dbg = builtin.mode == .Debug;

const util = @import("util");
const grid = util.grid;
const Solution = @import("./solution.zig");

// interface
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day 14: Restroom Redoubt";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    return getRobotSecurityFactor(allocator, input, 101, 103, 100);
}

pub fn getRobotSecurityFactor(allocator: Allocator, input: []const u8, width: u32, height: u32, seconds: u32) ?u64 {
    var robots = std.ArrayList(Robot).init(allocator);
    defer robots.deinit();

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        var num_iterator = mem.tokenizeAny(u8, line, "p=,v ");
        const r = Robot{
            .p = grid.Vec2{
                .x = std.fmt.parseInt(i64, num_iterator.next().?, 10) catch unreachable,
                .y = std.fmt.parseInt(i64, num_iterator.next().?, 10) catch unreachable,
            },
            .v = grid.Vec2{
                .x = std.fmt.parseInt(i64, num_iterator.next().?, 10) catch unreachable,
                .y = std.fmt.parseInt(i64, num_iterator.next().?, 10) catch unreachable,
            },
        };
        robots.append(r) catch unreachable;
    }

    var quadrant_security: [4]u64 = .{ 0, 0, 0, 0 };
    const v_delimiter = width / 2;
    const h_delimiter = height / 2;
    for (robots.items) |*robot| {
        robot.translate(width, height, seconds);
        quadrant_security[0] += if (robot.p.x < v_delimiter and robot.p.y < h_delimiter) 1 else 0;
        quadrant_security[1] += if (robot.p.x > v_delimiter and robot.p.y < h_delimiter) 1 else 0;
        quadrant_security[2] += if (robot.p.x > v_delimiter and robot.p.y > h_delimiter) 1 else 0;
        quadrant_security[3] += if (robot.p.x < v_delimiter and robot.p.y > h_delimiter) 1 else 0;
    }
    const safety_factor = quadrant_security[0] * quadrant_security[1] * quadrant_security[2] * quadrant_security[3];

    return safety_factor;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var robots = std.ArrayList(Robot).init(allocator);
    defer robots.deinit();

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        var num_iterator = mem.tokenizeAny(u8, line, "p=,v ");
        const r = Robot{
            .p = grid.Vec2{
                .x = std.fmt.parseInt(i64, num_iterator.next().?, 10) catch unreachable,
                .y = std.fmt.parseInt(i64, num_iterator.next().?, 10) catch unreachable,
            },
            .v = grid.Vec2{
                .x = std.fmt.parseInt(i64, num_iterator.next().?, 10) catch unreachable,
                .y = std.fmt.parseInt(i64, num_iterator.next().?, 10) catch unreachable,
            },
        };
        robots.append(r) catch unreachable;
    }

    const width = 101;
    const height = 103;

    var index: usize = 0;
    while (!containsVerticalOf(allocator, robots.items, 16)) {
        for (robots.items) |*robot| {
            robot.translate(width, height, 1);
        }
        index += 1;
    }

    var map = grid.ByteGrid.init(allocator, width, height, '.');
    defer map.deinit();
    for (robots.items) |robot| {
        map.set(robot.p, 'X');
    }
    if (dbg) {
        map.printRect(grid.Vec2{ .x = 2, .y = 2 }, grid.Vec2{ .x = width - 2, .y = height - 2 });
    }
    return index;
}

fn containsVerticalOf(allocator: Allocator, robots: []Robot, len: u32) bool {
    var map = std.AutoHashMap(grid.Vec2, void).init(allocator);
    defer map.deinit();
    map.ensureTotalCapacity(500) catch unreachable;

    for (robots) |robot| {
        map.putAssumeCapacity(robot.p, {});
    }
    for (robots) |robot| {
        var pos = robot.p;
        var index: u32 = 0;
        while (map.contains(pos)) {
            if (index == len) return true;
            pos = pos.translate(grid.S);
            index += 1;
        }
    }
    return false;
}

const Robot = struct {
    p: grid.Vec2,
    v: grid.Vec2,

    pub fn translate(self: *Robot, boundary_width: u32, boundary_height: u32, times: i64) void {
        var n = self.p.translate(self.v.times(times));
        n.x = @mod(@mod(n.x, boundary_width) + boundary_width, boundary_width);
        n.y = @mod(@mod(n.y, boundary_height) + boundary_height, boundary_height);
        self.p = n;
    }
};

test "part_1.sample_1" {
    const result = getRobotSecurityFactor(std.testing.allocator, sample_1, 11, 7, 100) orelse return error.SkipZigTest;
    try std.testing.expectEqual(12, result);
}

const sample_1: []const u8 =
    \\p=0,4 v=3,-3
    \\p=6,3 v=-1,-3
    \\p=10,3 v=-1,2
    \\p=2,0 v=2,-1
    \\p=0,0 v=1,3
    \\p=3,0 v=-2,-2
    \\p=7,6 v=-1,-3
    \\p=3,0 v=-1,-2
    \\p=9,3 v=2,3
    \\p=7,3 v=-1,2
    \\p=2,4 v=2,-3
    \\p=9,5 v=-3,-3
    \\
;
