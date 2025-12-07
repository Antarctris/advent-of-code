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

pub fn part_one(allocator: Allocator, input: []const u8) !Solution.Result {
    _ = allocator;

    var result: u64 = 0;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    var range_iterator = mem.tokenizeScalar(u8, line_iterator.next() orelse unreachable, ',');
    while (range_iterator.next()) |range_str| {
        if (range_str.len == 0) continue;
        var range_split = mem.splitScalar(u8, range_str, '-');
        const small: usize = try std.fmt.parseInt(u64, range_split.next() orelse unreachable, 10);
        const large: usize = try std.fmt.parseInt(u64, range_split.next() orelse unreachable, 10);
        for (small..large + 1) |n| {
            // Old version
            //const n_str = try std.fmt.bufPrint(&buffer, "{d}", .{n});
            //if (@mod(n_str.len, 2) != 0) continue;
            //const h = @divTrunc(n_str.len, 2);
            //if (mem.eql(u8, n_str[0..h], n_str[h..])) {
            //    result += n;
            //}
            const number_length = util.math.numeralLength10(u64, n);
            if (@mod(number_length, 2) != 0) continue;
            const half_length = @divTrunc(number_length, 2);
            const patternN = @mod(n, pow_10[half_length]) * (pow_10[number_length] - 1) / (pow_10[half_length] - 1);
            if (n == patternN) {
                result += n;
            }
        }
    }
    return Solution.Result.number(result);
}

pub fn part_two(allocator: Allocator, input: []const u8) !Solution.Result {
    _ = allocator;

    var result: u64 = 0;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    var range_iterator = mem.tokenizeScalar(u8, line_iterator.next() orelse unreachable, ',');
    while (range_iterator.next()) |range_str| {
        if (range_str.len == 0) continue;
        var range_split = mem.splitScalar(u8, range_str, '-');
        const small: usize = try std.fmt.parseInt(u64, range_split.next() orelse unreachable, 10);
        const large: usize = try std.fmt.parseInt(u64, range_split.next() orelse unreachable, 10);
        for (small..large + 1) |n| {
            if (containsRepeatingPatternNum(@intCast(n))) {
                result += n;
            }
        }
    }
    return Solution.Result.number(result);
}

// Pure mathematical solution
// Using the generic log and pow functions, this was even slower than the string conversion
// Only with optimizations of using dedicated log10 function and a table for powers of 10
// this became faster than the original.
fn containsRepeatingPatternNum(n: u64) bool {
    const number_len = util.math.numeralLength10(u64, n);
    const half_len = @divTrunc(number_len, 2) + 1;
    for (1..half_len) |pattern_len| {
        if (@mod(number_len, pattern_len) != 0) continue;
        const repeat = @divTrunc(number_len, pattern_len);
        const pattern_base = pow_10[pattern_len];
        const pattern0 = @mod(n, pattern_base);
        const patternN = pattern0 * (pow_10[pattern_len * repeat] - 1) / (pattern_base - 1);
        if (n == patternN) return true;
    }
    return false;
}

const pow_10: [20]u64 = blk: {
    var arr: [20]u64 = undefined;
    arr[0] = 1;
    for (1..20) |i| {
        arr[i] = 10 * arr[i - 1];
    }
    break :blk arr;
};

// My original solution using conversion to string in a buffer
// const n_str = std.fmt.bufPrint(&buffer, "{d}", .{n}) catch unreachable;
fn containsRepeatingPatternStr(s: []const u8) bool {
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
    var result = try part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(1227775554, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = try part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(4174379265, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_2" {
    var result = try part_two(std.testing.allocator, sample_2);
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
