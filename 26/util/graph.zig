const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMapUnmanaged;
const PriorityQueue = std.PriorityQueue;

pub const ResultType = enum {
    cost,
    route,
    routes,
    all_routes,
};

/// `heuristicFn` is optional: with `null`, `a_star` orders by cost only (= `dijkstra`).
pub fn Graph(
    comptime T: type,
    comptime Context: type,
    comptime adjacencyFn: fn (context: Context, adjacency_buf: []struct { T, u64 }, a: T) []struct { T, u64 },
    comptime heuristicFn: ?fn (context: Context, a: T) u64,
    comptime isEndFn: fn (context: Context, a: T) bool,
) type {
    return struct {
        const Self = @This();
        const Edge = struct { T, u64 };

        /// Used for internal bookkeeping during a search.
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

        /// Routes are stored end → start. Free with `Result.deinit` using the allocator passed to the search.
        /// - `cost`: cost of the cheapest route
        /// - `route`: one cheapest route
        /// - `routes`: all cheapest routes
        /// - `all_routes`: every loop-free route, regardless of cost (exhaustive DFS, exponential!)
        pub const Result = union(ResultType) {
            cost: u64,
            route: ArrayList(T),
            routes: ArrayList(ArrayList(T)),
            all_routes: ArrayList(ArrayList(T)),

            pub fn deinit(self: *Result, allocator: Allocator) void {
                switch (self.*) {
                    .cost => {},
                    .route => |*route| route.deinit(allocator),
                    .routes, .all_routes => |*routes| {
                        for (routes.items) |*route| route.deinit(allocator);
                        routes.deinit(allocator);
                    },
                }
            }
        };

        const Node = struct {
            t: T,
            cost: u64,
        };

        const Visit = struct {
            cost: u64 = std.math.maxInt(u64),
            prev: ?[]T = null,
            len: usize = 0,

            fn appendPrev(self: *Visit, allocator: Allocator, a: T) !void {
                if (self.prev == null) {
                    self.prev = try allocator.alloc(T, 5);
                } else if (self.len >= self.prev.?.len) {
                    self.prev = try allocator.realloc(self.prev.?, self.prev.?.len + 5);
                }
                self.prev.?[self.len] = a;
                self.len += 1;
            }

            fn containsPrev(self: Visit, a: T) bool {
                const prev = self.prev orelse return false;
                const a_hash = shallowHash(a);
                for (prev[0..self.len]) |p| {
                    if (a_hash == shallowHash(p)) return true;
                }
                return false;
            }
        };

        const Visited = AutoHashMap(T, Visit);

        fn shallowHash(value: T) u64 {
            var hasher = std.hash.Wyhash.init(0); // fast, good default
            std.hash.autoHash(&hasher, value);
            return hasher.final();
        }

        fn Queue(comptime use_heuristic: bool) type {
            return PriorityQueue(Node, Context, struct {
                fn order(context: Context, a: Node, b: Node) std.math.Order {
                    if (!use_heuristic) return std.math.order(a.cost, b.cost);
                    const h = heuristicFn.?;
                    return std.math.order(a.cost + h(context, a.t), b.cost + h(context, b.t));
                }
            }.order);
        }

        /// A-Star algorithm
        /// Without a `heuristicFn` falls back to Dijkstra's algorithm.
        pub fn a_star(
            self: Self,
            allocator: Allocator,
            comptime resultType: ResultType,
            starts: []const T,
            adjacency_buf_size: usize,
        ) !Result {
            return self.search(heuristicFn != null, allocator, resultType, starts, adjacency_buf_size);
        }

        /// Classic Dijkstra algorithm (without heuristic)
        pub fn dijkstra(
            self: Self,
            allocator: Allocator,
            comptime resultType: ResultType,
            starts: []const T,
            adjacency_buf_size: usize,
        ) !Result {
            return self.search(false, allocator, resultType, starts, adjacency_buf_size);
        }

        fn search(
            self: Self,
            comptime use_heuristic: bool,
            allocator: Allocator,
            comptime resultType: ResultType,
            starts: []const T,
            adjacency_buf_size: usize,
        ) !Result {
            if (resultType == .all_routes) return self.allRoutes(allocator, starts, adjacency_buf_size);
            const gpa = self.allocator;

            var visited: Visited = .empty;
            defer {
                var visited_it = visited.valueIterator();
                while (visited_it.next()) |visit| {
                    if (visit.prev) |prev| gpa.free(prev);
                }
                visited.deinit(gpa);
            }

            var queue: Queue(use_heuristic) = .initContext(self.context);
            defer queue.deinit(gpa);

            for (starts) |start| {
                try queue.push(gpa, Node{ .t = start, .cost = 0 });
                try visited.put(gpa, start, Visit{ .cost = 0 });
            }

            var end: std.array_hash_map.Auto(Node, void) = .empty;
            defer end.deinit(gpa);

            const adjacency_buf = try gpa.alloc(struct { T, u64 }, adjacency_buf_size);
            defer gpa.free(adjacency_buf);

            while (queue.pop()) |node| {
                if (end.count() > 0 and end.keys()[0].cost < node.cost) break;
                if (isEndFn(self.context, node.t)) {
                    try end.put(gpa, node, {});
                    switch (resultType) {
                        .cost, .route => break,
                        .routes => continue,
                        .all_routes => unreachable,
                    }
                }

                const current_record = visited.get(node.t) orelse Visit{};
                if (node.cost > current_record.cost) continue;

                for (adjacencyFn(self.context, adjacency_buf, node.t)) |neighbor| {
                    const next = Node{ .t = neighbor.@"0", .cost = node.cost + neighbor.@"1" };

                    const gop = try visited.getOrPut(gpa, next.t);
                    if (!gop.found_existing) gop.value_ptr.* = .{};
                    const neighbor_record = gop.value_ptr;

                    if (next.cost < neighbor_record.cost) {
                        neighbor_record.cost = next.cost;
                        neighbor_record.len = 0;
                        try neighbor_record.appendPrev(gpa, node.t);
                        try queue.push(gpa, next);
                    } else if (next.cost == neighbor_record.cost and !neighbor_record.containsPrev(node.t)) {
                        try neighbor_record.appendPrev(gpa, node.t);
                    }
                }
            }

            switch (resultType) {
                .cost => return .{ .cost = if (end.count() > 0) end.keys()[0].cost else std.math.maxInt(u64) },
                .route => {
                    var route: ArrayList(T) = .empty;
                    errdefer route.deinit(allocator);
                    if (end.count() > 0) {
                        var t = end.keys()[0].t;
                        try route.append(allocator, t);
                        var visit = visited.get(t).?;
                        while (visit.len > 0) {
                            t = visit.prev.?[0];
                            try route.append(allocator, t);
                            visit = visited.get(t).?;
                        }
                    }
                    return .{ .route = route };
                },
                .routes => {
                    var routes: ArrayList(ArrayList(T)) = .empty;
                    errdefer freeRoutes(allocator, &routes);
                    for (end.keys()) |node| {
                        try routes.append(allocator, .empty);
                        try buildRoutesRecursive(allocator, visited, &routes, routes.items.len - 1, node.t);
                    }
                    return .{ .routes = routes };
                },
                .all_routes => unreachable,
            }
        }

        fn freeRoutes(allocator: Allocator, routes: *ArrayList(ArrayList(T))) void {
            for (routes.items) |*route| route.deinit(allocator);
            routes.deinit(allocator);
        }

        /// Exhaustive depth-first search for every loop-free route from any start to an end node.
        /// A route stops at the first end node it reaches.
        fn allRoutes(self: Self, allocator: Allocator, starts: []const T, adjacency_buf_size: usize) !Result {
            const gpa = self.allocator;
            var dfs: Dfs = .{
                .graph = self,
                .gpa = gpa,
                .allocator = allocator,
                .adjacency_buf = try gpa.alloc(Edge, adjacency_buf_size),
            };
            defer gpa.free(dfs.adjacency_buf);
            defer dfs.path.deinit(gpa);
            defer dfs.on_path.deinit(gpa);
            errdefer freeRoutes(allocator, &dfs.routes);

            for (starts) |start| try dfs.visit(start);
            return .{ .all_routes = dfs.routes };
        }

        const Dfs = struct {
            graph: Self,
            gpa: Allocator,
            allocator: Allocator,
            adjacency_buf: []Edge,
            path: ArrayList(T) = .empty,
            on_path: AutoHashMap(T, void) = .empty,
            routes: ArrayList(ArrayList(T)) = .empty,

            fn visit(dfs: *Dfs, t: T) !void {
                try dfs.path.append(dfs.gpa, t);
                defer _ = dfs.path.pop();
                try dfs.on_path.put(dfs.gpa, t, {});
                defer _ = dfs.on_path.remove(t);

                if (isEndFn(dfs.graph.context, t)) {
                    var route = try dfs.path.clone(dfs.allocator);
                    errdefer route.deinit(dfs.allocator);
                    std.mem.reverse(T, route.items); // end → start, like the other results
                    try dfs.routes.append(dfs.allocator, route);
                    return;
                }

                // Deeper calls reuse adjacency_buf, so keep a copy of this level's neighbors.
                const neighbors = try dfs.gpa.dupe(Edge, adjacencyFn(dfs.graph.context, dfs.adjacency_buf, t));
                defer dfs.gpa.free(neighbors);
                for (neighbors) |neighbor| {
                    if (!dfs.on_path.contains(neighbor.@"0")) try dfs.visit(neighbor.@"0");
                }
            }
        };

        fn buildRoutesRecursive(
            allocator: Allocator,
            visited: Visited,
            routes: *ArrayList(ArrayList(T)),
            route_index: usize,
            t: T,
        ) !void {
            try routes.items[route_index].append(allocator, t);
            const visit = visited.get(t).?;
            if (visit.len == 0) return;
            for (1..visit.len) |i| {
                var new_route = try routes.items[route_index].clone(allocator);
                errdefer new_route.deinit(allocator);
                try routes.append(allocator, new_route);
                try buildRoutesRecursive(allocator, visited, routes, routes.items.len - 1, visit.prev.?[i]);
            }
            try buildRoutesRecursive(allocator, visited, routes, route_index, visit.prev.?[0]);
        }
    };
}

