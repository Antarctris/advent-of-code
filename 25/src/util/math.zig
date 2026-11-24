const std = @import("std");

pub fn numeralLength(comptime T: type, n: T, base: T) T {
    const logN: T = @intFromFloat(std.math.log(f64, @floatFromInt(base), @floatFromInt(n)));
    return logN + 1;
}

pub fn numeralLength10(comptime T: type, n: T) T {
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
                var v: VecT = undefined;
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

            pub fn dot(a: VecT, b: VecT) v_info.child {
                return @reduce(.Add, a * b);
            }

            fn u64Cast(n: anytype) u64 {
                return switch (@typeInfo(@TypeOf(n))) {
                    .int, .comptime_int => @intCast(n),
                    .float, .comptime_float => @intFromFloat(n),
                    .pointer => @intFromPtr(n),
                    else => @compileError("Vector type must be of int, float or pointer!"),
                };
            }

            // Orthogonal only distance, see https://en.wikipedia.org/wiki/Taxicab_geometry
            pub fn manhattanDistance(a: VecT, b: VecT) u64 {
                return u64Cast(@reduce(.Add, @abs(b - a)));
            }

            // Ortho- and diagonal distance, see https://en.wikipedia.org/wiki/Chebyshev_distance
            pub fn chebyshevDistance(a: VecT, b: VecT) u64 {
                return u64Cast(@reduce(.Max, @abs(b - a)));
            }

            // Euclidean distance (pythagorean), see https://en.wikipedia.org/wiki/Euclidean_distance
            pub fn euclideanDistance(a: VecT, b: VecT) f64 {
                const d = b - a;
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
