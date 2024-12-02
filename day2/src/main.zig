const std = @import("std");
const expect = std.testing.expect;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try getNumOfSafeLines(allocator);

    std.debug.print("Result is {}\n", .{result});
}

fn getNumOfSafeLines(allocator: std.mem.Allocator) !i32 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var sum: i32 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (try isLineSafePart2(line, allocator)) {
            sum += 1;
        }
    }

    return sum;
}

fn isLineSafe(line: []const u8) !bool {
    var splitIt = std.mem.splitScalar(u8, line, ' ');

    var prevNum: i32 = try std.fmt.parseInt(i32, splitIt.first(), 10);
    var num: i32 = try std.fmt.parseInt(i32, splitIt.peek().?, 10);
    const asc = num > prevNum;

    while (splitIt.next()) |c| {
        num = try std.fmt.parseInt(i32, c, 10);
        if (hasFailed(num, prevNum, asc)) {
            return false;
        }

        prevNum = num;
    }

    return true;
}

fn areNumsSafe(nums: []const i32) bool {
    var prevNum = nums[0];
    var num = nums[1];
    const asc = num > prevNum;

    for (nums[1..]) |n| {
        num = n;
        if (hasFailed(num, prevNum, asc)) {
            return false;
        }

        prevNum = num;
    }

    return true;
}

fn isLineSafePart2(line: []const u8, allocator: std.mem.Allocator) !bool {
    var splitIt = std.mem.splitScalar(u8, line, ' ');
    var numList = std.ArrayList(i32).init(allocator);

    while (splitIt.next()) |s| {
        const num = try std.fmt.parseInt(i32, s, 10);
        try numList.append(num);
    }

    const nums = try numList.toOwnedSlice();
    var sentNums: [16]i32 = undefined;

    for (0..nums.len) |i| {
        var j: usize = 0;

        for (0..nums.len) |n| {
            if (i == n) {
                continue;
            }

            sentNums[j] = nums[n];
            j += 1;
        }

        if (areNumsSafe(sentNums[0..(nums.len - 1)])) {
            return true;
        }
    }

    return false;
}

fn hasFailed(num: i32, prevNum: i32, asc: bool) bool {
    if (num == prevNum) {
        return true;
    }

    if (asc and (num < prevNum or num - 3 > prevNum)) {
        return true;
    }

    if (!asc and (num > prevNum or num + 3 < prevNum)) {
        return true;
    }

    return false;
}

test "test part 2" {
    try expect(try isLineSafePart2("7 6 4 2 1", std.heap.page_allocator) == true);
    try expect(try isLineSafePart2("1 2 7 8 9", std.heap.page_allocator) == false);
    try expect(try isLineSafePart2("9 7 6 2 1", std.heap.page_allocator) == false);
    try expect(try isLineSafePart2("1 3 2 4 5", std.heap.page_allocator) == true);
    try expect(try isLineSafePart2("8 6 4 4 1", std.heap.page_allocator) == true);
    try expect(try isLineSafePart2("1 3 6 7 9", std.heap.page_allocator) == true);
}

test "test part 1" {
    try expect(try isLineSafe("7 6 4 2 1") == true);
    try expect(try isLineSafe("1 2 7 8 9") == false);
    try expect(try isLineSafe("9 7 6 2 1") == false);
    try expect(try isLineSafe("1 3 2 4 5") == false);
    try expect(try isLineSafe("8 6 4 4 1") == false);
    try expect(try isLineSafe("1 3 6 7 9") == true);
}
