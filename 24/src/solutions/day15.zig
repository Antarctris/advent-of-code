const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

const util = @import("util");
const grid = util.grid;
const Solution = @import("./solution.zig");

// interface
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day 15: Warehouse Woes";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    var input_iterator = mem.tokenizeSequence(u8, input, "\n\n");
    const warehouse_str = input_iterator.next().?;
    const instruction_str = input_iterator.next().?;

    var warehouse = grid.ByteGrid.parse(allocator, warehouse_str);
    defer warehouse.deinit();

    var robot = warehouse.locationOfScalar('@').?;

    // Let robot shift things around
    for (instruction_str) |i| {
        if (i == '\n') continue;
        const there = switch (i) {
            '^' => grid.N,
            '>' => grid.E,
            'v' => grid.S,
            '<' => grid.W,
            else => unreachable,
        };
        var attempt = robot.translate(there);
        while (warehouse.get(attempt).? == 'O') attempt = attempt.translate(there);
        if (warehouse.get(attempt).? == '.') {
            const back = there.inverse();
            while (!attempt.equals(robot)) {
                const swap = attempt;
                attempt = attempt.translate(back);
                warehouse.swapValues(swap, attempt);
            }
            robot = robot.translate(there);
        } // else blocked and don't move
    }

    const items = warehouse.locationsOfScalar(allocator, 'O');
    defer allocator.free(items);
    var gps_sum: u64 = 0;
    for (items) |item| {
        gps_sum += @intCast(item.x + item.y * 100);
    }

    return gps_sum;
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    var input_iterator = mem.tokenizeSequence(u8, input, "\n\n");
    const warehouse_str = input_iterator.next().?;
    const instruction_str = input_iterator.next().?;

    var warehouse_s = grid.ByteGrid.parse(allocator, warehouse_str);
    defer warehouse_s.deinit();

    var warehouse = grid.ByteGrid.init(allocator, warehouse_s.width * 2, warehouse_s.height, null);
    defer warehouse.deinit();
    for (0..warehouse_s.bytes.len) |i| {
        const scaled: *const [2:0]u8 = switch (warehouse_s.bytes[i]) {
            '#' => "##",
            '.' => "..",
            'O' => "[]",
            '@' => "@.",
            else => unreachable,
        };
        mem.copyForwards(u8, warehouse.bytes[i * 2 .. (i + 1) * 2], scaled);
    }

    var robot = warehouse.locationOfScalar('@').?;

    // Let robot shift things around
    for (instruction_str) |i| {
        if (i == '\n') continue;
        const there = switch (i) {
            '^' => grid.N,
            '>' => grid.E,
            'v' => grid.S,
            '<' => grid.W,
            else => unreachable,
        };
        const step = robot.translate(there);
        if (warehouse.get(step).? == '#') continue;
        if (warehouse.get(step).? == '.') {
            warehouse.swapValues(robot, step);
            robot = step;
        } else if (there.y == 0) {
            var attempt = step;
            while (warehouse.get(attempt).? == '[' or warehouse.get(attempt).? == ']') attempt = attempt.translate(there);
            if (warehouse.get(attempt).? == '.') {
                const back = there.inverse();
                while (!attempt.equals(robot)) {
                    const swap = attempt;
                    attempt = attempt.translate(back);
                    warehouse.swapValues(swap, attempt);
                }
                robot = robot.translate(there);
            }
        } else {
            var stack = std.ArrayList(std.AutoArrayHashMap(grid.Vec2, void)).initCapacity(allocator, 16) catch unreachable;
            defer stack.deinit();
            defer for (stack.items) |*map| map.deinit();

            var attempt = std.AutoArrayHashMap(grid.Vec2, void).init(allocator);
            attempt.put(robot, {}) catch unreachable;

            var blocked = false;
            attempt: while (attempt.keys().len > 0) {
                var next = std.AutoArrayHashMap(grid.Vec2, void).init(allocator);
                next.ensureTotalCapacity(attempt.keys().len * 2) catch unreachable;
                for (attempt.keys()) |item| {
                    const swap = item.translate(there);
                    switch (warehouse.get(swap).?) {
                        '#' => {
                            next.deinit();
                            blocked = true;
                            break :attempt;
                        },
                        '.' => {}, // Do nothing!
                        '[' => {
                            next.putAssumeCapacity(swap, {});
                            next.putAssumeCapacity(swap.translate(grid.E), {});
                        },
                        ']' => {
                            next.putAssumeCapacity(swap.translate(grid.W), {});
                            next.putAssumeCapacity(swap, {});
                        },
                        else => unreachable,
                    }
                }
                stack.append(attempt) catch unreachable;
                attempt = next;
            }
            attempt.deinit(); // Last, empty step
            if (!blocked) {
                while (stack.items.len > 0) {
                    var swap = stack.pop();
                    for (swap.keys()) |item| {
                        warehouse.swapValues(item, item.translate(there));
                    }
                    swap.deinit();
                }

                robot = robot.translate(there);
            }
        } // else blocked and don't move
    }

    const items = warehouse.locationsOfScalar(allocator, '[');
    defer allocator.free(items);
    var gps_sum: u64 = 0;
    for (items) |item| {
        gps_sum += @intCast(item.x + item.y * 100);
    }

    return gps_sum;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(10092, result);
}

test "part_2.sample_1" {
    const result = part_two(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(9021, result);
}

const sample_1: []const u8 =
    \\##########
    \\#..O..O.O#
    \\#......O.#
    \\#.OO..O.O#
    \\#..O@..O.#
    \\#O#..O...#
    \\#O..O..O.#
    \\#.OO.O.OO#
    \\#....O...#
    \\##########
    \\
    \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
    \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
    \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
    \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
    \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
    \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
    \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
    \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
    \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
    \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
    \\
;
