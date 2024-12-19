const std = @import("std");

const Solution = @import("./solutions/solution.zig");

pub fn get(index: usize) ?Solution {
    return switch (index) {
        0 => @import("./solutions/day00.zig").solution,
        else => null,
    };

}

test {
    std.testing.refAllDecls(@This());
}