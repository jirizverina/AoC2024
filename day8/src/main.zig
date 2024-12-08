const std = @import("std");
const expectEqual = std.testing.expectEqual;
const math = std.math;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const map = try getMapFromInput(allocator);

    const result = try getNumberOfAntinodes(map, allocator);
    std.debug.print("Result for part 1 is {}\n", .{result});
}

fn getMapFromInput(allocator: std.mem.Allocator) ![][]u8 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = std.ArrayList([]u8).init(allocator);
    defer lines.deinit();

    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 500)) |line| {
        try lines.append(line);
    }

    return try lines.toOwnedSlice();
}

const Point = struct { x: usize, y: usize };

fn getNumberOfAntinodes(map: []const []const u8, allocator: std.mem.Allocator) !u32 {
    var freqs_locations = std.AutoHashMap(u8, []const Point).init(allocator);
    defer freqs_locations.deinit();

    try getFrequenciesAndLocations(map, allocator, &freqs_locations);

    var locations = std.AutoHashMap(Point, void).init(allocator);
    defer locations.deinit();

    var freqs_locations_it = freqs_locations.iterator();

    while (freqs_locations_it.next()) |freq_locations| {
        const tower_locations: []const Point = freq_locations.value_ptr.*;

        for (tower_locations) |tower1| {
            for (tower_locations) |tower2| {
                if (std.meta.eql(tower1, tower2)) {
                    continue;
                }

                const vector_x: i64 = @as(i64, @intCast(tower1.x)) - @as(i64, @intCast(tower2.x));
                const vector_y: i64 = @as(i64, @intCast(tower1.y)) - @as(i64, @intCast(tower2.y));

                const point1_x: i64 = @as(i64, @intCast(tower1.x)) +% vector_x;
                const point1_y: i64 = @as(i64, @intCast(tower1.y)) +% vector_y;

                if (!(point1_y >= map.len or point1_y < 0 or point1_x < 0 or point1_x >= map[@intCast(point1_y)].len)) {
                    _ = try locations.getOrPut(.{ .x = @intCast(point1_x), .y = @intCast(point1_y) });
                }

                const point2_x: i64 = @as(i64, @intCast(tower2.x)) -% vector_x;
                const point2_y: i64 = @as(i64, @intCast(tower2.y)) -% vector_y;

                if (!(point2_y >= map.len or point2_y < 0 or point2_x < 0 or point2_x >= map[@intCast(point2_y)].len)) {
                    _ = try locations.getOrPut(.{ .x = @intCast(point2_x), .y = @intCast(point2_y) });
                }
            }
        }
    }

    return locations.count();
}

fn getFrequenciesAndLocations(map: []const []const u8, allocator: std.mem.Allocator, result: *std.AutoHashMap(u8, []const Point)) !void {
    var hash_map = std.AutoHashMap(u8, std.ArrayList(Point)).init(allocator);
    defer hash_map.deinit();

    for (map, 0..map.len) |row, y| {
        for (row, 0..row.len) |c, x| {
            if (c == '.') {
                continue;
            }

            if (hash_map.contains(c)) {
                const points_ptr_ptr = hash_map.getPtr(c).?;
                var points = points_ptr_ptr.*;
                try points.append(.{ .x = x, .y = y });
                points_ptr_ptr.* = points;
                continue;
            }

            var points = std.ArrayList(Point).init(allocator);
            try points.append(.{ .x = x, .y = y });
            try hash_map.put(c, points);
        }
    }

    var hash_map_it = hash_map.iterator();

    while (hash_map_it.next()) |entry| {
        const points_list_ptr = entry.value_ptr;
        const points = try points_list_ptr.*.toOwnedSlice();
        try result.*.putNoClobber(entry.key_ptr.*, points);
    }
}

test "part1" {
    const allocator = std.heap.page_allocator;
    const input = getTestInput();
    const result = getNumberOfAntinodes(input, allocator);

    try expectEqual(14, result);
}

inline fn getTestInput() []const []const u8 {
    const map = [_][]const u8{ "............", "........0...", ".....0......", ".......0....", "....0.......", "......A.....", "............", "............", "........A...", ".........A..", "............", "............" };

    return &map;
}
