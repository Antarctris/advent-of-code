const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const util = @import("util");

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

pub fn solveChallenge(allocator: Allocator, input: []const u8) [2]u64 {
    var line_iterator = mem.splitScalar(u8, input, '\n');
    var save_one: u64 = 0;
    var save_two: u64 = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        const report = util.parseNumbers(allocator, i64, line, 10);
        defer allocator.free(report);

        if (isReportSaveRecursive(allocator, report, 0)) {
            save_one += 1;
        }

        if (isReportSaveRecursive(allocator, report, 1)) {
            save_two += 1;
        }
    }
    return .{ save_one, save_two };
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

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(2, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(4, solution[1]);
}

test "part_2.sample_2" {
    const solution = solveChallenge(std.testing.allocator, sample_2);
    try std.testing.expectEqual(1, solution[1]);
}
