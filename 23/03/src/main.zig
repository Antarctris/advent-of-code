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
    var engine_schematic = EngineSchematic.init(allocator, input);
    defer engine_schematic.deinit();
    return .{ engine_schematic.partSum(), engine_schematic.gearSum() };
}

const EngineSchematic = struct {
    allocator: Allocator,
    schematic: []const u8,
    width: usize,
    height: usize,
    parts: []Part,

    const Number = struct { i: usize, len: usize };
    const Part = struct { value: u32, symbol: usize };

    pub fn init(allocator: Allocator, input: []const u8) EngineSchematic {
        var es = EngineSchematic{
            .allocator = allocator,
            .schematic = input,
            .width = mem.indexOfScalar(u8, input, '\n') orelse unreachable,
            .height = mem.count(u8, input, "\n"),
            .parts = &.{},
        };
        es.initParts();
        return es;
    }

    pub fn deinit(self: *EngineSchematic) void {
        self.allocator.free(self.parts);
    }

    pub fn partSum(self: EngineSchematic) u32 {
        var sum: u32 = 0;
        for (self.parts) |part| {
            sum += part.value;
        }
        return sum;
    }

    pub fn gearSum(self: EngineSchematic) u32 {
        var sum: u32 = 0;
        const GearEntry = struct { count: u8, ratio: u32 };
        var gearMap = std.AutoArrayHashMap(usize, GearEntry).init(self.allocator);
        defer gearMap.deinit();

        for (self.parts) |part| {
            if (self.schematic[part.symbol] == '*') {
                if (gearMap.get(part.symbol)) |entry| {
                    gearMap.put(part.symbol, GearEntry{ .count = entry.count + 1, .ratio = entry.ratio * part.value }) catch unreachable;
                } else {
                    gearMap.put(part.symbol, GearEntry{ .count = 1, .ratio = part.value }) catch unreachable;
                }
            }
        }
        for (gearMap.values()) |gear| {
            if (gear.count == 2) {
                sum += gear.ratio;
            }
        }
        return sum;
    }

    fn initParts(self: *EngineSchematic) void {
        var partList = std.ArrayList(Part).init(self.allocator);
        var current: ?usize = null;
        for (self.schematic, 0..) |char, index| {
            if (util.isDigit(char) and current == null) {
                current = index;
            }
            if (!util.isDigit(char) and current != null) {
                const number = Number{ .i = current.?, .len = index - current.? };
                if (self.isPart(number)) |symbol| {
                    const value = std.fmt.parseInt(u32, self.schematic[number.i .. number.i + number.len], 10) catch unreachable;
                    partList.append(Part{ .value = value, .symbol = symbol }) catch unreachable;
                }
                current = null;
            }
        }
        self.parts = partList.items; // Super dirty...
    }

    fn isPart(self: EngineSchematic, number: Number) ?usize {
        const offset: usize = self.width + 1;
        // Left/right
        const left = if (number.i > 0) number.i - 1 else 0;
        if (isSymbol(self.schematic[left])) return left;
        const right = if (number.i + number.len < self.schematic.len) number.i + number.len else self.schematic.len - 1;
        if (isSymbol(self.schematic[right])) return right;
        // Top row
        if (left >= offset) {
            const topleft: usize = left - offset;
            const topright: usize = right - offset;
            for (topleft..topright + 1) |i| {
                if (isSymbol(self.schematic[i])) return i;
            }
        }
        // Bottom row
        if (right + offset < self.schematic.len) {
            const botleft: usize = left + offset;
            const botright: usize = right + offset;
            for (botleft..botright + 1) |i| {
                if (isSymbol(self.schematic[i])) return i;
            }
        }

        return null;
    }

    fn isSymbol(char: u8) bool {
        return (!util.isDigit(char) and char != '.' and char != '\n');
    }
};

const sample_1: []const u8 =
    \\467..114..
    \\...*......
    \\..35..633.
    \\......#...
    \\617*......
    \\.....+.58.
    \\..592.....
    \\......755.
    \\...$.*....
    \\.664.598..
    \\
;

test "part_1.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(4361, solution[0]);
}

test "part_2.sample_1" {
    const solution = solveChallenge(std.testing.allocator, sample_1);
    try std.testing.expectEqual(467835, solution[1]);
}
