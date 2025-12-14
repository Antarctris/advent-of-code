const Self = @This();

// imports
const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

const util = @import("util");
const Solution = @import("./solution.zig");

// interface
pub const solution: Solution = .{ .vtable = Solution.VTable.init(Self) };

pub fn title() []const u8 {
    return "Day 10: Factory";
}

pub fn part_one(allocator: Allocator, input: []const u8) !Solution.Result {
    _ = allocator;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');

    var buttons_pressed_total: u64 = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        var machine = try Machine.parse(line);

        var buttons_pressed_min: u64 = std.math.maxInt(u64);
        // Use integers, where each button-to-press is represented as a bit set to 1
        // Use shift operation to get the upper limit of all possible button-configurations.
        const button_configurations = @as(u64, 1) << @as(u6, @intCast(machine.buttons_len));
        for (0..button_configurations) |c| {
            if (tryReachToggleConfig(machine.lights, machine.buttons(), c)) |n| {
                buttons_pressed_min = @min(buttons_pressed_min, n);
            }
        }
        buttons_pressed_total += buttons_pressed_min;
    }
    return Solution.Result.number(buttons_pressed_total);
}

pub fn tryReachToggleConfig(target: Config, buttons: []const Config, button_indices: u64) ?u64 {
    const current, const buttons_pressed = applyToggleConfig(CONFIG_ZERO, buttons, button_indices);
    if (@reduce(.And, current == target)) {
        return buttons_pressed;
    }
    return null;
}

pub fn applyToggleConfig(c: Config, buttons: []const Config, button_indices: u64) struct { Config, u64 } {
    var current = c;
    var buttons_pressed: u64 = 0;
    for (buttons, 0..) |b, i| {
        if (@mod(button_indices >> @intCast(i), 2) == 1) {
            current ^= b;
            buttons_pressed += 1;
        }
    }
    return .{ current, buttons_pressed };
}

// After trying both Dijkstra and A*, the main problem seemed to be memory usage,
// since it just used up all my memory and froze the system. Therefore I decided to try
// some more memory efficient method and do some depth-first-approach, so I decided to
// search for a method to solve it recursive. The simple brute-force recursion was too slow
// of course and memoization wasn't helpful since I could never decide if a button combination
// was truly the shortest. So I ditched the idea of using the buttons as recursive step
// and looked back at the actual problem vector (joltage).
//
// There I thought for a looong time on how I could divide this into smaller, solvable
// problems. After considering GCD, some "test-upper-and-lower-boundaries" and even packing
// it in equations and trying to get a partial solution through Gaussian elimination,
// I finally found something.
//
// I observed that the odd numbers in the target vector could be treated as the lights from
// part 1. So I brute-forced all partial solutions of the odd numbers and applied them to my
// target, where I got remainders of only even numbers. All of them could be divided by two
// and then the process could be repeated for the smaller targets, efficiently halving the
// problem at each step. The presses from brute-forcing the odds and two times the result
// from the recursion (since we halved them before) give me the minimum for the associated
// button-presses-configuration. From all brute-forced partial solutions take the smallest.
//
// With this I could somewhat efficiently limit the necessary brute-forcing to much bigger
// steps and get to depth very quickly.
pub fn part_two(allocator: Allocator, input: []const u8) !Solution.Result {
    _ = allocator;
    var line_iterator = mem.tokenizeScalar(u8, input, '\n');

    var buttons_pressed_total: u64 = 0;
    while (line_iterator.next()) |line| {
        if (line.len == 0) continue;
        var machine = try Machine.parse(line);
        buttons_pressed_total += bruteforceLog2MinButtons(
            machine.joltage,
            machine.buttons(),
        ) orelse unreachable;
    }
    return Solution.Result.number(buttons_pressed_total);
}