test Graph {
    // Open 3x3 grid, nodes are indices 0..8, start top-left (0), end bottom-right (8).
    const Grid3 = struct {
        fn adjacent(_: void, buf: []struct { u8, u64 }, a: u8) []struct { u8, u64 } {
            var n: usize = 0;
            const x = a % 3;
            const y = a / 3;
            if (x > 0) buf[n] = .{ a - 1, 1 };
            n += @intFromBool(x > 0);
            if (x < 2) buf[n] = .{ a + 1, 1 };
            n += @intFromBool(x < 2);
            if (y > 0) buf[n] = .{ a - 3, 1 };
            n += @intFromBool(y > 0);
            if (y < 2) buf[n] = .{ a + 3, 1 };
            n += @intFromBool(y < 2);
            return buf[0..n];
        }
        fn heuristic(_: void, a: u8) u64 {
            return (2 - a % 3) + (2 - a / 3);
        }
        fn isEnd(_: void, a: u8) bool {
            return a == 8;
        }
    };
    const G = Graph(u8, void, Grid3.adjacent, Grid3.heuristic, Grid3.isEnd);
    const gpa = std.testing.allocator;
    const graph: G = .init(gpa, {});

    inline for (.{ G.a_star, G.dijkstra }) |searchFn| {
        var cost = try searchFn(graph, gpa, .cost, &.{0}, 4);
        defer cost.deinit(gpa);
        try std.testing.expectEqual(4, cost.cost);

        var route = try searchFn(graph, gpa, .route, &.{0}, 4);
        defer route.deinit(gpa);
        try std.testing.expectEqual(5, route.route.items.len);
        try std.testing.expectEqual(8, route.route.items[0]);
        try std.testing.expectEqual(0, route.route.items[4]);

        // Number of shortest monotone paths through a 3x3 grid: C(4, 2) = 6.
        var routes = try searchFn(graph, gpa, .routes, &.{0}, 4);
        defer routes.deinit(gpa);
        try std.testing.expectEqual(6, routes.routes.items.len);
        for (routes.routes.items) |r| try std.testing.expectEqual(5, r.items.len);

        // Self-avoiding corner-to-corner paths in a 3x3 grid (OEIS A007764): 12.
        var all = try searchFn(graph, gpa, .all_routes, &.{0}, 4);
        defer all.deinit(gpa);
        try std.testing.expectEqual(12, all.all_routes.items.len);
        for (all.all_routes.items) |r| {
            try std.testing.expectEqual(8, r.items[0]);
            try std.testing.expectEqual(0, r.items[r.items.len - 1]);
        }
    }

    // Without heuristic, a_star orders by cost only, same as dijkstra.
    const D = Graph(u8, void, Grid3.adjacent, null, Grid3.isEnd);
    const dgraph: D = .init(gpa, {});
    inline for (.{ D.a_star, D.dijkstra }) |searchFn| {
        var cost = try searchFn(dgraph, gpa, .cost, &.{0}, 4);
        defer cost.deinit(gpa);
        try std.testing.expectEqual(4, cost.cost);

        var routes = try searchFn(dgraph, gpa, .routes, &.{0}, 4);
        defer routes.deinit(gpa);
        try std.testing.expectEqual(6, routes.routes.items.len);
    }
}
