const std = @import("std");

pub fn sumTo(comptime T: type, n: T) T {
    return sumRange(T, 0, n);
}

/// Calculates the sum of consecutive numbers from i (inclusive) to n (exclusive).
pub fn sumRange(comptime T: type, i: T, n: T) T {
    return (i + n - 1) * (n - i) / 2;
}
