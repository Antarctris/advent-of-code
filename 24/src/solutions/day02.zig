const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

const util = @import("util");
const Solution = @import("./solution.zig");

// interfacerst
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day 2: Red-Nosed Reports";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.splitScalar(u8, input, '\n');
    var result: u64 = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const report = util.parseNumbers(allocator, i64, line, 10);
        defer allocator.free(report);

        if (isReportSaveRecursive(allocator, report, 0)) {
            result += 1;
        }
    }
    return result;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var line_iterator = mem.splitScalar(u8, input, '\n');
    var result: u64 = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const report = util.parseNumbers(allocator, i64, line, 10);
        defer allocator.free(report);

        if (isReportSaveRecursive(allocator, report, 1)) {
            result += 1;
        }
    }
    return result;
}

fn isReportSaveRecursive(allocator: Allocator, report: []const i64, tolerance: u64) bool {
    if (tolerance > 0 and
        isReportSaveRecursive(allocator, report[1..], tolerance - 1)) return true;
    var last: i64 = report[0];
    var index: usize = 1;
    var gradient_opt: ?bool = null;
    while (index < report.len) : (index += 1) {
        if (!inRange(@abs(last - report[index]), 1, 3) or (gradient_opt != null and gradient_opt != (last > report[index]))) {
            if (tolerance > 0) {
                if (index == report.len - 1 and isReportSaveRecursive(allocator, report[0 .. report.len - 1], tolerance - 1)) return true;
                var sub_report = std.ArrayList(i64).init(allocator);
                defer sub_report.deinit();
                for (report, 0..) |num, idx| {
                    if (idx == index - 1) continue;
                    sub_report.append(num) catch unreachable;
                }
                if (isReportSaveRecursive(allocator, sub_report.items, tolerance - 1)) return true;
                sub_report.clearRetainingCapacity();
                for (report, 0..) |num, idx| {
                    if (idx == index) continue;
                    sub_report.append(num) catch unreachable;
                }
                return isReportSaveRecursive(allocator, sub_report.items, tolerance - 1);
            }
            return false;
        }
        if (gradient_opt == null) {
            gradient_opt = last > report[index];
        }
        last = report[index];
    }
    return true;
}

fn inRange(n: u64, l: u64, h: u64) bool {
    return n >= l and n <= h;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;

    try std.testing.expectEqual(2, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(4, result);
}

test "part_2.sample_2" {
    const result = part_two(std.testing.allocator, sample_2) orelse return error.SkipZigTest;
    try std.testing.expectEqual(1, result);
}

const sample_1: []const u8 =
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
    \\
;

const sample_2: []const u8 =
    \\8 1 2 3 4
    \\
;
