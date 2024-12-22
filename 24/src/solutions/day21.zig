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
    return "Day 21: Keypad Conundrum";
}

pub fn part_one(allocator: Allocator, input: []const u8) ?u64 {
    return calculateRemoteCodeComplexity(allocator, input, 2);
}

pub fn part_two(allocator: Allocator, input: []const u8) ?u64 {
    return calculateRemoteCodeComplexity(allocator, input, 25);
}

fn calculateRemoteCodeComplexity(allocator: Allocator, input: []const u8, relays: u64) u64 {
    var total_code_complexity: u64 = 0;

    var memo = std.AutoHashMap(Node, u64).init(allocator);
    defer memo.deinit();

    var line_iterator = mem.tokenizeScalar(u8, input, '\n');
    while (line_iterator.next()) |line| {
        const code_num = std.fmt.parseInt(u64, line[0..3], 10) catch unreachable;
        var code_len: u64 = 0;

        const remote = getShortestRouteKeypad(allocator, line);
        defer allocator.free(remote);
        var last = A;
        for (remote) |vec| {
            code_len += getInstructionCount(&memo, Node.from(relays, last, vec));
            last = vec;
        }

        const complexity = code_num * code_len;
        total_code_complexity += complexity;
    }
    return total_code_complexity;
}

const num_keypad = [_]grid.Vec2{
    .{ .x = 1, .y = 3 }, // 0
    .{ .x = 0, .y = 2 }, // 1
    .{ .x = 1, .y = 2 },
    .{ .x = 2, .y = 2 },
    .{ .x = 0, .y = 1 },
    .{ .x = 1, .y = 1 }, // 5
    .{ .x = 2, .y = 1 },
    .{ .x = 0, .y = 0 },
    .{ .x = 1, .y = 0 },
    .{ .x = 2, .y = 0 },
    .{ .x = 2, .y = 3 }, // A
};

// Directional keypad
const A = grid.Vec2{ .x = 2, .y = 0 };
const N = grid.Vec2{ .x = 1, .y = 0 };
const W = grid.Vec2{ .x = 0, .y = 1 };
const S = grid.Vec2{ .x = 1, .y = 1 };
const E = grid.Vec2{ .x = 2, .y = 1 };

fn getShortestRouteKeypad(allocator: Allocator, line: []const u8) []grid.Vec2 {
    var remote = std.ArrayList(grid.Vec2).init(allocator);
    defer remote.deinit();
    var last = num_keypad[0xA];
    for (line) |c| {
        const vec = num_keypad[@min(c - '0', 0xA)];
        const translation = vec.translate(last.inverse());
        // Special cases for evasion of empty field
        if (vec.x == 0 and last.y == 3) {
            // ^ <
            for (0..@abs(translation.y)) |_| remote.append(N) catch unreachable;
            for (0..@abs(translation.x)) |_| remote.append(W) catch unreachable;
        } else if (vec.y == 3 and last.x == 0) {
            // > v
            for (0..@abs(translation.x)) |_| remote.append(E) catch unreachable;
            for (0..@abs(translation.y)) |_| remote.append(S) catch unreachable;
        } else {
            // Normal optimum
            // < v ^ >
            if (translation.x < 0) for (0..@abs(translation.x)) |_| remote.append(W) catch unreachable;
            if (translation.y > 0) for (0..@abs(translation.y)) |_| remote.append(S) catch unreachable;
            if (translation.y < 0) for (0..@abs(translation.y)) |_| remote.append(N) catch unreachable;
            if (translation.x > 0) for (0..@abs(translation.x)) |_| remote.append(E) catch unreachable;
        }
        remote.append(A) catch unreachable;
        last = vec;
    }
    return allocator.dupe(grid.Vec2, remote.items) catch unreachable;
}

const Node = struct {
    times: u64,
    previous: grid.Vec2,
    current: grid.Vec2,

    fn from(times: u64, previous: grid.Vec2, current: grid.Vec2) Node {
        return Node{ .times = times, .previous = previous, .current = current };
    }
};

