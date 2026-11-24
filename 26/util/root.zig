const std = @import("std");
const builtin = @import("builtin");

pub const graph = @import("graph.zig");
pub const grid = @import("grid.zig");
pub const math = @import("math.zig");
pub const mem = @import("mem.zig");

pub const testonly = struct {
    pub fn print(comptime fmt: []const u8, args: anytype) void {
        if (!builtin.is_test) return;
        std.debug.print(fmt, args);
    }
};

pub fn parseNumbersScalar(allocator: std.mem.Allocator, comptime T: type, base: u8, string: []const u8, delimiter: u8) ![]T {
    var numbers: std.ArrayList(T) = .empty;
    errdefer numbers.deinit(allocator);
    var iterator = std.mem.tokenizeScalar(u8, string, delimiter);
    while (iterator.next()) |num_str| {
        try numbers.append(allocator, try std.fmt.parseInt(T, num_str, base));
    }
    return numbers.toOwnedSlice(allocator);
}

pub fn parseNumbers(allocator: std.mem.Allocator, comptime T: type, string: []const u8, base: u8) ![]T {
    return parseNumbersScalar(allocator, T, base, string, ' ');
}

pub fn isDigit(char: u8) bool {
    return intFromDigit(char) != null;
}

pub fn intFromDigit(char: u8) ?u4 {
    return switch (char) {
        '0'...'9' => @intCast(char - '0'),
        else => null,
    };
}

/// Unstable in-place sort, see https://ziglang.org/documentation/0.13.0/std/#std.sort.heapContext
pub fn heapOrder(
    comptime T: type,
    items: []T,
    context: anytype,
    comptime lessThanFn: fn (@TypeOf(context), lhs: T, rhs: T) std.math.Order,
) void {
    const Context = struct {
        items: []T,
        sub_ctx: @TypeOf(context),

        pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
            return lessThanFn(ctx.sub_ctx, ctx.items[a], ctx.items[b]) == std.math.Order.lt;
        }

        pub fn swap(ctx: @This(), a: usize, b: usize) void {
            return std.mem.swap(T, &ctx.items[a], &ctx.items[b]);
        }
    };
    std.sort.heapContext(0, items.len, Context{ .items = items, .sub_ctx = context });
}

test "parseNumbers successfully parses small example" {
    const numbers = try parseNumbers(std.testing.allocator, u32, "1 20  300", 10);
    defer std.testing.allocator.free(numbers);
    try std.testing.expectEqualSlices(u32, &.{ 1, 20, 300 }, numbers);
}

test "isDigit returns false on non-digit" {
    const result = isDigit('A');
    try std.testing.expectEqual(false, result);
}

test "isDigit returns true on digit" {
    const result = isDigit('7');
    try std.testing.expectEqual(true, result);
}

test "heapOrder sorts correctly" {
    var items = [_]u8{ 3, 1, 2 };
    heapOrder(u8, &items, {}, struct {
        fn order(_: void, a: u8, b: u8) std.math.Order {
            return std.math.order(a, b);
        }
    }.order);
    try std.testing.expectEqualSlices(u8, &.{ 1, 2, 3 }, &items);
}

// Common method to test the other files as wel
test {
    std.testing.refAllDecls(@This());
    inline for (.{ graph, grid, math, mem }) |file| std.testing.refAllDecls(file);
}
