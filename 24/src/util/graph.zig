const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const PriorityQueue = std.PriorityQueue;

pub const ResultType = enum {
    cost,
    route,
    routes,
};

pub fn Graph(
    comptime T: type,
    comptime Context: type,
    comptime adjacency_buf_size: usize,
    comptime adjacencyFn: fn (context: Context, buf: []struct { T, u64 }, a: T) []struct { T, u64 },
    comptime isEndFn: fn (context: Context, a: T) bool,
) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        context: Context,

        pub fn init(allocator: Allocator, context: Context) Self {
            return Self{
                .allocator = allocator,
                .context = context,
            };
        }

        pub fn deinit(self: *Self) void {
            _ = self;
        }

        pub const Result = union(ResultType) {
            cost: u64,
            route: ArrayList(T),
            routes: ArrayList(ArrayList(T)),
        };

        const Node = struct {
            t: T,
            cost: u64,
        };

        const Visit = struct {
            cost: u64 = std.math.maxInt(u64),
            prev: [adjacency_buf_size]T = undefined,
            len: usize = 0,
        };

        fn nodePriority(context: void, a: Node, b: Node) std.math.Order {
            _ = context;
            return std.math.order(a.cost, b.cost);
        }

        pub fn dijkstra(self: Self, allocator: Allocator, comptime resultType: ResultType, starts: []const T) !Result {
            var visited = AutoHashMap(T, Visit).init(self.allocator);
            defer visited.deinit();
            var queue = PriorityQueue(Node, void, nodePriority).init(self.allocator, {});
            defer queue.deinit();

            for (starts) |start| {
                try queue.add(Node{ .t = start, .cost = 0 });
                try visited.put(start, Visit{ .cost = 0 });
            }

            var end = std.AutoArrayHashMap(Node, void).init(allocator);
            defer end.deinit();

            var adjacency_buf: [adjacency_buf_size]struct { T, u64 } = undefined;
            while (queue.removeOrNull()) |node| {
                if (end.count() > 0 and end.keys()[0].cost < node.cost) break;
                if (isEndFn(self.context, node.t)) {
                    try end.put(node, {});
                    switch (resultType) {
                        inline .cost, .route => break,
                        inline .routes => continue,
                    }
                }

                const current_record = visited.get(node.t) orelse Visit{};
                if (node.cost > current_record.cost) continue;

                for (adjacencyFn(self.context, &adjacency_buf, node.t)) |neighbor| {
                    const next = Node{ .t = neighbor.@"0", .cost = node.cost + neighbor.@"1" };

                    var neighbor_record = visited.get(next.t) orelse Visit{};
                    if (next.cost < neighbor_record.cost) {
                        var visit = Visit{ .cost = next.cost };
                        visit.prev[visit.len] = node.t;
                        visit.len += 1;
                        try visited.put(next.t, visit);
                        try queue.add(next);
                    }
                    if (next.cost == neighbor_record.cost) {
                        neighbor_record.prev[neighbor_record.len] = node.t;
                        neighbor_record.len += 1;
                        visited.putAssumeCapacity(next.t, neighbor_record);
                    }
                }
            }

            return switch (resultType) {
                inline .cost => Result{ .cost = if (end.keys().len > 0) end.keys()[0].cost else std.math.maxInt(u64) },
                inline .route => route: {
                    var route = ArrayList(T).init(allocator);
                    if (end.keys().len > 0) {
                        const node = end.keys()[0];
                        try route.append(node.t);
                        var visit = visited.get(node.t).?;
                        while (visit.len > 0) {
                            try route.append(visit.prev[0]);
                            visit = visited.get(visit.prev[0]).?;
                        }
                    }
                    break :route Result{ .route = route };
                },
                inline .routes => routes: {
                    std.debug.print("End nodes: {d}", .{end.keys().len});
                    var routes = ArrayList(ArrayList(T)).init(allocator);
                    for (end.keys()) |node| {
                        const route_index = routes.items.len;
                        try routes.insert(route_index, ArrayList(T).init(allocator));
                        try buildRoutesRecursive(allocator, visited, &routes, route_index, node.t);
                    }
                    break :routes Result{ .routes = routes };
                },
            };
        }

        fn buildRoutesRecursive(
            allocator: Allocator,
            visited: AutoHashMap(T, Visit),
            routes: *ArrayList(ArrayList(T)),
            route_index: usize,
            t: T,
        ) !void {
            try routes.items[route_index].append(t);
            const visit = visited.get(t).?;
            if (visit.len == 0) return;
            try buildRoutesRecursive(allocator, visited, routes, route_index, visit.prev[0]);
            if (visit.len > 1) {
                for (1..visit.len) |i| {
                    var new_route = ArrayList(T).init(allocator);
                    try new_route.insertSlice(0, routes.items[route_index].items);
                    const new_route_index: usize = routes.items.len;
                    std.debug.print("Recursion {d} => {d}\n", .{ route_index, new_route_index });
                    try routes.insert(new_route_index, new_route);
                    try buildRoutesRecursive(allocator, visited, routes, new_route_index, visit.prev[i]);
                }
            }
        }
    };
}
