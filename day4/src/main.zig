const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const parsed_input = try parseInput(allocator);

    const result = findXmas(parsed_input);
    const result2 = findXmas2(parsed_input);

    std.debug.print("Result for part 1 is {}\n", .{result});
    std.debug.print("Result for part 2 is {}\n", .{result2});
}

fn parseInput(allocator: std.mem.Allocator) ![][]u8 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var array_list = std.ArrayList([]u8).init(allocator);
    defer array_list.deinit();

    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 20_000)) |line| {
        try array_list.append(line);
    }

    return try array_list.toOwnedSlice();
}

fn findXmas2(map: []const []const u8) i32 {
    var sum: i32 = 0;

    for (1..map.len - 1) |y| {
        const row = map[y];

        for (1..row.len - 1) |x| {
            const c = row[x];

            if (c != 'A') {
                continue;
            }

            const point = Point{ .x = x, .y = y };

            if (isCenterMasCross(point, map)) {
                sum += 1;
            }
        }
    }

    return sum;
}

//I want to sleep
fn isCenterMasCross(point: Point, map: []const []const u8) bool {
    const p1 = applyVectorOnPoint(point, .{ .x = 1, .y = 1 });
    const p2 = applyVectorOnPoint(point, .{ .x = -1, .y = -1 });
    const p3 = applyVectorOnPoint(point, .{ .x = -1, .y = 1 });
    const p4 = applyVectorOnPoint(point, .{ .x = 1, .y = -1 });

    if (map[p1.y][p1.x] == 'M' and map[p2.y][p2.x] == 'S' or map[p1.y][p1.x] == 'S' and map[p2.y][p2.x] == 'M') {
        if (map[p3.y][p3.x] == 'M' and map[p4.y][p4.x] == 'S' or map[p3.y][p3.x] == 'S' and map[p4.y][p4.x] == 'M') {
            return true;
        }
        return false;
    }

    return false;
}

fn applyVectorOnPoint(point: Point, vector: Vector) Point {
    var p = point;

    p.x = @intCast(@as(i32, @intCast(p.x)) - vector.x);
    p.y = @intCast(@as(i32, @intCast(p.y)) - vector.y);

    return p;
}

fn findXmas(map: []const []const u8) i32 {
    var sum: i32 = 0;

    for (map, 0..map.len) |row, y| {
        for (row, 0..row.len) |c, x| {
            if (c != 'X') {
                continue;
            }

            const point = Point{ .x = x, .y = y };

            sum += findChars("MAS", point, map);
        }
    }
    return sum;
}

fn findChars(chars: []const u8, point: Point, map: []const []const u8) i32 {
    var sum: i32 = 0;

    if (chars.len == 0) {
        return sum;
    }

    const char = chars[0];

    for (0..3) |y| {
        const i_y = (@as(i32, @intCast(point.y))) + (@as(i32, @intCast(y)) - 1);

        if (i_y < 0 or i_y >= map.len) {
            continue;
        }

        const p_y: usize = @intCast(i_y);

        for (0..3) |x| {
            const i_x = (@as(i32, @intCast(point.x))) +% (@as(i32, @intCast(x)) - 1);

            if (i_x < 0 or i_x >= map[p_y].len) {
                continue;
            }

            const p_x: usize = @intCast(i_x);

            if (map[p_y][p_x] != char) {
                continue;
            }

            if (chars.len <= 1) {
                return sum + 1;
            }

            const v_y: i32 = @as(i32, @intCast(y)) - 1;
            const v_x: i32 = @as(i32, @intCast(x)) - 1;

            if (findCharsVec(chars[1..], .{ .x = p_x, .y = p_y }, map, .{ .x = v_x, .y = v_y })) {
                sum += 1;
            }
        }
    }

    return sum;
}

fn findCharsVec(chars: []const u8, point: Point, map: []const []const u8, v: Vector) bool {
    if (chars.len == 0) {
        return true;
    }

    const char = chars[0];

    const i_y: i32 = @as(i32, @intCast(point.y)) + v.y;
    if (i_y < 0 or i_y >= map.len) {
        return false;
    }

    const p_y: usize = @intCast(i_y);
    const i_x: i32 = @as(i32, @intCast(point.x)) + v.x;

    if (i_x < 0 or i_x >= map[p_y].len) {
        return false;
    }

    const p_x: usize = @intCast(i_x);

    if (map[p_y][p_x] != char) {
        return false;
    }

    if (chars.len <= 1) {
        return true;
    }

    return findCharsVec(chars[1..], .{ .x = p_x, .y = p_y }, map, v);
}

const Point = struct { x: usize, y: usize };
const Vector = struct { x: i32, y: i32 };

fn printMap(map: []const []const u8) void {
    std.debug.print("Map:\n", .{});
    for (map) |row| {
        std.debug.print("{s}\n", .{row});
    }

    std.debug.print("\n", .{});
}

test "part1" {
    const input = [10][]const u8{
        "MMMSXXMASM",
        "MSAMXMSMSA",
        "AMXSXMAAMM",
        "MSAMASMSMX",
        "XMASAMXAMM",
        "XXAMMXXAMA",
        "SMSMSASXSS",
        "SAXAMASAAA",
        "MAMMMXMMMM",
        "MXMXAXMASX",
    };

    var known_at_runtime_zero: usize = 0;
    _ = &known_at_runtime_zero;

    const result = findXmas(input[known_at_runtime_zero..input.len]);
    try expectEqual(18, result);
}

test "part2" {
    const input = [10][]const u8{
        ".M.S......",
        "..A..MSMS.",
        ".M.S.MAA..",
        "..A.ASMSM.",
        ".M.S.M....",
        "..........",
        "S.S.S.S.S.",
        ".A.A.A.A..",
        "M.M.M.M.M.",
        "..........",
    };

    var known_at_runtime_zero: usize = 0;
    _ = &known_at_runtime_zero;

    const result = findXmas2(input[known_at_runtime_zero..input.len]);
    try expectEqual(9, result);
}