fn getInstructionCount(memo: *std.AutoHashMap(Node, u64), n: Node) u64 {
    if (memo.get(n)) |count| return count;
    if (n.times == 1) return 1 + n.current.manhattanDistance(n.previous);
    if (n.current.equals(n.previous)) return 1;
    const translation = n.current.translate(n.previous.inverse());
    var count: u64 = 0;
    var last = A;
    if (n.current.x == 0 and n.previous.y == 0) {
        // Special case for evasion of empty field
        // v <
        for (0..@abs(translation.y)) |_| {
            count += getInstructionCount(memo, Node.from(n.times - 1, last, S));
            last = S;
        }
        for (0..@abs(translation.x)) |_| {
            count += getInstructionCount(memo, Node.from(n.times - 1, last, W));
            last = W;
        }
    } else if (n.current.y == 0 and n.previous.x == 0) {
        // Special case for evasion of empty field
        // > ^
        for (0..@abs(translation.x)) |_| {
            count += getInstructionCount(memo, Node.from(n.times - 1, last, E));
            last = E;
        }
        for (0..@abs(translation.y)) |_| {
            count += getInstructionCount(memo, Node.from(n.times - 1, last, N));
            last = N;
        }
    } else {
        // Normal optimum
        // < v ^ >
        if (translation.x < 0) for (0..@abs(translation.x)) |_| {
            count += getInstructionCount(memo, Node.from(n.times - 1, last, W));
            last = W;
        };
        if (translation.y > 0) for (0..@abs(translation.y)) |_| {
            count += getInstructionCount(memo, Node.from(n.times - 1, last, S));
            last = S;
        };
        if (translation.y < 0) for (0..@abs(translation.y)) |_| {
            count += getInstructionCount(memo, Node.from(n.times - 1, last, N));
            last = N;
        };
        if (translation.x > 0) for (0..@abs(translation.x)) |_| {
            count += getInstructionCount(memo, Node.from(n.times - 1, last, E));
            last = E;
        };
    }
    count += getInstructionCount(memo, Node.from(n.times - 1, last, A));
    memo.put(n, count) catch unreachable;
    return count;
}

test "part_1.sample_1" {
    const result = part_one(std.testing.allocator, sample_1) orelse return error.SkipZigTest;
    try std.testing.expectEqual(126384, result);
}

const sample_1: []const u8 =
    \\029A
    \\980A
    \\179A
    \\456A
    \\379A
;

// Original solution of part one
fn getShortestRouteRemote(allocator: Allocator, input: []const grid.Vec2) []grid.Vec2 {
    var remote = std.ArrayList(grid.Vec2).init(allocator);
    defer remote.deinit();
    var last = A;
    for (input) |vec| {
        const translation = vec.translate(last.inverse());
        // Special cases for evasion of empty field
        if (vec.x == 0 and last.y == 0) {
            // v <
            for (0..@abs(translation.y)) |_| remote.append(S) catch unreachable;
            for (0..@abs(translation.x)) |_| remote.append(W) catch unreachable;
        } else if (vec.y == 0 and last.x == 1) {
            // > ^
            for (0..@abs(translation.x)) |_| remote.append(E) catch unreachable;
            for (0..@abs(translation.y)) |_| remote.append(N) catch unreachable;
        } else {
            // Normal optimum
            // < v ^ >
            if (translation.x < 0) for (0..@abs(translation.x)) |_| remote.append(W) catch unreachable;
            if (translation.y > 0) for (0..@abs(translation.y)) |_| remote.append(S) catch unreachable;
            if (translation.y < 0) for (0..@abs(translation.y)) |_| remote.append(N) catch unreachable;
            if (translation.x > 0) for (0..@abs(translation.x)) |_| remote.append(E) catch unreachable;
        }
        remote.append(A) catch unreachable;
        last = vec;
    }
    return allocator.dupe(grid.Vec2, remote.items) catch unreachable;
}
