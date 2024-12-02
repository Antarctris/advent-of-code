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
    var line_iterator = mem.splitScalar(u8, input, '\n');
    const instructions = line_iterator.next().?;

    var map = std.StringHashMap(Node).init(allocator);
    defer map.deinit();
    var nodes = std.ArrayList(*const [3]u8).init(allocator);
    defer nodes.deinit();

    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        map.put(line[0..3], Node{ .left = line[7..10], .right = line[12..15] }) catch unreachable;
        if (line[2] == 'A') {
            nodes.append(line[0..3]) catch unreachable;
        }
    }

    var current_one: *const [3]u8 = "AAA";
    var steps_one: u64 = 0;
    while (!mem.eql(u8, current_one, "ZZZ")) : (steps_one += 1) {
        current_one = map.get(current_one).?.n(instructions[@mod(steps_one, instructions.len)]);
    }

    var steps_two: u64 = 1;
    for (0..nodes.items.len) |node| {
        var z: ?*const [3]u8 = null;
        var zs: u64 = 0;
        var zi: u64 = std.math.maxInt(u64);
        var current: *const [3]u8 = nodes.items[node];
        var i: u64 = 0;
        var s: u64 = 0;
        while (z == null or !(std.mem.eql(u8, current, z.?) and zi == @mod(s, instructions.len))) : ({
            current = map.get(current).?.n(instructions[i]);
            s += 1;
        }) {
            i = @mod(s, instructions.len);
            if (current[2] == 'Z' and zs == 0) {
                z = current;
                zs = s;
                zi = i;
            }
        }
        steps_two = lcm(steps_two, zs);
    }

    return .{ steps_one, steps_two };
}

const Node = struct {
    left: *const [3]u8,
    right: *const [3]u8,

    fn n(self: Node, instruction: u8) *const [3]u8 {
        return switch (instruction) {
            'L' => self.left,
            'R' => self.right,
            else => unreachable,
        };
    }
};

fn wholeListEndingScalar(list: []*const [3]u8, scalar: u8) bool {
    for (list) |entry| {
        if (entry[2] != scalar) return false;
    }
    return true;
}

fn lcm(a: u64, b: u64) u64 {
    return @abs(a) * (@abs(b) / std.math.gcd(a, b));
}

const sample_1: []const u8 =
    \\RL
    \\
    \\AAA = (BBB, CCC)
    \\BBB = (DDD, EEE)
    \\CCC = (ZZZ, GGG)
    \\DDD = (DDD, DDD)
    \\EEE = (EEE, EEE)
    \\GGG = (GGG, GGG)
    \\ZZZ = (ZZZ, ZZZ)
    \\
;

const sample_2: []const u8 =
    \\LLR
    \\
    \\AAA = (BBB, BBB)
    \\BBB = (AAA, ZZZ)
    \\ZZZ = (ZZZ, ZZZ)
    \\
;

const sample_3: []const u8 =
    \\LR
    \\
    \\AAA = (11B, XXX)
    \\11B = (XXX, ZZZ)
    \\ZZZ = (11B, XXX)
    \\22A = (22B, XXX)
    \\22B = (22C, 22C)
    \\22C = (22Z, 22Z)
    \\22Z = (22B, 22B)
    \\XXX = (XXX, XXX)
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(2, solution[0]);
}

test "part_1.sample_2" {
    const solution = solveChallenge(std.testing.allocator, sample_2);
    try std.testing.expectEqual(6, solution[0]);
}

test "part_2.sample_3" {
    const solution = solveChallenge(std.testing.allocator, sample_3);
    try std.testing.expectEqual(6, solution[1]);
}
