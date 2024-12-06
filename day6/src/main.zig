const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const parsed_input = try createMapFromInput(allocator);
    const result = try getGuardsPosCount(parsed_input.map, parsed_input.starting_pos, allocator);

    std.debug.print("Result is {}\n", .{result});
}

const Point = struct { x: usize, y: usize };
const ParsedInput = struct { map: [][]u8, starting_pos: Point };

fn createMapFromInput(allocator: std.mem.Allocator) !ParsedInput {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var map = std.ArrayList([]u8).init(allocator);
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

fn getGuardsPosCount(map: [][]u8, starting_pos: Point, allocator: std.mem.Allocator) !i32 {
    var direction: Direction = Direction.up;
    var curr_pos: Point = starting_pos;

    var visited_positions = std.AutoHashMap(Point, void).init(allocator);
    defer visited_positions.deinit();

    try visited_positions.putNoClobber(curr_pos, undefined);

    while (true) {
        const next_pos = switch (direction) {
            Direction.up => .{ .x = curr_pos.x, .y = curr_pos.y -% 1 },
            Direction.right => .{ .x = curr_pos.x +% 1, .y = curr_pos.y },
            Direction.down => .{ .x = curr_pos.x, .y = curr_pos.y +% 1 },
            Direction.left => .{ .x = curr_pos.x -% 1, .y = curr_pos.y },
        };

        //std.debug.print("Current position: x = {}, y = {} \n", .{ curr_pos.x, curr_pos.y });
        //std.debug.print("Next position: x = {}, y = {} \n", .{ next_pos.x, next_pos.y });

        if (next_pos.y >= map.len or next_pos.x >= map[next_pos.y].len) {
            //std.debug.print("Guard is outside\n", .{});
            break;
        }

        if (map[next_pos.y][next_pos.x] == '#') {
            //std.debug.print("Rotating guard from direction {s}", .{@tagName(direction)});
            rotateGuard(&direction);
            //std.debug.print(" to direction {s}\n", .{@tagName(direction)});
            continue;
        }

        const get_or_put_result = try visited_positions.getOrPut(next_pos);
        if (get_or_put_result.found_existing) {
            //std.debug.print("Position has been already visited\n", .{});
        } else {
            //std.debug.print("Position was not visited\n", .{});
        }

        curr_pos = next_pos;
    }

    return @intCast(visited_positions.count());
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
    const parsed_input = getTestMap();
    const allocator = std.heap.page_allocator;

    const result = try getGuardsPosCount(parsed_input.map, parsed_input.starting_pos, allocator);

    try expectEqual(41, result);
}

inline fn getTestMap() ParsedInput {
    var arr1 = [_]u8{ '.', '.', '.', '.', '#', '.', '.', '.', '.', '.' };
    var arr2 = [_]u8{ '.', '.', '.', '.', '.', '.', '.', '.', '.', '#' };
    var arr3 = [_]u8{ '.', '.', '.', '.', '.', '.', '.', '.', '.', '.' };
    var arr4 = [_]u8{ '.', '.', '#', '.', '.', '.', '.', '.', '.', '.' };
    var arr5 = [_]u8{ '.', '.', '.', '.', '.', '.', '.', '#', '.', '.' };
    var arr6 = [_]u8{ '.', '.', '.', '.', '.', '.', '.', '.', '.', '.' };
    var arr7 = [_]u8{ '.', '#', '.', '.', '^', '.', '.', '.', '.', '.' };
    var arr8 = [_]u8{ '.', '.', '.', '.', '.', '.', '.', '.', '#', '.' };
    var arr9 = [_]u8{ '#', '.', '.', '.', '.', '.', '.', '.', '.', '.' };
    var arr10 = [_]u8{ '.', '.', '.', '.', '.', '.', '#', '.', '.', '.' };

    var map = [_][]u8{
        &arr1,
        &arr2,
        &arr3,
        &arr4,
        &arr5,
        &arr6,
        &arr7,
        &arr8,
        &arr9,
        &arr10,
    };

    return .{ .map = &map, .starting_pos = .{ .x = 4, .y = 6 } };
}
