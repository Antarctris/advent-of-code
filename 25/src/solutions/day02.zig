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
    return "Day 2: Gift Shop";
}

pub fn part_one(allocator: Allocator, input: []const u8) Solution.Result {
    _ = allocator;

    var result: u64 = 0;
    var buffer: [1024]u8 = undefined;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    var range_iterator = mem.tokenizeScalar(u8, line_iterator.next() orelse unreachable, ',');
    while (range_iterator.next()) |range_str| {
        if (range_str.len == 0) continue;
        var range_split = mem.splitScalar(u8, range_str, '-');
        const small: usize = std.fmt.parseInt(u64, range_split.next() orelse unreachable, 10) catch unreachable;
        const large: usize = std.fmt.parseInt(u64, range_split.next() orelse unreachable, 10) catch unreachable;
        for (small..large + 1) |n| {
            const n_str = std.fmt.bufPrint(&buffer, "{d}", .{n}) catch unreachable;
            if (@mod(n_str.len, 2) != 0) continue;
            const h = @divTrunc(n_str.len, 2);
            if (mem.eql(u8, n_str[0..h], n_str[h..])) {
                result += n;
            }
        }
    }
    return Solution.Result.number(result);
}

pub fn part_two(allocator: Allocator, input: []const u8) Solution.Result {
    _ = allocator;

    var result: u64 = 0;
    var buffer: [1024]u8 = undefined;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    var range_iterator = mem.tokenizeScalar(u8, line_iterator.next() orelse unreachable, ',');
    while (range_iterator.next()) |range_str| {
        if (range_str.len == 0) continue;
        var range_split = mem.splitScalar(u8, range_str, '-');
        const small: usize = std.fmt.parseInt(u64, range_split.next() orelse unreachable, 10) catch unreachable;
        const large: usize = std.fmt.parseInt(u64, range_split.next() orelse unreachable, 10) catch unreachable;
        for (small..large + 1) |n| {
            const n_str = std.fmt.bufPrint(&buffer, "{d}", .{n}) catch unreachable;
            if (containsRepeatingPattern(n_str)) {
                result += n;
            }
        }
    }
    return Solution.Result.number(result);
}

fn containsRepeatingPattern(s: []const u8) bool {
    const half_point = @divTrunc(s.len, 2) + 1; // +1 for include in range
    outer: for (1..half_point) |pattern_len| {
        if (@mod(s.len, pattern_len) != 0) continue;
        const repeat = @divTrunc(s.len, pattern_len);
        for (1..repeat) |i| {
            if (!mem.eql(u8, s[0..pattern_len], s[i * pattern_len .. (i + 1) * pattern_len])) continue :outer;
        }
        return true;
    }
    return false;
}

test "part_1.sample_1" {
    var result = part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(1227775554, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(4174379265, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_2" {
    var result = part_two(std.testing.allocator, sample_2);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(123123123, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
;

const sample_2: []const u8 =
    \\123123122-123123124
;
