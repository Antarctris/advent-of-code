const std = @import("std");

pub const Result = union(enum) {
    Empty,
    Number: u64,
    String: struct {
        allocator: std.mem.Allocator,
        bytes: []u8,
    },

    pub fn number(n: u64) Result {
        return .{ .Number = n };
    }

    pub fn string(allocator: std.mem.Allocator, msg: []const u8) !Result {
        return .{
            .String = .{
                .allocator = allocator,
                .bytes = try allocator.dupe(u8, msg),
            },
        };
    }

    pub fn deinit(self: *Result) void {
        switch (self.*) {
            .String => |s| s.allocator.free(s.bytes),
            else => {},
        }
        self.* = .Empty;
    }
};

const Solution = @This();

vtable: *const VTable,

pub const VTable = struct {
    title: *const fn () []const u8,
    part_one: *const fn (allocator: std.mem.Allocator, input: []const u8) Result,
    part_two: *const fn (allocator: std.mem.Allocator, input: []const u8) Result,

    pub fn init(T: type) *const VTable {
        const table = &struct {
            fn title() []const u8 {
                return T.title();
            }
            fn part_one(allocator: std.mem.Allocator, input: []const u8) Result {
                return T.part_one(allocator, input);
            }
            fn part_two(allocator: std.mem.Allocator, input: []const u8) Result {
                return T.part_two(allocator, input);
            }
        };
        return &.{
            .title = table.title,
            .part_one = table.part_one,
            .part_two = table.part_two,
        };
    }
};

pub fn title(self: Solution) []const u8 {
    return self.vtable.title();
}

pub fn part_one(self: Solution, allocator: std.mem.Allocator, input: []const u8) Result {
    return self.vtable.part_one(allocator, input);
}

pub fn part_two(self: Solution, allocator: std.mem.Allocator, input: []const u8) Result {
    return self.vtable.part_two(allocator, input);
}
