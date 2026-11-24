const std = @import("std");

/// Calculates the amount of digits needed to render this number in base 'base'
/// Don't use for very big numbers (15 digits or more), as rounding breaks this from then on.
pub fn numeralLength(comptime T: type, n: T, base: T) T {
    if (n == 0) return 1;
    const logN: T = @intFromFloat(std.math.log(f64, @floatFromInt(base), @floatFromInt(n)));
    return logN + 1;
}

/// Calculates the amount of digits needed to render this number in base 10
pub fn numeralLength10(comptime T: type, n: T) T {
    if (n == 0) return 1;
    return std.math.log10_int(n) + 1;
}

pub fn sumTo(comptime T: type, n: T) T {
    return sumRange(T, 0, n);
}

/// Calculates the sum of consecutive numbers from i (inclusive) to n (exclusive).
pub fn sumRange(comptime T: type, i: T, n: T) T {
    return (i + n - 1) * (n - i) / 2;
}

pub fn VectorExtension(VecT: type) type {
    return switch (@typeInfo(VecT)) {
        .vector => |v_info| struct {
            pub const T = v_info.child;
            pub const vec_len = v_info.len;

            pub const zero: VecT = @splat(0);

            pub fn parseStringScalar(str: []const u8, scalar: u8) !VecT {
                var str_iterator = std.mem.tokenizeScalar(u8, str, scalar);
                // Vectors can't be indexed with runtime indices, so fill an array and coerce.
                var v: [v_info.len]v_info.child = undefined;
                var i: usize = 0;
                while (str_iterator.next()) |n_str| : (i += 1) {
                    if (i >= v_info.len) return error.TooManyElements;
                    v[i] = switch (@typeInfo(v_info.child)) {
                        .int => try std.fmt.parseInt(v_info.child, n_str, 10),
                        .float => try std.fmt.parseFloat(v_info.child, n_str),
                        else => @compileError("Vector must hold int or float."),
                    };
                }
                if (i != v_info.len) return error.NotEnoughElements;
                return v;
            }

            pub fn scale(v: VecT, n: anytype) VecT {
                return v * @as(VecT, @splat(@as(T, n)));
            }

            pub fn inverse(v: VecT) VecT {
                const isSigned = switch (@typeInfo(T)) {
                    .int => |a| a.signedness == .signed,
                    .float => true,
                    else => false,
                };
                if (!isSigned) @compileError("Vector Type must be signed for inversion.");
                return -v;
            }

            pub fn eql(a: VecT, b: VecT) bool {
                return @reduce(.And, a == b);
            }

            /// 2D only: determinant of the 2x2 matrix [a b], i.e. a.x*b.y - a.y*b.x ("2D cross product").
            /// |result| is the area of the parallelogram spanned by a and b; the sign is the
            /// orientation (> 0: b lies counter-clockwise of a, < 0: clockwise, 0: collinear).
            /// Shoelace: summing determinant(p[i], p[i+1]) over a closed polygon gives 2 * signed area.
            pub fn determinant(a: VecT, b: VecT) T {
                if (vec_len != 2) @compileError("determinant needs 2D vectors, use cross for 3D.");
                const ab = a * @shuffle(T, b, undefined, [2]i32{ 1, 0 }); // { a.x*b.y, a.y*b.x }
                return ab[0] - ab[1];
            }

            /// 3D only: cross product, a vector perpendicular to a and b (right-hand rule)
            /// with length |a| * |b| * sin(angle).
            pub fn cross(a: VecT, b: VecT) VecT {
                if (vec_len != 3) @compileError("cross needs 3D vectors, use determinant for 2D.");
                const yzx = [3]i32{ 1, 2, 0 };
                const zxy = [3]i32{ 2, 0, 1 };
                return @shuffle(T, a, undefined, yzx) * @shuffle(T, b, undefined, zxy) -
                    @shuffle(T, a, undefined, zxy) * @shuffle(T, b, undefined, yzx);
            }

            pub fn dot(a: VecT, b: VecT) v_info.child {
                return @reduce(.Add, a * b);
            }

            fn u64Cast(n: anytype) u64 {
                return switch (@typeInfo(@TypeOf(n))) {
                    .int, .comptime_int => @intCast(n),
                    .float, .comptime_float => @intFromFloat(n),
                    else => @compileError("Vector type must be of int or float!"),
                };
            }

            // Orthogonal only distance, see https://en.wikipedia.org/wiki/Taxicab_geometry
            pub fn manhattanDistance(a: VecT, b: VecT) u64 {
                return u64Cast(@reduce(.Add, @max(a, b) - @min(a, b)));
            }

            // Ortho- and diagonal distance, see https://en.wikipedia.org/wiki/Chebyshev_distance
            pub fn chebyshevDistance(a: VecT, b: VecT) u64 {
                return u64Cast(@reduce(.Max, @max(a, b) - @min(a, b)));
            }

            // Euclidean distance (pythagorean), see https://en.wikipedia.org/wiki/Euclidean_distance
            pub fn euclideanDistance(a: VecT, b: VecT) f64 {
                const d = @max(a, b) - @min(a, b);
                return @sqrt(@reduce(.Add, vecToFloat(d * d)));
            }

            fn vecToFloat(v: VecT) @Vector(v_info.len, f64) {
                var result: @Vector(v_info.len, f64) = undefined;
                inline for (0..v_info.len) |i| {
                    result[i] = switch (@typeInfo(v_info.child)) {
                        .int => @floatFromInt(v[i]),
                        .float => @floatCast(v[i]),
                        else => @compileError("T must be of int or float type for euclideanDistance!"),
                    };
                }
                return result;
            }
        },
        else => @compileError("T must be a vector type"),
    };
}

