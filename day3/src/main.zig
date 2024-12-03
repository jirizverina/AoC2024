const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try getResult(allocator);

    std.debug.print("Part 1 is {} and Part 2 is {}\n", .{ result.part1, result.part2 });
}

const Result = struct { part1: i64, part2: i64 };

fn getResult(allocator: std.mem.Allocator) !Result {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var sum1: i64 = 0;
    var sum2: i64 = 0;

    const buffer = try in_stream.readAllAlloc(allocator, 20_000);
    defer allocator.free(buffer);

    sum1 = try getMul(buffer);
    sum2 = try getMul2(buffer);

    return Result{ .part1 = sum1, .part2 = sum2 };
}

fn getMul(line: []const u8) !i64 {
    var result: i64 = 0;
    var digits1: [16]u8 = undefined;
    var digits2: [16]u8 = undefined;
    var digit1_idx: usize = 0;
    var digit2_idx: usize = 0;

    var fill_first_num = true;

    const expected_start = "mul(";
    var expected_start_idx: usize = 0;

    for (line) |c| {
        if (expected_start_idx >= 4) {
            switch (c) {
                ',' => {
                    fill_first_num = false;
                    continue;
                },
                ')' => {
                    if (!fill_first_num) {
                        const num1 = try std.fmt.parseInt(i64, digits1[0..(digit1_idx)], 10);
                        const num2 = try std.fmt.parseInt(i64, digits2[0..(digit2_idx)], 10);

                        result += num1 * num2;
                    }
                },
                '0'...'9' => {
                    if (fill_first_num) {
                        digits1[digit1_idx] = c;
                        digit1_idx += 1;
                    } else {
                        digits2[digit2_idx] = c;
                        digit2_idx += 1;
                    }

                    continue;
                },
                else => {},
            }

            digits1 = undefined;
            digits2 = undefined;
            fill_first_num = true;
            digit1_idx = 0;
            digit2_idx = 0;

            expected_start_idx = 0;
            continue;
        }

        if (c == expected_start[expected_start_idx]) {
            expected_start_idx += 1;
            continue;
        }

        expected_start_idx = 0;
    }

    return result;
}

fn getMul2(line: []const u8) !i64 {
    var sum: i64 = 0;
    var is_first_run = true;
    var dont_it = std.mem.splitSequence(u8, line, "don't");

    //std.debug.print("\nLine is {s}\n", .{line});

    while (dont_it.next()) |dont| {
        var do_idx: usize = undefined;
        if (is_first_run) {
            do_idx = 0;
            is_first_run = false;
        } else {
            do_idx = std.mem.indexOf(u8, dont, "do") orelse dont.len - 1;
        }

        //std.debug.print("Dont {s}\n", .{dont});
        //std.debug.print("Do {s} with index {}\n", .{ dont[do_idx..], do_idx });
        sum += try getMul(dont[do_idx..]);
    }

    return sum;
}

test "part1" {
    const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    const result = try getMul(input);

    try expectEqual(161, result);
}

test "part2" {
    const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    const result = try getMul2(input);

    try expectEqual(48, result);
}
