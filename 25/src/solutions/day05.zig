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
    return "Day 5: Cafeteria";
}

pub fn part_one(allocator: Allocator, input: []const u8) Solution.Result {
    var line_iterator = mem.splitScalar(u8, input, '\n');

    var ranges = std.ArrayList(Range).initCapacity(allocator, 1000) catch unreachable;
    defer ranges.deinit(allocator);
    while (line_iterator.next()) |line| {
        if (line.len == 0) break;
        var line_split = mem.splitScalar(u8, line, '-');
        ranges.append(allocator, .{
            .a = std.fmt.parseInt(u64, line_split.next() orelse unreachable, 10) catch unreachable,
            .b = std.fmt.parseInt(u64, line_split.next() orelse unreachable, 10) catch unreachable,
        }) catch unreachable;
    }

    var fresh_ids: u64 = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const n = std.fmt.parseInt(u64, line, 10) catch unreachable;

        for (ranges.items) |range| {
            if (range.contains(n)) {
                fresh_ids += 1;
                break;
            }
        }
    }
    return Solution.Result.number(fresh_ids);
}

pub fn part_two(allocator: Allocator, input: []const u8) Solution.Result {
    var line_iterator = mem.splitScalar(u8, input, '\n');

    var ranges = std.ArrayList(Range).initCapacity(allocator, 200) catch unreachable;
    defer ranges.deinit(allocator);
    while (line_iterator.next()) |line| {
        if (line.len == 0) break;
        var line_split = mem.splitScalar(u8, line, '-');
        var current = Range{
            .a = std.fmt.parseInt(u64, line_split.next() orelse unreachable, 10) catch unreachable,
            .b = std.fmt.parseInt(u64, line_split.next() orelse unreachable, 10) catch unreachable,
        };
        while (current.intersectsAny(ranges.items)) |index| {
            current = current.merge(ranges.swapRemove(index));
        }
        ranges.append(allocator, current) catch unreachable;
    }

    var fresh_ids: u64 = 0;
    for (ranges.items) |range| {
        fresh_ids += range.count();
    }

    return Solution.Result.number(fresh_ids);
}

const Range = struct {
    a: u64,
    b: u64,

    pub fn count(self: Range) u64 {
        return 1 + self.b - self.a;
    }

    pub fn contains(self: Range, n: u64) bool {
        return (self.a <= n and n <= self.b);
    }

    pub fn intersects(self: Range, other: Range) bool {
        return self.contains(other.a) or self.contains(other.b) or other.contains(self.a) or other.contains(self.b);
    }

    pub fn intersectsAny(self: Range, list: []const Range) ?u64 {
        for (0..list.len) |i| {
            if (self.intersects(list[i])) {
                return i;
            }
        }
        return null;
    }

    pub fn merge(self: Range, other: Range) Range {
        return Range{
            .a = @min(self.a, other.a),
            .b = @max(self.b, other.b),
        };
    }
};

test "part_1.sample_1" {
    var result = part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(3, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(14, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\3-5
    \\10-14
    \\16-20
    \\12-18
    \\
    \\1
    \\5
    \\8
    \\11
    \\17
    \\32
    \\
;
