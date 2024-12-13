const std = @import("std");

const Solution = @This();

vtable: *const VTable,

pub const VTable = struct {
    part_one: *const fn (allocator: std.mem.Allocator, input: []const u8) ?u64,
    part_two: *const fn (allocator: std.mem.Allocator, input: []const u8) ?u64,

    pub fn init(T: type) *const VTable {
        const table = &struct {
            fn part_one(allocator: std.mem.Allocator, input: []const u8) ?u64 {
                return T.part_one(allocator, input);
            }
            fn part_two(allocator: std.mem.Allocator, input: []const u8) ?u64 {
                return T.part_two(allocator, input);
            }
        };
        return &.{
            .part_one = table.part_one,
            .part_two = table.part_two,
        };
    }
};

pub fn part_one(self: Solution, allocator: std.mem.Allocator, input: []const u8) ?u64 {
    return self.vtable.part_one(allocator, input);
}

pub fn part_two(self: Solution, allocator: std.mem.Allocator, input: []const u8) ?u64 {
    return self.vtable.part_two(allocator, input);
}
