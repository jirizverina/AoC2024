const std = @import("std");
const expect = std.testing.expect;

pub fn main() !void {
    const result = try getResult();

    std.debug.print("Result is {}\n", .{result});
}

fn getResult() !i64 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [20000]u8 = undefined;
    var sum: i64 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        sum += try getMul(line);
    }

    return sum;
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

test "part1" {
    const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    const result = try getMul(input);

    try expect(result == 161);
}
