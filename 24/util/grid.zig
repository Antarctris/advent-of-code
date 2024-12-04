const std = @import("std");
const mem = std.mem;

const Allocator = std.mem.Allocator;

pub const Point = struct {
    x: i64,
    y: i64,

    pub fn translate(self: Point, other: Point) Point {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn tranlateTimes(self: Point, other: Point, times: i64) Point {
        return .{ .x = self.x + other.x * times, .y = self.y + other.y * times };
    }

    pub fn inverse(self: Point) Point {
        return .{ .x = self.x * -1, .y = self.y * -1 };
    }

    // See https://en.wikipedia.org/wiki/Determinant
    // Also useful for https://en.wikipedia.org/wiki/Shoelace_formula#Other_formulas_2
    pub fn determinant(self: Point, other: Point) i64 {
        return self.x * other.y - self.y * other.x;
    }

    pub fn equals(self: Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }

    // Orthogonal only distance, see https://en.wikipedia.org/wiki/Taxicab_geometry
    pub fn manhattanDistance(self: Point, other: Point) u64 {
        return @intCast(@abs(self.x - other.x) + @abs(self.y - other.y));
    }

    // Ortho- and diagonal distance, see https://en.wikipedia.org/wiki/Chebyshev_distance
    pub fn chebyshevDistance(self: Point, other: Point) u64 {
        return @intCast(@max(@abs(self.x - other.x), @abs(self.y - other.y)));
    }

    // Euclidean distance (pythagorean), see https://en.wikipedia.org/wiki/Euclidean_distanctarstoa
    pub fn euclideanDistance(self: Point, other: Point) f64 {
        const a: f64 = @intCast(self.x - other.x);
        const b: f64 = @intCast(self.y - other.y);
        return @sqrt(a * a + b * b);
    }
};

pub const N = Point{ .x = 0, .y = -1 };
pub const E = Point{ .x = 1, .y = 0 };
pub const S = Point{ .x = 0, .y = 1 };
pub const W = Point{ .x = -1, .y = 0 };
pub const CardinalDirections: [4]Point = .{ N, E, S, W };
pub const NE = N.translate(E);
pub const SE = S.translate(E);
pub const SW = S.translate(W);
pub const NW = N.translate(W);
pub const OrdinalDirections: [4]Point = .{ NE, SE, SW, NW };
pub const OctagonalDirections: [8]Point = .{ N, NE, E, SE, S, SW, W, NW };

pub const CharGrid = struct {
    allocator: Allocator,
    height: u64,
    width: u64,
    bytes: []u8,

    pub fn init(allocator: Allocator, input: []const u8) CharGrid {
        // Files usually end with a final \n and therefore an additional empty line, meaning every
        // meaningful line is terminated with \n and this can be used to count meaningful lines.
        const height = std.mem.count(u8, input, "\n") + @intFromBool(input[input.len - 1] != '\n');
        const width = std.mem.indexOf(u8, input, "\n").?;
        var bytes = allocator.alloc(u8, height * width) catch unreachable;

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

    pub fn switchRowsAndCols(self: CharGrid) CharGrid {
        var bytes = self.allocator.alloc(u8, self.height * self.width) catch unreachable;
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

    pub fn deinit(self: CharGrid) void {
        self.allocator.free(self.bytes);
    }

    pub fn byteIndexOf(self: CharGrid, x: u64, y: u64) u64 {
        return y * self.width + x;
    }

    pub fn isInBounds(self: CharGrid, p: Point) bool {
        return p.x >= 0 and p.y >= 0 and p.x < self.width and p.y < self.height;
    }

    pub fn pointOf(self: CharGrid, needle: []const u8) ?Point {
        var y: u64 = 0;
        while (y < self.height) : (y += 1) {
            if (std.mem.indexOf(u8, self.bytes[y * self.width .. (y + 1) * self.width], needle)) |x| {
                return Point{ .x = @intCast(x), .y = @intCast(y) };
            }
        }
        return null;
    }

    pub fn count(self: CharGrid, needle: []const u8) u64 {
        var sum: u64 = 0;
        var y: u64 = 0;
        while (y < self.height) : (y += 1) {
            sum += std.mem.count(u8, self.bytes[y * self.width .. (y + 1) * self.width], needle);
        }
        return sum;
    }

    pub fn countDirections(self: CharGrid, needle: []const u8, directions: []const Point) u64 {
        var sum: u64 = 0;
        for (0..self.height) |y| {
            var index = Point{ .x = 0, .y = @intCast(y) };
            while (index.x < self.width) : (index = index.translate(E)) {
                sum += self.countDirectionsAt(index, needle, directions);
            }
        }
        return sum;
    }

    pub fn countDirectionsAt(self: CharGrid, point: Point, needle: []const u8, directions: []const Point) u64 {
        var sum: u64 = 0;
        for (directions) |direction| {
            if (self.isInBounds(point.tranlateTimes(direction, @intCast(needle.len - 1)))) {
                var p = point;
                var i: usize = 0;
                while (i < needle.len and self.get(p) == needle[i]) {
                    i += 1;
                    p = p.translate(direction);
                }
                sum += @intFromBool(i == needle.len);
            }
        }
        return sum;
    }

    pub fn get(self: CharGrid, p: Point) ?u8 {
        if (p.x < 0 or p.y < 0) return null;
        return self.bytes[self.byteIndexOf(@intCast(p.x), @intCast(p.y))];
    }

    pub fn set(self: CharGrid, p: Point, value: u8) void {
        self.bytes[self.byteIndexOf(@intCast(p.x), @intCast(p.y))] = value;
    }

    pub fn row(self: CharGrid, index: usize) []const u8 {
        return self.bytes[index * self.width .. (index + 1) * self.width];
    }
};
