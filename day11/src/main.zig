const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    const blinks = 25;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const nums = try getNumbersFromInput(allocator);

    const part1 = try solve(allocator, nums, blinks);
    std.debug.print("Result for part 1 is {}\n", .{part1});
}

fn getNumbersFromInput(allocator: std.mem.Allocator) ![]u64 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var list = std.ArrayList(u64).init(allocator);
    defer list.deinit();

    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, ' ', 50)) |line| {
        const num = std.fmt.parseInt(u64, line, 10) catch |err| switch (err) {
            std.fmt.ParseIntError.InvalidCharacter => try std.fmt.parseInt(u64, line[0..(line.len - 1)], 10),
            else => |e| return e,
        };

        try list.append(num);
    }
    return try list.toOwnedSlice();
}

fn solve(allocator: std.mem.Allocator, numbers: []const u64, blinks: u7) !u64 {
    //var nums = numbers;
    var sum: u64 = 0;

    //for (0..blinks) |_| {
    //    var list = std.ArrayList(u64).init(allocator);
    //    defer list.deinit();

    //    for (nums) |n| {
    //        if (n == 0) {
    //            try list.append(1);
    //            continue;
    //        }

    //        const n_length = std.math.log10(n) + 1;

    //        if ((n_length & 1) == 0) {
    //            const divider = std.math.pow(u64, 10, n_length / 2);
    //            const first_part: u64 = n / divider;
    //            const second_part: u64 = try std.math.rem(u64, n, divider);

    //            try list.append(first_part);
    //            try list.append(second_part);

    //            continue;
    //        }

    //        //const n_as_string = try std.fmt.allocPrint(allocator, "{}", .{n});

    //        //if ((n_as_string.len & 1) == 0) {
    //        //    const mid_index = n_as_string.len / 2;
    //        //    const first_part = n_as_string[0..mid_index];
    //        //    const second_part = n_as_string[mid_index..];

    //        //    try list.append(try std.fmt.parseInt(u64, first_part, 10));
    //        //    try list.append(try std.fmt.parseInt(u64, second_part, 10));
    //        //    continue;
    //        //}

    //        try list.append(n * 2024);
    //    }

    //    nums = try list.toOwnedSlice();

    //    //std.debug.print("After {} blinks: ", .{i + 1});
    //    //printNums(nums);
    //}

    for (numbers) |n| {
        sum += try getNumberOfStones(allocator, n, 0, blinks);
    }

    //return @intCast(nums.len);
    return sum;
}

fn getNumberOfStones(allocator: std.mem.Allocator, n: u64, depth: u64, max_depth: u64) !u64 {
    if (depth >= max_depth) {
        return 1;
    }

    if (n == 0) {
        return try getNumberOfStones(allocator, 1, depth + 1, max_depth);
    }

    //const n_length = std.math.log10(n) + 1;

    //if ((n_length & 1) == 0) {
    //    const divider = std.math.pow(u64, 10, n_length / 2);
    //    const first_part: u64 = n / divider;
    //    const second_part: u64 = n % divider;

    //    return try getNumberOfStones(allocator, first_part, next_depth, max_depth) + try getNumberOfStones(allocator, second_part, next_depth, max_depth);
    //}
    //
    var n_length: usize = 0;
    var arr: [1024]u4 = undefined;
    var num = n;

    while (num > 0) {
        arr[n_length] = @intCast(num % 10);
        num = num / 10;
        n_length += 1;
    }

    const d = std.math.log2(n_length);
    if ((n_length & 1) == 0) {
        //std.debug.print("Divided number {} with len {} to {any}\n", .{ n, n_length, arr[0..n_length] });
        if (max_depth <= depth + d) {
            var first_n: u64 = 0;
            var second_n: u64 = 0;
            const half = n_length / 2;

            for (0..half) |i| {
                const mul = std.math.pow(u64, 10, i);
                first_n = arr[i] * mul;
                second_n = arr[half + i] * mul;
            }

            return try getNumberOfStones(allocator, first_n, depth + 1, max_depth) + try getNumberOfStones(allocator, second_n, depth + 1, max_depth);
        }

        var sum: u64 = 0;
        for (0..n_length) |i| {
            sum += try getNumberOfStones(allocator, arr[i], depth + d, max_depth);
        }

        return sum;
    }

    return try getNumberOfStones(allocator, n * 2024, depth + 1, max_depth);
}

fn printNums(nums: []const u64) void {
    for (nums) |n| {
        std.debug.print("{} ", .{n});
    }

    std.debug.print("\n", .{});
}

test "part1" {
    var input_arr = [_]u64{ 125, 17 };
    //const allocator = test.allocator;
    const allocator = std.heap.page_allocator;
    const result = try solve(allocator, &input_arr, 6);

    try testing.expectEqual(55312, result);
}
