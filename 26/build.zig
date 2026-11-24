const std = @import("std");

const solutions_dir = "src/solutions";

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_runner: std.Build.Step.Compile.TestRunner = .{
        .path = b.path("test_runner.zig"),
        .mode = .simple,
    };
    const test_step = b.step("test", "Run all unit tests");

    // utility library, use @import("util").
    const util = b.addModule("util", .{
        .root_source_file = b.path("util/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const util_tests = b.addTest(.{ .root_module = util, .test_runner = test_runner });
    const util_test_run = b.addRunArtifact(util_tests);
    util_test_run.has_side_effects = true;
    b.step("test-utils", "Run unit tests of util/").dependOn(&util_test_run.step);

    // Shared solution types (Result), importable as @import("solution").
    const solution = b.addModule("solution", .{
        .root_source_file = b.path(solutions_dir ++ "/solution.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Discover src/solutions/dayNN.zig.
    // dependsOn is needed to work around the cache and get file updates
    b.dependOnDirectoryContents(b.path(solutions_dir));
    const days = try discoverDays(b);

    // One module per day, plus a registry generated into the cache (never into
    // the source tree) that imports them all:
    //   pub const days = .{ .{ 1, @import("day01") }, ... };
    var registry: std.ArrayList(u8) = .empty;
    var day_imports: std.ArrayList(std.Build.Module.Import) = .empty;
    try registry.appendSlice(b.allocator, "pub const days = .{\n");
    for (days) |day| {
        const name = b.fmt("day{d:0>2}", .{day});
        const day_module = b.createModule(.{
            .root_source_file = b.path(b.fmt("{s}/{s}.zig", .{ solutions_dir, name })),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "util", .module = util },
                .{ .name = "solution", .module = solution },
            },
        });
        try day_imports.append(b.allocator, .{ .name = name, .module = day_module });
        try registry.print(b.allocator, "    .{{ {d}, @import(\"{s}\") }},\n", .{ day, name });

        addTestStep(b, b.fmt("test-{s}", .{name}), b.fmt("Run unit tests of {s}", .{name}), day_module, test_runner, test_step);
    }
    try registry.appendSlice(b.allocator, "};\n");

    const solutions = b.createModule(.{
        .root_source_file = b.addWriteFiles().add("solutions.zig", registry.items),
        .target = target,
        .optimize = optimize,
        .imports = day_imports.items,
    });

    const exe = b.addExecutable(.{
        .name = "advent-of-code",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "solutions", .module = solutions },
                .{ .name = "solution", .module = solution },
            },
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
    const run_step = b.step("run", "Run a day: zig build run -- <day>");
    run_step.dependOn(&run_cmd.step);
}

/// Returns the sorted day numbers of all `dayNN.zig` files in `solutions_dir`.
fn discoverDays(b: *std.Build) ![]const u8 {
    const io = b.graph.io;
    const root = try b.root.join(b.allocator, solutions_dir);
    var dir = try root.root_dir.handle.openDir(io, root.sub_path, .{ .iterate = true });
    defer dir.close(io);

    var days: std.ArrayList(u8) = .empty;
    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.startsWith(u8, entry.name, "day") or !std.mem.endsWith(u8, entry.name, ".zig")) continue;
        const digits = entry.name["day".len .. entry.name.len - ".zig".len];
        const day = std.fmt.parseUnsigned(u8, digits, 10) catch continue;
        try days.append(b.allocator, day);
    }
    std.mem.sortUnstable(u8, days.items, {}, std.sort.asc(u8));
    return days.items;
}

fn addTestStep(
    b: *std.Build,
    name: []const u8,
    description: []const u8,
    module: *std.Build.Module,
    test_runner: std.Build.Step.Compile.TestRunner,
    test_all: *std.Build.Step,
) void {
    const tests = b.addTest(.{ .root_module = module, .test_runner = test_runner });
    const run = b.addRunArtifact(tests);
    run.has_side_effects = true;
    b.step(name, description).dependOn(&run.step);
    test_all.dependOn(&run.step);
}
