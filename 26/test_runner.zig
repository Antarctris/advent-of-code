// Based on https://gist.github.com/nurpax/4afcb6e4ef3f03f0d282f7c462005f12
// Modded from https://gist.github.com/karlseguin/c6bea5b35e4e8d26af6f81c22cb5d76b
//
// Env vars:
//   TEST_FILTER=<substring>  only run tests whose name contains the substring
//   TEST_FAIL_FIRST=true     stop after the first failing test

const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

const BORDER: []const u8 = &@as([80]u8, @splat('='));

const Status = enum { pass, fail, skip, text };

pub fn main(init: std.process.Init.Minimal) void {
    const gpa = std.heap.page_allocator;

    const fail_first = if (init.environ.getAlloc(gpa, "TEST_FAIL_FIRST")) |v| std.mem.eql(u8, v, "true") else |_| false;
    const filter: ?[]const u8 = init.environ.getAlloc(gpa, "TEST_FILTER") catch null;

    print("\r\x1b[0K", .{}); // beginning of line and clear to end of line

    var pass: usize = 0;
    var fail: usize = 0;
    var skip: usize = 0;
    var leak: usize = 0;

    for (builtin.test_functions) |t| {
        if (filter) |f| if (std.mem.indexOf(u8, t.name, f) == null) continue;

        testing.environ = init.environ;
        testing.allocator_instance = .init(std.heap.page_allocator, .{ .stack_trace_frames = 12 });
        testing.io_instance = .init(testing.allocator, .{
            .argv0 = .init(init.args),
            .environ = init.environ,
        });

        print("Testing {s}: ", .{t.name});
        const result = t.func();

        testing.io_instance.deinit();
        if (testing.allocator_instance.deinit() > 0) {
            leak += 1;
            printStatus(.fail, "\n{s}\n\"{s}\" - Memory Leak\n{s}\n", .{ BORDER, t.name, BORDER });
        }

        var status: Status = .pass;
        if (result) |_| {
            pass += 1;
        } else |err| switch (err) {
            error.SkipZigTest => {
                skip += 1;
                status = .skip;
            },
            else => {
                status = .fail;
                fail += 1;
                printStatus(.fail, "\n{s}\n\"{s}\" - {t}\n{s}\n", .{ BORDER, t.name, err, BORDER });
                if (@errorReturnTrace()) |trace| std.debug.dumpErrorReturnTrace(trace);
            },
        }

        printStatus(status, "[{t}]\n", .{status});
        if (status == .fail and fail_first) break;
    }

    const total = pass + fail;
    printStatus(if (fail == 0) .pass else .fail, "\n{d} of {d} test{s} passed\n", .{ pass, total, if (total != 1) "s" else "" });
    if (skip > 0) printStatus(.skip, "{d} test{s} skipped\n", .{ skip, if (skip != 1) "s" else "" });
    if (leak > 0) printStatus(.fail, "{d} test{s} leaked\n", .{ leak, if (leak != 1) "s" else "" });
    std.process.exit(if (fail == 0 and leak == 0) 0 else 1);
}

fn print(comptime format: []const u8, args: anytype) void {
    std.debug.print(format, args);
}

fn printStatus(s: Status, comptime format: []const u8, args: anytype) void {
    const color = switch (s) {
        .pass => "\x1b[32m",
        .fail => "\x1b[31m",
        .skip => "\x1b[33m",
        .text => "",
    };
    print("{s}" ++ format ++ "\x1b[0m", .{color} ++ args);
}
