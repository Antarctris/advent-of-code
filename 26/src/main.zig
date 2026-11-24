const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const solutions = @import("solutions");
const Result = @import("solution").Result;

const YEAR = 2026;
const DAYS = 12;
const record_path = "solution_record.json";
const report_path = "README.md";

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;
    defer stdout.flush() catch {};

    const args = try init.minimal.args.toSlice(arena);
    if (args.len != 2) {
        std.debug.print("Number of day must be specified as first argument! No input read.\n", .{});
        std.process.exit(1);
    }
    const day = std.fmt.parseUnsigned(u8, args[1], 10) catch {
        std.debug.print("Argument given was not a number of day! Input not read.\n", .{});
        std.process.exit(1);
    };

    inline for (solutions.days) |entry| {
        if (entry[0] == day) return runDay(entry[1], day, io, arena, stdout);
    }
    std.debug.print("No solution for day {d} found in src/solutions/.\n", .{day});
    std.process.exit(1);
}

fn runDay(comptime Day: type, day: u8, io: Io, arena: Allocator, stdout: *Io.Writer) !void {
    const path = try std.fmt.allocPrint(arena, "input/{d:0>2}.txt", .{day});
    const input = try Io.Dir.cwd().readFileAlloc(io, path, arena, .limited(1 << 20));

    try stdout.print("Processing...\n", .{});
    try stdout.flush();

    const ms_one = try runPart(io, arena, stdout, "Part 1", Day.part_one, input);
    const ms_two = try runPart(io, arena, stdout, "Part 2", Day.part_two, input);

    if (day != 0) {
        try updateRecord(io, arena, .{
            .id = day,
            .title = Day.title,
            .part_one = ms_one,
            .part_two = ms_two,
        });
    }

    try stdout.print("Done!\n", .{});
}

/// Runs one part, prints its result and returns the elapsed milliseconds, or null if the part is not implemented.
fn runPart(
    io: Io,
    allocator: Allocator,
    stdout: *Io.Writer,
    label: []const u8,
    part: fn (Allocator, []const u8) anyerror!Result,
    input: []const u8,
) !?f64 {
    const start: Io.Clock.Timestamp = .now(io, .awake);
    var result = try part(allocator, input);
    defer result.deinit();
    const elapsed = start.untilNow(io);
    const ms = @as(f64, @floatFromInt(elapsed.raw.toNanoseconds())) / std.time.ns_per_ms;

    switch (result) {
        .Empty => return null,
        .Number => |n| try stdout.print("{s}: {d}, {d:.3} ms\n", .{ label, n, ms }),
        .String => |s| try stdout.print("{s}: {s}, {d:.3} ms\n", .{ label, s.bytes, ms }),
    }
    try stdout.flush();
    return ms;
}

const YearRecord = struct {
    lang: []const u8 = "Zig",
    results: []ResultRecord,
};

const ResultRecord = struct {
    id: u32,
    title: []const u8,
    part_one: ?f64,
    part_two: ?f64,

    /// Keeps the best time per part.
    fn update(self: *ResultRecord, other: ResultRecord) void {
        self.title = other.title;
        inline for (.{ "part_one", "part_two" }) |field| {
            if (@field(other, field)) |new| {
                if (@field(self, field) == null or new < @field(self, field).?) @field(self, field) = new;
            }
        }
    }

    fn lessThan(_: void, a: ResultRecord, b: ResultRecord) bool {
        return a.id < b.id;
    }
};

fn updateRecord(io: Io, arena: Allocator, record: ResultRecord) !void {
    const cwd = Io.Dir.cwd();

    var results: std.ArrayList(ResultRecord) = .empty;
    if (cwd.readFileAlloc(io, record_path, arena, .limited(1 << 16))) |old_file| {
        const old = try std.json.parseFromSliceLeaky(YearRecord, arena, old_file, .{});
        try results.appendSlice(arena, old.results);
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }

    for (results.items) |*existing| {
        if (existing.id == record.id) {
            existing.update(record);
            break;
        }
    } else try results.append(arena, record);
    std.mem.sortUnstable(ResultRecord, results.items, {}, ResultRecord.lessThan);

    var buffer: [1024]u8 = undefined;

    // solution_record.json
    {
        const file = try cwd.createFile(io, record_path, .{});
        defer file.close(io);
        var file_writer = file.writer(io, &buffer);
        const w = &file_writer.interface;
        try w.print("{f}\n", .{std.json.fmt(YearRecord{ .results = results.items }, .{ .whitespace = .indent_4 })});
        try w.flush();
    }

    // README.md
    {
        const file = try cwd.createFile(io, report_path, .{});
        defer file.close(io);
        var file_writer = file.writer(io, &buffer);
        const w = &file_writer.interface;

        try w.print(
            \\| {d: <61} | Stars | Time (ms)  | Time (ms)  |
            \\|---------------------------------------------------------------|:-----:|-----------:|-----------:|
            \\
        , .{YEAR});

        var stars: usize = 0;
        for (results.items) |rec| {
            if (rec.id < 1 or rec.id > DAYS) continue;
            const title = try std.fmt.allocPrint(arena, "[{s}](src/solutions/day{d:0>2}.zig)", .{ rec.title, rec.id });

            stars += @intFromBool(rec.part_one != null);
            const star_one = if (rec.part_one != null) "⭐" else "  ";
            // The last star of the year is granted for free once all others are collected.
            const star_two = if (rec.part_two != null or stars == DAYS * 2 - 1) "⭐" else "  ";
            stars += @intFromBool(rec.part_two != null);

            try w.print("| {s: <61} |  {s}{s} | {s: >10} | {s: >10} |\n", .{
                title,
                star_one,
                star_two,
                try fmtMs(arena, rec.part_one),
                try fmtMs(arena, rec.part_two),
            });
        }
        try w.flush();
    }
}

fn fmtMs(arena: Allocator, ms: ?f64) ![]const u8 {
    return if (ms) |v| std.fmt.allocPrint(arena, "{d:.3}", .{v}) else "-";
}
