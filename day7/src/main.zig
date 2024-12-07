const std = @import("std");
const expectEqual = std.testing.expectEqual;
const math = std.math;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const parsed_input = try parseInput(allocator);

    const result = getTotalCalibrationResult(parsed_input);
    std.debug.print("Result for part 1 is {}\n", .{result});

    const result2 = getTotalCalibrationResult2(parsed_input);
    std.debug.print("Result for part 2 is {}\n", .{result2});
}

const CalibrationEquation = struct { result: u64, nums: []const u64 };
const ParseInputError = error{InvalidInput};
const Operation = enum { addition, multiplication };

fn parseInput(allocator: std.mem.Allocator) ![]CalibrationEquation {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var equations = std.ArrayList(CalibrationEquation).init(allocator);
    defer equations.deinit();

    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 500)) |line| {
        const colon_idx = std.mem.indexOfScalar(u8, line, ':') orelse return error.InvalidInput;
        const result = try std.fmt.parseInt(u64, line[0..colon_idx], 10);
        var it = std.mem.splitScalar(u8, line[(colon_idx + 2)..], ' ');

        var nums = std.ArrayList(u64).init(allocator);
        defer nums.deinit();

        while (it.next()) |n| {
            const num = try std.fmt.parseInt(u64, n, 10);
            try nums.append(num);
        }

        try equations.append(.{ .result = result, .nums = try nums.toOwnedSlice() });
    }

    return try equations.toOwnedSlice();
}

fn getTotalCalibrationResult(equations: []const CalibrationEquation) u64 {
    var sum: u64 = 0;

    for (equations) |equation| {
        if (addOrMultiplyNums(equation.nums[1..], equation.result, equation.nums[0])) {
            sum += equation.result;
        }
    }

    return sum;
}

fn getTotalCalibrationResult2(equations: []const CalibrationEquation) u64 {
    var sum: u64 = 0;

    for (equations) |equation| {
        if (addOrMultiplyOrConcatNums(equation.nums[1..], equation.result, equation.nums[0])) {
            sum += equation.result;
        }
    }

    return sum;
}

fn addOrMultiplyNums(nums: []const u64, expected_result: u64, curr_result: u64) bool {
    if (curr_result > expected_result) {
        return false;
    }

    if (nums.len == 0) {
        return curr_result == expected_result;
    }

    if (addOrMultiplyNums(nums[1..], expected_result, nums[0] * curr_result)) {
        return true;
    }

    return addOrMultiplyNums(nums[1..], expected_result, nums[0] + curr_result);
}

fn addOrMultiplyOrConcatNums(nums: []const u64, expected_result: u64, curr_result: u64) bool {
    if (curr_result > expected_result) {
        return false;
    }

    if (nums.len == 0) {
        return curr_result == expected_result;
    }

    if (addOrMultiplyOrConcatNums(nums[1..], expected_result, nums[0] * curr_result)) {
        return true;
    }

    if (addOrMultiplyOrConcatNums(nums[1..], expected_result, nums[0] + curr_result)) {
        return true;
    }

    const num = nums[0];
    const digits: u64 = math.log10_int(num) + 1;
    const result = curr_result * math.pow(u64, 10, digits) + num;

    return addOrMultiplyOrConcatNums(nums[1..], expected_result, result);
}

test "getTotalCalibrationResult" {
    const input = getTestInput();
    const result = getTotalCalibrationResult(input);

    try expectEqual(3749, result);
}

test "getTotalCalibrationResult2" {
    const input = getTestInput();
    const result = getTotalCalibrationResult2(input);

    try expectEqual(11387, result);
}

inline fn getTestInput() []const CalibrationEquation {
    const equations = [_]CalibrationEquation{
        .{ .result = 190, .nums = &[_]u64{ 10, 19 } },
        .{ .result = 3267, .nums = &[_]u64{ 81, 40, 27 } },
        .{ .result = 83, .nums = &[_]u64{ 17, 5 } },
        .{ .result = 156, .nums = &[_]u64{ 15, 6 } },
        .{ .result = 7290, .nums = &[_]u64{ 6, 8, 6, 15 } },
        .{ .result = 161011, .nums = &[_]u64{ 16, 10, 13 } },
        .{ .result = 192, .nums = &[_]u64{ 17, 8, 14 } },
        .{ .result = 21037, .nums = &[_]u64{ 9, 7, 18, 13 } },
        .{ .result = 292, .nums = &[_]u64{ 11, 6, 16, 20 } },
    };

    return &equations;
}
