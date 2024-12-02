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
    var line_iterator = std.mem.splitScalar(u8, input, '\n');
    var seed_iterator = std.mem.splitScalar(u8, line_iterator.next().?, ' ');

    _ = line_iterator.next();
    var maps = parseAlmanachMaps(allocator, &line_iterator);

    var seeds = std.ArrayList(u64).init(allocator);
    defer seeds.deinit();
    var seed_ranges = std.ArrayList(AlmanachRange).init(allocator);
    defer seed_ranges.deinit();

    _ = seed_iterator.next();
    var seed_range_start: ?u64 = null;
    while (seed_iterator.next()) |seed_str| {
        const number = std.fmt.parseInt(u64, seed_str, 10) catch unreachable;
        seeds.append(number) catch unreachable;
        if (seed_range_start) |seed| {
            seed_ranges.append(AlmanachRange{ .start = seed, .len = number }) catch unreachable;
            seed_range_start = null;
        } else {
            seed_range_start = number;
        }
    }
    _ = line_iterator.next();

    // Part One
    for (maps) |map| {
        for (seeds.items, 0..) |item, index| {
            seeds.items[index] = map.translate(item);
        }
    }
    var location_one: u64 = std.math.maxInt(u64);
    for (seeds.items) |item| {
        location_one = @min(location_one, item);
    }

    // Part Two
    var ranges: []AlmanachRange = allocator.dupe(AlmanachRange, seed_ranges.items) catch unreachable;
    defer allocator.free(ranges);
    for (maps) |map| {
        const old = ranges;
        defer allocator.free(old);
        ranges = map.translateRanges(allocator, old);
    }
    var location_two: u64 = std.math.maxInt(u64);
    for (ranges) |range| {
        location_two = @min(location_two, range.start);
    }

    for (0..maps.len) |index| {
        maps[index].deinit();
    }
    return .{ location_one, location_two };
}

const AlmanachRange = struct {
    start: u64,
    len: u64,
};

const AlmanachMapEntry = struct {
    dest: u64,
    source: u64,
    len: u64,

    pub fn FromSlice(input: []const u8) AlmanachMapEntry {
        var value_iterator = mem.splitScalar(u8, input, ' ');
        const dest = std.fmt.parseInt(u64, value_iterator.next().?, 10) catch unreachable;
        const source = std.fmt.parseInt(u64, value_iterator.next().?, 10) catch unreachable;
        const range = std.fmt.parseInt(u64, value_iterator.next().?, 10) catch unreachable;
        return .{
            .dest = dest,
            .source = source,
            .len = range,
        };
    }
};

const AlmanachMap = struct {
    allocator: Allocator,
    name: []const u8,
    entries: std.ArrayList(AlmanachMapEntry),

    pub fn init(allocator: Allocator, name: []const u8) AlmanachMap {
        return .{
            .allocator = allocator,
            .name = name,
            .entries = std.ArrayList(AlmanachMapEntry).init(allocator),
        };
    }

    pub fn deinit(self: *AlmanachMap) void {
        self.entries.deinit();
    }

    pub fn append(self: *AlmanachMap, entry: AlmanachMapEntry) void {
        self.entries.append(entry) catch unreachable;
    }

    pub fn translate(self: AlmanachMap, value: u64) u64 {
        for (self.entries.items) |entry| {
            if (value >= entry.source and value <= entry.source + entry.len) {
                return entry.dest + value - entry.source;
            }
        }
        return value;
    }

    pub fn translateRanges(self: AlmanachMap, allocator: Allocator, sources: []AlmanachRange) []AlmanachRange {
        var destination = std.ArrayList(AlmanachRange).init(allocator);
        defer destination.deinit();
        for (sources) |source| {
            var workload = std.ArrayList(AlmanachRange).init(self.allocator);
            defer workload.deinit();
            workload.append(source) catch unreachable;
            workloop: while (workload.popOrNull()) |range| {
                for (self.entries.items) |translation| {
                    if (range.start + range.len < translation.source or translation.source + translation.len < range.start) {
                        // Complete miss, continue for-loop
                        continue;
                    }
                    if (range.start >= translation.source and range.start + range.len <= translation.source + translation.len) {
                        // Range is contained and translated
                        destination.append(AlmanachRange{ .start = range.start + translation.dest - translation.source, .len = range.len }) catch unreachable;
                        continue :workloop;
                    }
                    if (range.start < translation.source and range.start + range.len > translation.source + translation.len) {
                        // Range contains translation and needs to be split in 3
                        workload.append(AlmanachRange{ .start = range.start, .len = translation.source - range.start }) catch unreachable;
                        destination.append(AlmanachRange{ .start = translation.dest, .len = translation.len }) catch unreachable;
                        workload.append(AlmanachRange{ .start = translation.source + translation.len, .len = range.start + range.len - translation.source - translation.len }) catch unreachable;
                        continue :workloop;
                    }
                    if (range.start < translation.source and range.start + range.len > translation.source) {
                        // Start of range is not contained
                        workload.append(AlmanachRange{ .start = range.start, .len = translation.source - range.start }) catch unreachable;
                        destination.append(AlmanachRange{ .start = translation.dest, .len = range.len + range.start - translation.source }) catch unreachable;
                        continue :workloop;
                    }
                    if (range.start < translation.source + translation.len and range.start + range.len > translation.source + translation.len) {
                        destination.append(AlmanachRange{ .start = translation.dest + range.start - translation.source, .len = translation.source + translation.len - range.start }) catch unreachable;
                        workload.append(AlmanachRange{ .start = translation.source + translation.len, .len = range.start + range.len - translation.source - translation.len }) catch unreachable;
                        continue :workloop;
                    }
                }
                destination.append(range) catch unreachable;
            }
        }
        return allocator.dupe(AlmanachRange, destination.items) catch unreachable;
    }
};

fn parseAlmanachMaps(allocator: Allocator, line_iterator: *mem.SplitIterator(u8, mem.DelimiterType.scalar)) [7]AlmanachMap {
    var maps: [7]AlmanachMap = undefined;
    var init_index: usize = 0;
    var current: ?AlmanachMap = null;
    while (line_iterator.next()) |line| {
        if (line.len == 0) {
            if (current) |map| {
                maps[init_index] = map;
                current = null;
                init_index += 1;
            }
        } else if (!util.isDigit(line[0]) and current == null) {
            current = AlmanachMap.init(allocator, line);
        } else if (util.isDigit(line[0]) and current != null) {
            current.?.append(AlmanachMapEntry.FromSlice(line));
        } else {
            std.debug.print("Couldn't parse line:\n{s}\n", .{line});
            unreachable;
        }
    }
    return maps;
}

const sample_1: []const u8 =
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(35, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(46, solution[1]);
}
