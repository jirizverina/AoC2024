const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const parsed_input = try parseInput(allocator);

    const result = findXmas(parsed_input);

    std.debug.print("Result is {}\n", .{result});
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

fn findXmas(map: []const []const u8) i32 {
    //printMap(map);

    var sum: i32 = 0;

    for (map, 0..map.len) |row, y| {
        //std.debug.print("{s}\n", .{row});
        for (row, 0..row.len) |c, x| {
            if (c != 'X') {
                continue;
            }

            //std.debug.print("Found 'X' at x: {} y: {}\n", .{ x, y });

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
            //std.debug.print("Outside of scope - point y: {}; vector y {}\n", .{ point.y, y });
            continue;
        }

        const p_y: usize = @intCast(i_y);

        for (0..3) |x| {
            const i_x = (@as(i32, @intCast(point.x))) +% (@as(i32, @intCast(x)) - 1);

            if (i_x < 0 or i_x >= map[p_y].len) {
                //std.debug.print("Outside of scope - point x: {} y: {}; vector x: {} y {}\n", .{ point.x, point.y, x, y });
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

    //std.debug.print("Searching {c} current point is x: {} y: {}\n", .{ char, point.x, point.y });
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
    //std.debug.print("Searching {c} new point is x: {} y: {} and vector is x: {} y: {}\n", .{ char, p_x, p_y, v.x, v.y });

    if (map[p_y][p_x] != char) {
        return false;
    }
    //std.debug.print("Found {c} at x: {} y: {}\n", .{ char, p_x, p_y });

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

    const input2 = [10][]const u8{
        "....XXMAS.",
        ".SAMXMS...",
        "...S..A...",
        "..A.A.MS.X",
        "XMASAMX.MM",
        "X.....XA.A",
        "S.S.S.S.SS",
        ".A.A.A.A.A",
        "..M.M.M.MM",
        ".X.X.XMASX",
    };

    var known_at_runtime_zero: usize = 0;
    _ = &known_at_runtime_zero;

    const result2 = findXmas(input2[known_at_runtime_zero..input2.len]);
    try expectEqual(18, result2);

    const result = findXmas(input[known_at_runtime_zero..input.len]);
    try expectEqual(18, result);
}
