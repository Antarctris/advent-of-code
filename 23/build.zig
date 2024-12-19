const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Create module for utils, so it can be imported within solutions folder
    const util = b.createModule(.{
        .root_source_file = b.path("src/util/util.zig"),
    });

    // Create main executable
    const exe = b.addExecutable(.{
        .name = "advent-of-code",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("util", util);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/solutions/solutions.zig"),
        .target = target,
        .optimize = optimize,
        .test_runner = b.path("test_runner.zig"),
    });
    exe_unit_tests.root_module.addImport("util", util);

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    run_exe_unit_tests.has_side_effects = true;

    // Generate solution_collection.zig
    const solutions_gen = b.addExecutable(.{
        .name = "solution_collection_gen",
        .root_source_file = b.path("tools/solutions_gen.zig"),
        .target = b.host,
    });
    const solutions_gen_run = b.addRunArtifact(solutions_gen);
    solutions_gen_run.has_side_effects = true;
    const generated_solutions_file = solutions_gen_run.addOutputFileArg("solutions.zig");
    const wf = b.addWriteFiles();
    wf.addCopyFileToSource(generated_solutions_file, "src/solutions.zig");
    const update_solutions_step = b.step("update-solutions", "update src/solutions.zig to latest");
    update_solutions_step.dependOn(&wf.step);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    inline for (0..26) |day| {
        var buf_name: [10]u8 = undefined;
        const test_n_step_name = std.fmt.bufPrint(buf_name[0..], "test-day{d:0>2}", .{day}) catch unreachable;
        var buf_path: [23]u8 = undefined;
        const test_n_step_path = std.fmt.bufPrint(buf_path[0..], "src/solutions/day{d:0>2}.zig", .{day}) catch unreachable;

        const exe_unit_tests_n = b.addTest(.{
            .root_source_file = b.path(test_n_step_path),
            .target = target,
            .optimize = optimize,
            .test_runner = b.path("test_runner.zig"),
        });
        exe_unit_tests_n.root_module.addImport("util", util);

        const run_exe_unit_tests_n = b.addRunArtifact(exe_unit_tests_n);
        run_exe_unit_tests_n.has_side_effects = true;

        // Similar to creating the run step earlier, this exposes a `test` step to
        // the `zig build --help` menu, providing a way for the user to request
        // running the unit tests.
        const test_n_step = b.step(test_n_step_name, "Run unit tests");
        test_n_step.dependOn(&run_exe_unit_tests_n.step);
    }
}
