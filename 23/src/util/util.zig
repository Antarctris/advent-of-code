const std = @import("std");

pub const graph = @import("graph.zig");
pub const grid = @import("grid.zig");
pub const math = @import("math.zig");
pub const mem = @import("mem.zig");

pub fn parseNumbersScalar(allocator: std.mem.Allocator, comptime T: type, base: u8, string: []const u8, delimiter: u8) []T {
    var numbers = std.ArrayList(T).init(allocator);
    defer numbers.deinit();
    var iterator = std.mem.tokenizeScalar(u8, string, delimiter);
    while (iterator.next()) |num_str| {
        const number = std.fmt.parseInt(T, num_str, base) catch unreachable;
        numbers.append(number) catch unreachable;
    }
    return allocator.dupe(T, numbers.items) catch unreachable;
}

pub fn parseNumbers(allocator: std.mem.Allocator, comptime T: type, string: []const u8, base: u8) []T {
    var numbers = std.ArrayList(T).init(allocator);
    defer numbers.deinit();
    var iterator = std.mem.tokenizeScalar(u8, string, ' ');
    while (iterator.next()) |num_str| {
        const number = std.fmt.parseInt(T, num_str, base) catch unreachable;
        numbers.append(number) catch unreachable;
    }
    return allocator.dupe(T, numbers.items) catch unreachable;
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
