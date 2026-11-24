const std = @import("std");
const mem = std.mem;

const Allocator = std.mem.Allocator;

pub const Vec2 = struct {
    x: i64,
    y: i64,

    pub const Zero = Vec2{ .x = 0, .y = 0 };

    pub fn translate(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn times(self: Vec2, n: i64) Vec2 {
        return .{ .x = self.x * n, .y = self.y * n };
    }

    pub fn inverse(self: Vec2) Vec2 {
        return .{ .x = self.x * -1, .y = self.y * -1 };
    }

    pub fn perpendicular(self: Vec2) Vec2 {
        return .{ .x = self.y, .y = -self.x };
    }

    pub fn abs(self: Vec2) Vec2 {
        return .{ .x = @intCast(@abs(self.x)), .y = @intCast(@abs(self.y)) };
    }

    pub fn min(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = @min(self.x, other.x), .y = @min(self.y, other.y) };
    }

    pub fn max(self: Vec2, other: Vec2) Vec2 {
        return .{ .x = @max(self.x, other.x), .y = @max(self.y, other.y) };
    }

    // See https://en.wikipedia.org/wiki/Determinant
    // Also useful for https://en.wikipedia.org/wiki/Shoelace_formula#Other_formulas_2
    pub fn determinant(self: Vec2, other: Vec2) i64 {
        return self.x * other.y - self.y * other.x;
    }

    pub fn dot(self: Vec2, other: Vec2) i64 {
        return self.x * other.x + self.y * other.y;
    }

    pub fn equals(self: Vec2, other: Vec2) bool {
        return self.x == other.x and self.y == other.y;
    }

    // Orthogonal only distance, see https://en.wikipedia.org/wiki/Taxicab_geometry
    pub fn manhattanDistance(self: Vec2, other: Vec2) u64 {
        return @intCast(@abs(self.x - other.x) + @abs(self.y - other.y));
    }

    // Ortho- and diagonal distance, see https://en.wikipedia.org/wiki/Chebyshev_distance
    pub fn chebyshevDistance(self: Vec2, other: Vec2) u64 {
        return @intCast(@max(@abs(self.x - other.x), @abs(self.y - other.y)));
    }

    // Euclidean distance (pythagorean), see https://en.wikipedia.org/wiki/Euclidean_distanctarstoa
    pub fn euclideanDistance(self: Vec2, other: Vec2) f64 {
        const a: f64 = @floatFromInt(self.x - other.x);
        const b: f64 = @floatFromInt(self.y - other.y);
        return @sqrt(a * a + b * b);
    }
};

pub const N = Vec2{ .x = 0, .y = -1 };
pub const E = Vec2{ .x = 1, .y = 0 };
pub const S = Vec2{ .x = 0, .y = 1 };
pub const W = Vec2{ .x = -1, .y = 0 };
pub const CardinalDirections: [4]Vec2 = .{ N, E, S, W };
pub const NE = N.translate(E);
pub const SE = S.translate(E);
pub const SW = S.translate(W);
pub const NW = N.translate(W);
pub const OrdinalDirections: [4]Vec2 = .{ NE, SE, SW, NW };
pub const OctagonalDirections: [8]Vec2 = .{ N, NE, E, SE, S, SW, W, NW };

