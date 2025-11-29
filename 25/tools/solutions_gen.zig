const std = @import("std");

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);

    if (args.len != 2) fatal("wrong number of arguments", .{});

    const output_file_path = args[1];

    var output_file = std.fs.cwd().createFile(output_file_path, .{}) catch |err| {
        fatal("unable to open '{s}': {s}", .{ output_file_path, @errorName(err) });
    };
    defer output_file.close();

    try output_file.writeAll(header);

    var dir = try std.fs.cwd().openDir("./src/solutions/", .{ .iterate = true });
    defer dir.close();

    var implementations: [26]u64 = undefined;
    var implementations_idx: usize = 0;

    var dirIterator = dir.iterate();
    while (try dirIterator.next()) |dirContent| {
        const file: []const u8 = dirContent.name;
        if (std.mem.endsWith(u8, file, ".zig") and std.mem.eql(u8, "day", file[file.len - 9 .. file.len - 6])) {
            implementations[implementations_idx] = try std.fmt.parseInt(u8, file[file.len - 6 .. file.len - 4], 10);
            implementations_idx += 1;
        }
    }

    std.sort.heap(u64, implementations[0..implementations_idx], {}, comptime std.sort.asc(u64));

    for (0..implementations_idx) |idx| {
        var buf: [128]u8 = undefined;
        try output_file.writeAll(try std.fmt.bufPrint(
            &buf,
            "        {d} => @import(\"./solutions/day{0d:0>2}.zig\").solution,\n",
            .{implementations[idx]},
        ));
    }

    try output_file.writeAll(footer);

    return std.process.cleanExit();
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(1);
}

const header =
    \\const std = @import("std");
    \\
    \\const Solution = @import("./solutions/solution.zig");
    \\
    \\pub fn get(index: usize) ?Solution {
    \\    return switch (index) {
    \\
;

const footer =
    \\        else => null,
    \\    };
    \\
    \\}
    \\
    \\test {
    \\    std.testing.refAllDecls(@This());
    \\}
    \\
;
