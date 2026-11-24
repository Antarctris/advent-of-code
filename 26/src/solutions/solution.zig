//! Types shared between all day solutions. Import via @import("solution").

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