pub const ByteGrid = struct {
    allocator: Allocator,
    width: u64,
    height: u64,
    bytes: []u8,

    pub fn init(allocator: Allocator, width: u64, height: u64, initial: ?u8) !ByteGrid {
        var bytes = try allocator.alloc(u8, width * height);
        if (initial) |value| {
            for (0..bytes.len) |index| {
                bytes[index] = value;
            }
        }
        return .{
            .allocator = allocator,
            .width = width,
            .height = height,
            .bytes = bytes,
        };
    }

    pub fn parse(allocator: Allocator, input: []const u8) !ByteGrid {
        // Files usually end with a final \n and therefore an additional empty line, meaning every
        // meaningful line is terminated with \n and this can be used to count meaningful lines.
        const height = std.mem.count(u8, input, "\n") + @intFromBool(input[input.len - 1] != '\n');
        const width = std.mem.indexOf(u8, input, "\n").?;
        var bytes = try allocator.alloc(u8, height * width);

        var line_iterator = std.mem.splitScalar(u8, input, '\n');
        var index: usize = 0;
        while (line_iterator.next()) |line| : (index += width) {
            if (line.len == 0) continue;
            mem.copyForwards(u8, bytes[index .. index + width], line);
        }

        return .{
            .allocator = allocator,
            .height = @intCast(height),
            .width = @intCast(width),
            .bytes = bytes,
        };
    }

    pub fn columnsToRows(self: ByteGrid) !ByteGrid {
        var bytes = try self.allocator.alloc(u8, self.height * self.width);
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                bytes[x * self.height + y] = self.bytes[self.byteIndexOf(x, y)];
            }
        }
        return .{
            .allocator = self.allocator,
            .height = self.width,
            .width = self.height,
            .bytes = bytes,
        };
    }

    pub fn deinit(self: ByteGrid) void {
        self.allocator.free(self.bytes);
    }

    pub fn hash(self: ByteGrid) u64 {
        return std.hash.Wyhash.hash(0, self.bytes);
    }

    pub fn mutateBytes(self: ByteGrid, comptime transform: fn (u8) u8) void {
        for (0..self.bytes.len) |i| {
            self.bytes[i] = transform(self.bytes[i]);
        }
    }

    pub fn mutateBytesContext(self: ByteGrid, comptime Ctx: type, comptime transform: fn (Ctx, u8) u8, context: Ctx) void {
        for (0..self.bytes.len) |i| {
            self.bytes[i] = transform(context, self.bytes[i]);
        }
    }

    pub fn byteIndexOf(self: ByteGrid, x: u64, y: u64) u64 {
        return y * self.width + x;
    }

    pub fn isInBounds(self: ByteGrid, p: Vec2) bool {
        return p.x >= 0 and p.y >= 0 and p.x < self.width and p.y < self.height;
    }

    pub fn corner(self: ByteGrid, d: Vec2) Vec2 {
        return Vec2{ .x = @intCast(@max(d.x, 0) * self.width), .y = @intCast(@max(d.y, 0) * self.height) };
    }

    pub fn scalars(self: ByteGrid, allocator: Allocator) ![]u8 {
        var elements: std.array_hash_map.Auto(u8, void) = .empty;
        defer elements.deinit(self.allocator);

        for (self.bytes) |b| {
            try elements.put(self.allocator, b, {});
        }

        return try allocator.dupe(u8, elements.keys());
    }

    pub fn locationOf(self: ByteGrid, needle: []const u8) ?Vec2 {
        var y: u64 = 0;
        while (y < self.height) : (y += 1) {
            if (std.mem.indexOf(u8, self.bytes[y * self.width .. (y + 1) * self.width], needle)) |x| {
                return Vec2{ .x = @intCast(x), .y = @intCast(y) };
            }
        }
        return null;
    }

    pub fn locationOfScalar(self: ByteGrid, scalar: u8) ?Vec2 {
        return self.locationOf(&.{scalar});
    }

    pub fn locationsOf(self: ByteGrid, allocator: Allocator, needle: []const u8) ![]Vec2 {
        var points: std.ArrayList(Vec2) = .empty;
        if (self.width >= needle.len) {
            errdefer points.deinit(allocator);
            var y: u64 = 0;
            while (y < self.height) : (y += 1) {
                var x: u64 = 0;
                while (x <= self.width - needle.len) : (x += 1) {
                    const index = self.byteIndexOf(x, y);
                    if (std.mem.eql(u8, self.bytes[index .. index + needle.len], needle)) {
                        try points.append(allocator, Vec2{ .x = @intCast(x), .y = @intCast(y) });
                    }
                }
            }
        }
        return points.toOwnedSlice(allocator);
    }

    pub fn locationsOfScalar(self: ByteGrid, allocator: Allocator, scalar: u8) ![]Vec2 {
        return try self.locationsOf(allocator, &.{scalar});
    }

    pub fn neighborsOfRect(self: ByteGrid, allocator: Allocator, a: Vec2, b: Vec2) ![]Vec2 {
        const nw = Vec2{ .x = @min(a.x, b.x) - 1, .y = @min(a.y, b.y) - 1 };
        const se = Vec2{ .x = @max(a.x, b.x) + 1, .y = @max(a.y, b.y) + 1 };
        return try self.borderOfRect(allocator, nw, se);
    }

    pub fn borderOfRect(self: ByteGrid, allocator: Allocator, a: Vec2, b: Vec2) ![]Vec2 {
        var locations: std.ArrayList(Vec2) = .empty;
        errdefer locations.deinit(allocator);
        const nw = Vec2{ .x = @min(a.x, b.x), .y = @min(a.y, b.y) };
        const se = Vec2{ .x = @max(a.x, b.x), .y = @max(a.y, b.y) };
        const width = se.x - nw.x;
        const height = se.y - nw.y;

        var x: i64 = 0;
        var y: i64 = 0;

        while (x < width) : (x += 1) {
            const vec = Vec2{ .x = nw.x + x, .y = nw.y + y };
            if (self.isInBounds(vec)) {
                try locations.append(allocator, vec);
            }
        }
        while (y < height) : (y += 1) {
            const vec = Vec2{ .x = nw.x + x, .y = nw.y + y };
            if (self.isInBounds(vec)) {
                try locations.append(allocator, vec);
            }
        }
        while (x > 0) : (x -= 1) {
            const vec = Vec2{ .x = nw.x + x, .y = nw.y + y };
            if (self.isInBounds(vec)) {
                try locations.append(allocator, vec);
            }
        }
        while (y > 0) : (y -= 1) {
            const vec = Vec2{ .x = nw.x + x, .y = nw.y + y };
            if (self.isInBounds(vec)) {
                try locations.append(allocator, vec);
            }
        }

        return locations.toOwnedSlice(allocator);
    }

    pub fn count(self: ByteGrid, needle: []const u8) u64 {
        var sum: u64 = 0;
        var y: u64 = 0;
        while (y < self.height) : (y += 1) {
            sum += std.mem.count(u8, self.bytes[y * self.width .. (y + 1) * self.width], needle);
        }
        return sum;
    }

    pub fn countScalar(self: ByteGrid, scalar: u8) u64 {
        return self.count(&.{scalar});
    }

    pub fn get(self: ByteGrid, p: Vec2) ?u8 {
        if (!self.isInBounds(p)) return null;
        return self.bytes[self.byteIndexOf(@intCast(p.x), @intCast(p.y))];
    }

    pub fn set(self: ByteGrid, p: Vec2, value: u8) void {
        if (!self.isInBounds(p)) return;
        self.bytes[self.byteIndexOf(@intCast(p.x), @intCast(p.y))] = value;
    }

    pub fn swapValues(self: ByteGrid, a: Vec2, b: Vec2) void {
        if (self.isInBounds(a) and self.isInBounds(b)) {
            mem.swap(
                u8,
                &self.bytes[self.byteIndexOf(@intCast(a.x), @intCast(a.y))],
                &self.bytes[self.byteIndexOf(@intCast(b.x), @intCast(b.y))],
            );
        }
    }

    pub fn row(self: ByteGrid, index: usize) []u8 {
        return self.bytes[index * self.width .. (index + 1) * self.width];
    }

    pub fn print(self: ByteGrid) void {
        std.debug.print("\n", .{});
        for (0..self.height) |r| {
            std.debug.print("{s}\n", .{self.row(r)});
        }
    }

    /// Print rectangle from a to b (both inclusive).
    pub fn printRect(self: ByteGrid, a: Vec2, b: Vec2) void {
        if (!self.isInBounds(a) or !self.isInBounds(b)) return;
        const nw = Vec2{ .x = @min(a.x, b.x), .y = @min(a.y, b.y) };
        const se = Vec2{ .x = @max(a.x, b.x), .y = @max(a.y, b.y) };
        const width: u64 = @intCast(se.x - nw.x + 1);
        const height: u64 = @intCast(se.y - nw.y + 1);

        const x: u64 = @intCast(nw.x);
        const t: u64 = @intCast(nw.y);
        std.debug.print("\n", .{});
        for (t..t + height) |y| {
            std.debug.print("{s}\n", .{self.bytes[self.byteIndexOf(x, y)..self.byteIndexOf(x + width, y)]});
        }
    }
};

