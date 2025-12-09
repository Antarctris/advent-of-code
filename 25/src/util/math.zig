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

pub fn VectorExtension(T: type) type {
    return switch (@typeInfo(T)) {
        .vector => |v_info| struct {
            pub const Zero = T{0 ** v_info.len};

            pub fn parseStringScalar(str: []const u8, scalar: u8) !T {
                var str_iterator = std.mem.tokenizeScalar(u8, str, scalar);
                var v: T = undefined;
                var i: usize = 0;
                while (str_iterator.next()) |n_str| {
                    v[i] = switch (@typeInfo(v_info.child)) {
                        .int => try std.fmt.parseInt(v_info.child, n_str, 10),
                        .float => try std.fmt.parseFloat(v_info.child, n_str),
                        else => @compileError("Vector needs to hold int or float to support parsing!"),
                    };
                    i += 1;
                    if (i == v_info.len) break;
                }
                return v;
            }

            pub fn times(v: T, n: anytype) T {
                return .{v * @as(T, @splat(n))};
            }

            pub fn inverse(v: T) T {
                return v.times(-1);
            }

            pub fn dot(a: T, b: T) v_info.child {
                return @reduce(.Add, a * b);
            }

            fn u64Cast(n: v_info.child) u64 {
                return switch (@typeInfo(v_info.child)) {
                    .int => @intCast(n),
                    .float => @intFromFloat(n),
                    .pointer => @intFromPtr(n),
                    else => @compileError("Vector type must be of int, float or pointer!"),
                };
            }

            // Orthogonal only distance, see https://en.wikipedia.org/wiki/Taxicab_geometry
            pub fn manhattanDistance(a: T, b: T) u64 {
                return u64Cast(@reduce(.Add, @abs(b - a)));
            }

            // Ortho- and diagonal distance, see https://en.wikipedia.org/wiki/Chebyshev_distance
            pub fn chebyshevDistance(a: T, b: T) u64 {
                return u64Cast(@reduce(.Max, @abs(b - a)));
            }

            // Euclidean distance (pythagorean), see https://en.wikipedia.org/wiki/Euclidean_distanctarstoa
            pub fn euclideanDistance(a: T, b: T) f64 {
                const d = b - a;
                const sum: f64 = @reduce(.Add, vecToFloat(d * d));
                return switch (v_info.len) {
                    1 => sum,
                    2 => @sqrt(sum),
                    3 => std.math.cbrt(sum),
                    // Zig doesn't provide a nth root implementation at the moment
                    // returning the sum at least gives comparable values (eq, lt, gt, ...)
                    else => sum,
                };
            }

            fn vecToFloat(v: T) @Vector(v_info.len, f64) {
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
