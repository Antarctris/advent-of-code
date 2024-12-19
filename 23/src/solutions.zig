const std = @import("std");

const Solution = @import("./solutions/solution.zig");

pub fn get(index: usize) ?Solution {
    return switch (index) {
        0 => @import("./solutions/day00.zig").solution,
        1 => @import("./solutions/day01.zig").solution,
        2 => @import("./solutions/day02.zig").solution,
        else => null,
    };

}

test {
    std.testing.refAllDecls(@This());
}