test ByteGrid {
    const gpa = std.testing.allocator;
    const grid = try ByteGrid.parse(gpa, "#.#\n.S.\n#.#\n");
    defer grid.deinit();

    try std.testing.expectEqual(3, grid.width);
    try std.testing.expectEqual(3, grid.height);
    try std.testing.expectEqual(Vec2{ .x = 1, .y = 1 }, grid.locationOfScalar('S').?);
    try std.testing.expectEqual(4, grid.countScalar('#'));
    try std.testing.expectEqual('#', grid.get(.Zero).?);
    try std.testing.expectEqual(null, grid.get(W));

    const scalars = try grid.scalars(gpa);
    defer gpa.free(scalars);
    try std.testing.expectEqualSlices(u8, "#.S", scalars);

    const hashes = try grid.locationsOfScalar(gpa, '#');
    defer gpa.free(hashes);
    try std.testing.expectEqual(4, hashes.len);

    const border = try grid.neighborsOfRect(gpa, .{ .x = 1, .y = 1 }, .{ .x = 1, .y = 1 });
    defer gpa.free(border);
    try std.testing.expectEqual(8, border.len);

    const transposed = try grid.columnsToRows();
    defer transposed.deinit();
    try std.testing.expectEqualSlices(u8, grid.bytes, transposed.bytes);
}

test Vec2 {
    const a: Vec2 = .{ .x = 0, .y = 0 };
    const b: Vec2 = .{ .x = 3, .y = -4 };
    try std.testing.expectEqual(7, a.manhattanDistance(b));
    try std.testing.expectEqual(4, a.chebyshevDistance(b));
    try std.testing.expectEqual(5.0, a.euclideanDistance(b));
    try std.testing.expectEqual(E, N.perpendicular().inverse());
}
