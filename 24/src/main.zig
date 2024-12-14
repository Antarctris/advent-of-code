const std = @import("std");
const mem = std.mem;
const time = std.time;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const solutions = @import("solutions.zig");

pub fn main() !void {
    if (std.os.argv.len != 2) {
        std.debug.print("Number of day must be specified as first argument! No input read.\n", .{});
        std.process.exit(1);
    }

    // Set up output (yes, not buffered because I can't be bothered)
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
        const input = try std.fs.cwd().readFileAlloc(allocator, path, 1 << 16); // 64MiB

        try stdout.print("Processing...\n", .{});

        if (solutions.get(day)) |solution| {
            const time0_one = try time.Instant.now();
            const value_one = solution.part_one(allocator, input);
            const time1_one = try time.Instant.now();
            const timed_one: f32 = @floatFromInt(time1_one.since(time0_one));
            const elapsed_ms_one = timed_one / time.ns_per_ms;
            if (value_one) |value| {
                try stdout.print("Part 1: {d}, {d:.3} ms\n", .{ value, elapsed_ms_one });
            }
            const time0_two = try time.Instant.now();
            const value_two = solution.part_two(allocator, input);
            const time1_two = try time.Instant.now();
            const timed_two: f32 = @floatFromInt(time1_two.since(time0_two));
            const elapsed_ms_two = timed_two / time.ns_per_ms;
            if (value_two) |value| {
                try stdout.print("Part 2: {d}, {d:.3} ms\n", .{ value, elapsed_ms_two });
            }

            try updateRecord(allocator, ResultRecord{
                .id = @intCast(day),
                .title = solution.title(),
                .part_one = if (value_one != null) elapsed_ms_one else null,
                .part_two = if (value_two != null) elapsed_ms_two else null,
            });
        }

        try stdout.print("Done!\n", .{});
    } else {
        try stdout.print("Argument given was not a number of day! Input not read.", .{});
        std.process.exit(1);
    }
}

const record_path = "solution_record.json";
fn updateRecord(allocator: Allocator, record: ResultRecord) !void {
    if (std.fs.cwd().readFileAlloc(allocator, record_path, 1 << 12)) |old_file| { // 4MiB
        defer allocator.free(old_file);

        const old_record = try std.json.parseFromSlice(YearRecord, allocator, old_file, .{});
        defer old_record.deinit();

        var result_records = std.ArrayList(ResultRecord).init(allocator);
        defer result_records.deinit();
        try result_records.appendSlice(old_record.value.results);
        std.sort.heap(ResultRecord, result_records.items, {}, resultRecordFirst);

        var index: usize = 0;
        while (index < result_records.items.len and result_records.items[index].id < record.id) {
            index += 1;
        }
        if (index < result_records.items.len and result_records.items[index].id == record.id) {
            result_records.items[index].update(record);
        } else {
            try result_records.insert(index, record);
        }

        const new_record = YearRecord{ .lang = ziglang, .results = result_records.items };
        const new_json = try std.json.stringifyAlloc(allocator, new_record, .{ .whitespace = .indent_4 });

        const file = try std.fs.cwd().createFile(record_path, .{});
        defer file.close();

        _ = try file.writeAll(new_json);
    } else |_| {
        var records: [1]ResultRecord = .{record};
        const new_record = YearRecord{ .lang = ziglang, .results = &records };
        const new_json = try std.json.stringifyAlloc(allocator, new_record, .{ .whitespace = .indent_4 });

        const file = try std.fs.cwd().createFile(record_path, .{});
        defer file.close();

        _ = try file.writeAll(new_json);
    }
}

const ziglang: []const u8 = "Zig";

const YearRecord = struct {
    lang: []const u8,
    results: []ResultRecord,
};

const ResultRecord = struct {
    id: u32,
    title: []const u8,
    part_one: ?f32,
    part_two: ?f32,

    pub fn update(self: *ResultRecord, other: ResultRecord) void {
        self.title = other.title;
        if (other.part_one) |new_one| {
            if (self.part_one == null or new_one < self.part_one.?) {
                self.part_one = new_one;
            }
        }
        if (other.part_two) |new_two| {
            if (self.part_two == null or new_two < self.part_two.?) {
                self.part_two = new_two;
            }
        }
    }
};

fn resultRecordFirst(ctx: void, a: ResultRecord, b: ResultRecord) bool {
    _ = ctx;
    return a.id < b.id;
}
