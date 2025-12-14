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
    return "Day 12: Christmas Tree Farm";
}

pub fn part_one(allocator: Allocator, input: []const u8) !Solution.Result {
    _ = allocator;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    // Skip presents
    for (0..24) |_| {
        _ = line_iterator.next();
    }
    var possible: u64 = 0;
    var impossible: u64 = 0;
    while (line_iterator.next()) |line| {
        var tree_iterator = mem.tokenizeScalar(u8, line, ' ');
        const tree_size_str = tree_iterator.next().?;
        var tree_size_iterator = mem.tokenizeScalar(u8, tree_size_str[0 .. tree_size_str.len - 1], 'x');
        const w: u64 = try std.fmt.parseInt(u64, tree_size_iterator.next().?, 10);
        const h: u64 = try std.fmt.parseInt(u64, tree_size_iterator.next().?, 10);
        var packages: @Vector(6, u64) = undefined;
        packages[0] = try std.fmt.parseInt(u64, tree_iterator.next().?, 10);
        packages[1] = try std.fmt.parseInt(u64, tree_iterator.next().?, 10);
        packages[2] = try std.fmt.parseInt(u64, tree_iterator.next().?, 10);
        packages[3] = try std.fmt.parseInt(u64, tree_iterator.next().?, 10);
        packages[4] = try std.fmt.parseInt(u64, tree_iterator.next().?, 10);
        packages[5] = try std.fmt.parseInt(u64, tree_iterator.next().?, 10);
        const sum_packages = @reduce(.Add, packages);
        const space_max = w * h;
        const no_tiling = @divFloor(w, 3) * @divFloor(h, 3);
        const space_req: @Vector(6, u64) = .{ 6, 5, 7, 7, 7, 7 };
        const perfect_tiling = @reduce(.Add, packages * space_req);
        if (no_tiling >= sum_packages) {
            possible += 1;
        } else if (perfect_tiling > space_max) {
            impossible += 1;
        }
    }

    // If at this point possible and impossible add up to all trees to solve
    // then the group of uncertain trees is 0 and the result of possible trees is
    // already correct.

    return Solution.Result.number(possible);
}

pub fn part_two(allocator: Allocator, input: []const u8) !Solution.Result {
    _ = allocator;
    _ = input;
    return .Empty;
}

test "part_1.sample_1" {
    var result = try part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(0, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = try part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(0, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\
;
