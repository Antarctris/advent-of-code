const std = @import("std");
const mem = std.mem;
const time = std.time;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const solutions = @import("solutions.zig");

fn readInputFile(allocator: Allocator, path: []const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const file_size = (try file.metadata()).size();
    const input = try allocator.alloc(u8, file_size);
    _ = try file.readAll(input);
    return input;
}

pub fn main() !void {
    if (std.os.argv.len != 2) {
        std.debug.print("Number of day must be specified as first argument! No input read.\n", .{});
        std.process.exit(1);
    }

    // Set up output
    const stdout = std.io.getStdOut().writer();

    // Initialze allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Check file argument, should be the number of day for solution source code to be run
    // with according input.
    const file_arg: []const u8 = mem.span(std.os.argv[1]);
    if (std.fmt.parseUnsigned(usize, file_arg, 10) catch null) |day| {

        // Read input
        var path_buf: [12]u8 = undefined;
        const path = try std.fmt.bufPrint(&path_buf, "input/{d:0>2}.txt", .{day});
        const input = try readInputFile(allocator, path);

        try stdout.print("Processing...\n", .{});

        if (solutions.get(day)) |solution| {
            const time0_one = try time.Instant.now();
            const value_one = solution.part_one(allocator, input);
            const time1_one = try time.Instant.now();
            const timed_one: f64 = @floatFromInt(time1_one.since(time0_one));
            const elapsed_ms_one = timed_one / time.ns_per_ms;
            if (value_one) |value| {
                try stdout.print("Part 1: {d}, {d:.3} ms\n", .{ value, elapsed_ms_one });
            }
            const time0_two = try time.Instant.now();
            const value_two = solution.part_two(allocator, input);
            const time1_two = try time.Instant.now();
            const timed_two: f64 = @floatFromInt(time1_two.since(time0_two));
            const elapsed_ms_two = timed_two / time.ns_per_ms;
            if (value_two) |value| {
                try stdout.print("Part 2: {d}, {d:.3} ms\n", .{ value, elapsed_ms_two });
            }
        }

        try stdout.print("Done!\n", .{});
    } else {
        try stdout.print("Argument given was not a number of day! Input not read.", .{});
        std.process.exit(1);
    }
}
