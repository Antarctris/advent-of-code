const std = @import("std");

pub fn numeralLength(comptime T: type, n: T, base: T) T {
    const logN: T = @intFromFloat(std.math.log(f64, @floatFromInt(base), @floatFromInt(n)));
    return logN + 1;
}

pub fn numeralLength10(comptime T: type, n: T) T {
    return std.math.log10_int(n) + 1;
}

pub fn sumTo(comptime T: type, n: T) T {
    return sumRange(T, 0, n);
}

/// Calculates the sum of consecutive numbers from i (inclusive) to n (exclusive).
pub fn sumRange(comptime T: type, i: T, n: T) T {
    return (i + n - 1) * (n - i) / 2;
}
