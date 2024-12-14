const std = @import("std");

const Solution = @import("./solutions/solution.zig");

pub fn get(index: usize) ?Solution {
    return switch (index) {
        0 => @import("./solutions/day00.zig").solution,
        1 => @import("./solutions/day01.zig").solution,
        2 => @import("./solutions/day02.zig").solution,
        3 => @import("./solutions/day03.zig").solution,
        4 => @import("./solutions/day04.zig").solution,
        5 => @import("./solutions/day05.zig").solution,
        6 => @import("./solutions/day06.zig").solution,
        7 => @import("./solutions/day07.zig").solution,
        8 => @import("./solutions/day08.zig").solution,
        9 => @import("./solutions/day09.zig").solution,
        10 => @import("./solutions/day10.zig").solution,
        11 => @import("./solutions/day11.zig").solution,
        12 => @import("./solutions/day12.zig").solution,
        13 => @import("./solutions/day13.zig").solution,
        14 => @import("./solutions/day14.zig").solution,
        else => null,
    };

}

test {
    std.testing.refAllDecls(@This());
}