test "numerals and sums" {
    try std.testing.expectEqual(3, numeralLength(u64, 255, 10));
    try std.testing.expectEqual(8, numeralLength(u64, 255, 2));
    try std.testing.expectEqual(4, numeralLength10(u64, 1000));
    try std.testing.expectEqual(10, sumTo(u64, 5));
    try std.testing.expectEqual(9, sumRange(u64, 2, 5));
}

test "VectorExtension functions compile" {
    const Vec3 = @Vector(3, i64);
    const V3E = VectorExtension(Vec3);
    const v = try V3E.parseStringScalar("1,-2,3", ',');
    try std.testing.expectEqual(Vec3{ 1, -2, 3 }, v);
    try std.testing.expectEqual(Vec3{ 2, -4, 6 }, V3E.scale(v, 2));
    try std.testing.expectEqual(Vec3{ -1, 2, -3 }, V3E.inverse(v));
    try std.testing.expectEqual(true, V3E.eql(Vec3{ 1, 2, 3 }, Vec3{ 1, 2, 3 }));
    try std.testing.expectEqual(Vec3{ 0, 0, 1 }, V3E.cross(.{ 1, 0, 0 }, .{ 0, 1, 0 }));
    try std.testing.expectEqual(Vec3{ -3, 6, -3 }, V3E.cross(.{ 1, 2, 3 }, .{ 4, 5, 6 }));
    try std.testing.expectEqual(14, V3E.dot(v, v));
    try std.testing.expectEqual(6, V3E.manhattanDistance(V3E.zero, v));
    try std.testing.expectEqual(3, V3E.chebyshevDistance(V3E.zero, v));
    try std.testing.expectApproxEqAbs(@sqrt(14.0), V3E.euclideanDistance(V3E.zero, v), 1e-9);

    const V2E = VectorExtension(@Vector(2, i64));
    try std.testing.expectEqual(1, V2E.determinant(.{ 1, 0 }, .{ 0, 1 }));
    try std.testing.expectEqual(-2, V2E.determinant(.{ 3, 4 }, .{ 2, 2 }));
}
