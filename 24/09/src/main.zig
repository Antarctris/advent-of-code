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
    var line = allocator.dupe(u8, mem.trim(u8, input, "\n")) catch unreachable;
    defer allocator.free(line);
    for (0..line.len) |i| line[i] = line[i] - '0'; //Convert all to numbers

    const checksum_one = checksum_part_one(line);
    const checksum_two = checksum_part_two(allocator, line);

    return .{ checksum_one, checksum_two };
}

fn checksum_part_one(line: []const u8) u64 {
    var checksum: u64 = 0;

    var l_line_index: usize = 0;
    var l_id: usize = 0;
    var l_index: usize = 0;

    var r_line_index: usize = line.len - 1;
    var r_count: usize = line[r_line_index];

    while (l_line_index < r_line_index) {
        // File
        const file_size = line[l_line_index];
        checksum += util.math.sumRange(u64, l_index, l_index + file_size) * l_id;
        l_id += 1;
        l_index += line[l_line_index];
        l_line_index += 1;

        // empty space
        var empty_space: usize = line[l_line_index];
        // Continue until space is filled or there is no entry to move anymore
        while (empty_space > 0 and r_line_index > l_line_index) {
            const r_id = r_line_index / 2;
            r_count = if (r_count != 0) r_count else line[r_line_index];
            if (r_count > empty_space) {
                checksum += util.math.sumRange(u64, l_index, l_index + empty_space) * r_id;
                r_count -= empty_space;
                l_index += empty_space;
                empty_space = 0;
            } else {
                checksum += util.math.sumRange(u64, l_index, l_index + r_count) * r_id;
                empty_space -= r_count;
                l_index += r_count;
                r_count = 0;
            }
            if (r_count == 0) {
                r_line_index -= 2;
                // Not updating r_count here, since this would corrupt the value for the
                // optional last checksum addition after the loop, instead, only update index
                // and get r_count at the beginning of the loop if update is necessary.
            }
        }
        l_line_index += 1;
    }
    if (r_count > 0) {
        checksum += util.math.sumRange(u64, l_index, l_index + r_count) * (r_line_index / 2);
    }

    return checksum;
}

fn checksum_part_two(allocator: Allocator, line: []const u8) u64 {
    // Directly allocate enough space for all entries with spare capacity, so that filling the
    // list won't have to reallocate memory an unreasonable amount of times
    var files = std.ArrayList(FileEntry).initCapacity(allocator, line.len + 100) catch unreachable;
    defer files.deinit();
    for (line, 0..) |n, i| {
        // Create file system entries, all even indices are files with id, all uneven are empty with id null
        files.appendAssumeCapacity(FileEntry{ .len = n, .id = if (i % 2 == 0) i / 2 else null, .visited = false });
    }
    var index: usize = files.items.len - 1;
    files: while (index > 0) {
        if (files.items[index].id == null) {
            // Merge consecutive empty space, optional, but reduces number of entries,
            // which might improve performance (not tested)
            if (index + 1 < files.items.len and files.items[index + 1].id == null) {
                files.items[index].len += files.items[index + 1].len;
                _ = files.orderedRemove(index + 1);
            }
        } else if (!files.items[index].visited) {
            // Search space for this unvisited node
            var search_index: usize = 0;
            while (search_index < index) {
                if (files.items[search_index].id == null) {
                    if (files.items[search_index].len == files.items[index].len) {
                        // Inplace move, which prevents shifting of entries in memory
                        files.items[search_index].id = files.items[index].id;
                        files.items[search_index].visited = true;
                        files.items[index].id = null;
                        continue :files;
                    } else if (files.items[search_index].len > files.items[index].len) {
                        // Default move, where shifting of entries in memory can't be prevented
                        files.items[search_index].len -= files.items[index].len;
                        const id = files.items[index].id;
                        const len = files.items[index].len;
                        files.items[index].id = null;
                        files.insert(search_index, FileEntry{ .len = len, .id = id, .visited = true }) catch unreachable;
                        continue :files;
                    }
                }
                search_index += 1;
            }
            files.items[index].visited = true;
        }
        index -= 1;
    }
    // Run over all entries and calculate the checksum
    var checksum: u64 = 0;
    var file_index: usize = 0;
    for (files.items) |entry| {
        if (entry.id) |d| {
            checksum += util.math.sumRange(u64, file_index, file_index + entry.len) * d;
        }
        file_index += entry.len;
    }
    return checksum;
}

const FileEntry = struct {
    len: usize,
    id: ?usize,
    visited: bool,
};

const sample_1: []const u8 =
    \\2333133121414131402
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(1928, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(2858, solution[1]);
}
