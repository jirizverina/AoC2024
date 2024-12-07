const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const parsed_input = try createMapFromInput(allocator);
    const result = try getGuardsPosCount(parsed_input.map, parsed_input.starting_pos, allocator);
    const result2 = try getNumOfPossibleObstructions(parsed_input.map, parsed_input.starting_pos, allocator);

    std.debug.print("Result for part 1 is {}\n", .{result});
    std.debug.print("Result for part 2 is {}\n", .{result2});
}

const Point = struct { x: usize, y: usize };
const ParsedInput = struct { map: []const []const u8, starting_pos: Point };
const PositionAndDirection = struct { pos: Point, direction: Direction };

fn createMapFromInput(allocator: std.mem.Allocator) !ParsedInput {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var map = std.ArrayList([]const u8).init(allocator);
    defer map.deinit();

    var starting_pos: Point = undefined;
    var i: usize = 0;

    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 500)) |line| {
        try map.append(line);

        if (std.mem.indexOfScalar(u8, line, '^')) |idx| {
            starting_pos = .{ .x = idx, .y = i };
        }

        i += 1;
    }

    return .{ .map = try map.toOwnedSlice(), .starting_pos = starting_pos };
}

const Direction = enum { up, right, down, left };

fn getGuardsPosCount(map: []const []const u8, starting_pos: Point, allocator: std.mem.Allocator) !u32 {
    var direction: Direction = Direction.up;
    var curr_pos: Point = starting_pos;

    var visited_positions = std.AutoHashMap(Point, void).init(allocator);
    defer visited_positions.deinit();

    try visited_positions.putNoClobber(curr_pos, undefined);

    while (getNextPosAndDirection(map, curr_pos, direction)) |next_pos_and_direction| {
        const next_pos = next_pos_and_direction.pos;
        direction = next_pos_and_direction.direction;

        _ = try visited_positions.getOrPut(next_pos);
        curr_pos = next_pos;
    }

    return @intCast(visited_positions.count());
}

fn getNumOfPossibleObstructions(map: []const []const u8, starting_pos: Point, allocator: std.mem.Allocator) !u32 {
    var curr_pos = starting_pos;
    var direction = Direction.up;

    var tested_obstructions = std.AutoHashMap(Point, void).init(allocator);
    defer tested_obstructions.deinit();

    var sum: u32 = 0;

    while (getNextPosAndDirection(map, curr_pos, direction)) |next_pos_and_direction| {
        const next_pos = next_pos_and_direction.pos;

        const get_or_put_result = try tested_obstructions.getOrPut(next_pos);

        if (get_or_put_result.found_existing) {
            curr_pos = next_pos;
            direction = next_pos_and_direction.direction;
            continue;
        }

        if (try isGuardInLoop(map, curr_pos, direction, next_pos, allocator)) {
            sum += 1;
        }

        curr_pos = next_pos;
        direction = next_pos_and_direction.direction;
    }

    return sum;
}

fn isGuardInLoop(map: []const []const u8, starting_pos: Point, direction: Direction, obstruction_pos: Point, allocator: std.mem.Allocator) !bool {
    var curr_pos = starting_pos;
    var curr_direction = direction;

    var visited_obstructions = std.AutoHashMap(PositionAndDirection, void).init(allocator);
    defer visited_obstructions.deinit();

    while (getNextPos(map, curr_pos, curr_direction)) |next_pos| {
        if (map[next_pos.y][next_pos.x] != '#' and !std.meta.eql(next_pos, obstruction_pos)) {
            curr_pos = next_pos;
            continue;
        }

        const curr_pos_and_direction = PositionAndDirection{ .pos = curr_pos, .direction = curr_direction };
        const get_or_put_result = try visited_obstructions.getOrPut(curr_pos_and_direction);

        if (get_or_put_result.found_existing) {
            return true;
        }

        rotateGuard(&curr_direction);
    }

    return false;
}

///returns null, when next position is outside of map
fn getNextPos(map: []const []const u8, curr_pos: Point, direction: Direction) ?Point {
    const next_pos = switch (direction) {
        Direction.up => .{ .x = curr_pos.x, .y = curr_pos.y -% 1 },
        Direction.right => .{ .x = curr_pos.x +% 1, .y = curr_pos.y },
        Direction.down => .{ .x = curr_pos.x, .y = curr_pos.y +% 1 },
        Direction.left => .{ .x = curr_pos.x -% 1, .y = curr_pos.y },
    };

    if (next_pos.y >= map.len or next_pos.x >= map[next_pos.y].len) {
        return null;
    }

    return next_pos;
}

///returns null, when next position is outside of map
fn getNextPosAndDirection(map: []const []const u8, curr_pos: Point, direction: Direction) ?PositionAndDirection {
    var result_direction = direction;

    while (getNextPos(map, curr_pos, result_direction)) |next_pos| {
        if (map[next_pos.y][next_pos.x] == '#') {
            rotateGuard(&result_direction);
            continue;
        }

        return .{ .pos = next_pos, .direction = result_direction };
    }

    return null;
}

fn rotateGuard(direction: *Direction) void {
    direction.* = switch (direction.*) {
        Direction.up => Direction.right,
        Direction.right => Direction.down,
        Direction.down => Direction.left,
        Direction.left => Direction.up,
    };
}

test "part1" {
    const parsed_input = getTestInput();
    const allocator = std.heap.page_allocator;

    const result = try getGuardsPosCount(parsed_input.map, parsed_input.starting_pos, allocator);

    try expectEqual(41, result);
}

test "part2" {
    const parsed_input = getTestInput();
    const allocator = std.heap.page_allocator;

    const result = try getNumOfPossibleObstructions(parsed_input.map, parsed_input.starting_pos, allocator);

    try expectEqual(6, result);
}

inline fn getTestInput() ParsedInput {
    var map = [_][]const u8{ "....#.....", ".........#", "..........", "..#.......", ".......#..", "..........", ".#..^.....", "........#.", "#.........", "......#..." };

    return .{ .map = &map, .starting_pos = .{ .x = 4, .y = 6 } };
}