pub fn bruteforceLog2MinButtons(target: Config, buttons: []const Config) ?u64 {
    if (@reduce(.And, target == CONFIG_ZERO)) return 0;
    // Take only the odds
    const current = target % @as(Config, @splat(2));
    var buttons_pressed_min: u64 = std.math.maxInt(u64);
    const button_configurations = @as(u64, 1) << @as(u6, @intCast(buttons.len));
    // Brute-force the odds
    for (0..button_configurations) |c| {
        if (tryReachToggleConfig(current, buttons, c)) |n| {
            // For each solution to the odds, perform recursion if the remainder is valid
            if (applyRemainderConfig(target, buttons, c)) |remainder| {
                if (bruteforceLog2MinButtons(remainder, buttons)) |rem| {
                    const min = n + 2 * rem;
                    buttons_pressed_min = @min(buttons_pressed_min, min);
                }
            }
        }
    }
    if (buttons_pressed_min == std.math.maxInt(u64)) return null;
    return buttons_pressed_min;
}

pub fn applyRemainderConfig(c: Config, buttons: []const Config, button_indices: u64) ?Config {
    var current = c;
    for (buttons, 0..) |b, i| {
        if (@mod(button_indices >> @intCast(i), 2) == 1) {
            if (@reduce(.Or, b > current)) return null;
            current -= b;
        }
    }
    // Division by two without zig compiler bullying me about floating point numbers.
    return current >> @splat(1);
}

const MAX_LIGHTS = 12;
const MAX_BUTTONS = 16;

const Config = @Vector(MAX_LIGHTS, u16);
const CONFIG_ZERO: Config = @splat(0);

const Machine = struct {
    lights: Config,
    buttons_buf: [MAX_BUTTONS]Config,
    buttons_len: usize,
    joltage: Config,

    pub fn parse(input: []const u8) !Machine {
        var input_iterator = std.mem.tokenizeScalar(u8, input, ' ');
        const light_str = input_iterator.next().?[1..];
        var lights = CONFIG_ZERO;
        for (0..light_str.len - 1) |i| {
            lights[i] = if (light_str[i] == '#') 1 else 0;
        }
        var buttons_buf: [MAX_BUTTONS]Config = undefined;
        var buttons_len: usize = 0;
        while (input_iterator.next()) |str| {
            if (input_iterator.peek() != null) {
                const button_str = str[1 .. str.len - 1];
                var button = CONFIG_ZERO;
                for (button_str) |c| {
                    if (c == ',') continue;
                    button[c - '0'] = 1;
                }
                buttons_buf[buttons_len] = button;
                buttons_len += 1;
            } else {
                var joltage_iterator = std.mem.tokenizeScalar(u8, str[1 .. str.len - 1], ',');
                var joltage = CONFIG_ZERO;
                var i: usize = 0;
                while (joltage_iterator.next()) |joltage_str| : (i += 1) {
                    joltage[i] = try std.fmt.parseInt(u16, joltage_str, 10);
                }
                return Machine{
                    .lights = lights,
                    .buttons_buf = buttons_buf,
                    .buttons_len = buttons_len,
                    .joltage = joltage,
                };
            }
        }
        return error.MachineParsingError;
    }

    pub fn buttons(self: *Machine) []const Config {
        return self.buttons_buf[0..self.buttons_len];
    }

    pub fn print(self: *Machine) void {
        util.testonly.print("\nMachine:\n{any} LIGHTS\n{any} JOLTAGE\n", .{ self.lights, self.joltage });
        for (self.buttons()) |button| {
            util.testonly.print("{any}\n", .{button});
        }
    }
};

test "part_1.sample_1" {
    var result = try part_one(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(7, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

test "part_2.sample_1" {
    var result = try part_two(std.testing.allocator, sample_1);
    defer result.deinit();
    switch (result) {
        .Empty => return error.SkipZigTest,
        .Number => |n| try std.testing.expectEqual(33, n),
        .String => |s| try std.testing.expectEqualStrings("", s.bytes),
    }
}

const sample_1: []const u8 =
    \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
    \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
    \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    \\
;
