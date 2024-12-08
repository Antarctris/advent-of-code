const std = @import("std");

pub fn sumTo(comptime T: type, n: T) T {
    return (n * (n + 1)) / 2;
}
