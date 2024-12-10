const std = @import("std");
const testing = std.testing;

//hiking trail = path with uphill slope from 0 to 9
//trailhead = start of hiking trail
//trailhead score = number of 9s reachable from trailhead

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const map = try getMapFromInput(allocator);

    const part1 = try solve(allocator, map);
    std.debug.print("Result for part 1 is {}\n", .{part1});
}

fn solve(allocator: std.mem.Allocator, map: []const []const u8) !ScoreAndRanking {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const aa = arena.allocator();

    const trail_heads = try getTrailHeads(aa, map);
    try scoreTrailHeads(aa, map, trail_heads);
    const result = aggregateScoresAndRankings(trail_heads);

    return result;
}

fn getMapFromInput(allocator: std.mem.Allocator) ![][]u8 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var list = std.ArrayList([]u8).init(allocator);
    defer list.deinit();

    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 200)) |line| {
        var row = try allocator.alloc(u8, line.len);
        for (line, 0..line.len) |c, i| {
            row[i] = try std.fmt.charToDigit(c, 10);
        }
        try list.append(row);
    }

    return try list.toOwnedSlice();
}

const ScoreAndRanking = struct { score: u32, ranking: u32 };
const Vector = struct { x: i32, y: i32 };
const Point = struct { x: usize, y: usize };
const TrailHeads = struct { pos: Point, score: u32 = 0, ranking: u32 = 0 };

const PointManipulationError = error{OutsideOfMap};

fn getTrailHeads(allocator: std.mem.Allocator, map: []const []const u8) ![]TrailHeads {
    var list = std.ArrayList(TrailHeads).init(allocator);
    defer list.deinit();

    for (map, 0..map.len) |row, y| {
        for (row, 0..row.len) |d, x| {
            if (d != 0) {
                continue;
            }

            try list.append(.{ .pos = .{ .x = x, .y = y } });
        }
    }

    return list.toOwnedSlice();
}

fn scoreTrailHeads(allocator: std.mem.Allocator, map: []const []const u8, trail_heads: []TrailHeads) !void {
    for (0..trail_heads.len) |i| {
        const th = &trail_heads[i];
        try scoreTrailHead(allocator, map, th);
    }
}

fn scoreTrailHead(allocator: std.mem.Allocator, map: []const []const u8, trail_head: *TrailHeads) !void {
    var hash_map = std.AutoHashMap(Point, void).init(allocator);
    defer hash_map.deinit();

    const ranking = try findTrails(map, trail_head.pos, 1, 9, &hash_map);
    trail_head.ranking = ranking;
    trail_head.score = hash_map.count();
}

fn findTrails(map: []const []const u8, pos: Point, search_value: u8, max_value: u8, hash_map: *std.AutoHashMap(Point, void)) !u32 {
    var sum: u32 = 0;

    for (vectors) |vector| {
        const new_pos = applyVectorToPoint(map, vector, pos) catch |err| switch (err) {
            PointManipulationError.OutsideOfMap => continue,
            else => |e| return e,
        };

        if (map[new_pos.y][new_pos.x] != search_value) {
            continue;
        }

        if (search_value == max_value) {
            sum += 1;
            _ = try hash_map.getOrPut(new_pos);
            continue;
        }

        sum += try findTrails(map, new_pos, search_value + 1, max_value, hash_map);
    }

    return sum;
}

const vectors = [_]Vector{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 } };

fn applyVectorToPoint(map: []const []const u8, vector: Vector, point: Point) PointManipulationError!Point {
    const x: i64 = @as(i64, @intCast(point.x)) + vector.x;
    const y: i64 = @as(i64, @intCast(point.y)) + vector.y;

    if (y < 0 or x < 0 or y >= map.len or x >= map[@intCast(y)].len) {
        return PointManipulationError.OutsideOfMap;
    }

    return Point{ .x = @intCast(x), .y = @intCast(y) };
}

fn aggregateScoresAndRankings(trail_heads: []TrailHeads) ScoreAndRanking {
    var score: u32 = 0;
    var ranking: u32 = 0;

    for (trail_heads) |trail_head| {
        score += trail_head.score;
        ranking += trail_head.ranking;
    }

    return .{ .score = score, .ranking = ranking };
}

test "solve" {
    const input = getTestInput();
    const result = try solve(testing.allocator, input);

    try testing.expectEqual(36, result.score);
    try testing.expectEqual(81, result.ranking);
}

inline fn getTestInput() []const []const u8 {
    var arr = [_][]const u8{
        &[_]u8{ 8, 9, 0, 1, 0, 1, 2, 3 },
        &[_]u8{ 7, 8, 1, 2, 1, 8, 7, 4 },
        &[_]u8{ 8, 7, 4, 3, 0, 9, 6, 5 },
        &[_]u8{ 9, 6, 5, 4, 9, 8, 7, 4 },
        &[_]u8{ 4, 5, 6, 7, 8, 9, 0, 3 },
        &[_]u8{ 3, 2, 0, 1, 9, 0, 1, 2 },
        &[_]u8{ 0, 1, 3, 2, 9, 8, 0, 1 },
        &[_]u8{ 1, 0, 4, 5, 6, 7, 3, 2 },
    };

    return &arr;
}
