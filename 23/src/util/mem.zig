const std = @import("std");
const assert = std.debug.assert;

pub fn eqlTolerance(comptime T: type, a: []const T, b: []const T, tolerance: usize) ?usize {
    if (@sizeOf(T) == 0) return 0;
    if (a.len != b.len) return null;
    if (a.len == 0 or a.ptr == b.ptr) return 0;
    var deviations: usize = 0;
    for (a, b) |a_elem, b_elem| {
        if (a_elem != b_elem) deviations += 1;
        if (deviations > tolerance) return null;
    }
    return deviations;
}

pub fn indexOfAnySeries(
    comptime T: type,
    slice: []const T,
    values: []const T,
    series_len: usize,
) ?usize {
    return indexOfAnySeriesPos(T, slice, 0, values, series_len);
}

pub fn indexOfAnySeriesPos(
    comptime T: type,
    slice: []const T,
    start_index: usize,
    values: []const T,
    series_len: usize,
) ?usize {
    if (start_index > slice.len - series_len) return null;
    slice: for (start_index..slice.len - series_len + 1) |i| {
        series: for (i..i + series_len) |si| {
            for (values) |value| {
                if (slice[si] == value) continue :series;
            }
            continue :slice;
        }
        return i;
    }
    return null;
}

pub fn indexAfterAnySeries(
    comptime T: type,
    slice: []const T,
    values: []const T,
    series_len: usize,
) ?usize {
    return indexAfterAnySeriesPos(T, slice, 0, values, series_len);
}

pub fn indexAfterAnySeriesPos(
    comptime T: type,
    slice: []const T,
    start_index: usize,
    values: []const T,
    series_len: usize,
) ?usize {
    if (indexOfAnySeriesPos(T, slice, start_index, values, series_len)) |result| {
        return result + series_len;
    }
    return null;
}

pub fn countAnySeries(
    comptime T: type,
    slice: []const T,
    values: []const T,
    series_len: usize,
) usize {
    assert(series_len > 0);
    var i: usize = 0;
    var found: usize = 0;

    while (indexOfAnySeriesPos(T, slice, i, values, series_len)) |idx| {
        i = idx + series_len;
        found += 1;
    }
}

pub fn sum(comptime T: type, slice: []const T) T {
    if (slice.len == 0) return 0;
    if (slice.len == 1) return slice[0];
    var accumulator: T = slice[0];
    for (1..slice.len) |i| {
        accumulator += slice[i];
    }
    return accumulator;
}

pub fn tokenizeNumbers(comptime T: type, buffer: []const u8) NumberIterator(T) {
    std.debug.assert(buffer.len > 0);
    return .{
        .index = 0,
        .buffer = buffer,
    };
}

pub fn NumberIterator(comptime T: type) type {
    return struct {
        index: usize,
        buffer: []const u8,

        const Self = @This();

        pub fn next(self: *Self) ?T {
            // Move to start of number or end of buffer
            while (self.index < self.buffer.len and (self.buffer[self.index] < '0' or self.buffer[self.index] > '9')) {
                self.index += 1;
            }
            if (self.index == self.buffer.len) return null;

            var acc: T = 0;
            while (self.index < self.buffer.len and self.buffer[self.index] >= '0' and self.buffer[self.index] <= '9') {
                acc = acc * 10 + @as(T, self.buffer[self.index] - '0');
                self.index += 1;
            }
            return acc;
        }
    };
}
