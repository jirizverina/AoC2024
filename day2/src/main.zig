const std = @import("std");
const expect = std.testing.expect;

pub fn main() !void {
    const result = try getNumOfSafeLines();

    std.debug.print("Result is {}\n", .{result});
}

fn getNumOfSafeLines() !i32 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var sum: i32 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (try isLineSafe(line)) {
            sum += 1;
        }
    }

    return sum;
}

fn isLineSafe(line: []const u8) !bool {
    var asc: ?bool = null;
    var prevNum: ?i32 = null;

    var splitIt = std.mem.splitScalar(u8, line, ' ');

    while (splitIt.next()) |c| {
        const num = try std.fmt.parseInt(i32, c, 10);

        if (prevNum == null) {
            prevNum = num;
            continue;
        }

        if (asc == null) {
            asc = num > prevNum.?;
        }

        if (num == prevNum.?) {
            return false;
        }

        if (asc.? and (num < prevNum.? or num - 3 > prevNum.?)) {
            return false;
        }

        if (!asc.? and (num > prevNum.? or num + 3 < prevNum.?)) {
            return false;
        }

        prevNum = num;
    }

    return true;
}

test "should return false" {
    try expect(try isLineSafe("1 1 1") == false);
    try expect(try isLineSafe("1 2 2") == false);
    try expect(try isLineSafe("1 5 9") == false);
    try expect(try isLineSafe("9 5 1") == false);
    try expect(try isLineSafe("1 2 9") == false);
    try expect(try isLineSafe("1 9 2") == false);
    try expect(try isLineSafe("9 5 7") == false);
    try expect(try isLineSafe("0 2 6") == false);
}

test "should return true" {
    try expect(try isLineSafe("1 2 3") == true);
    try expect(try isLineSafe("1 4 7") == true);
    try expect(try isLineSafe("7 4 1") == true);
    try expect(try isLineSafe("1 2 5") == true);
    try expect(try isLineSafe("9 8 6") == true);
    try expect(try isLineSafe("9 6 5") == true);
    try expect(try isLineSafe("0 2 5") == true);
}
