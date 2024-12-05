const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const parsed_input = try parseInput(allocator);
    const result = getSumOfMidNumsOnValidLines(parsed_input);

    std.debug.print("Result is {}", .{result});
}

const Rule = struct { first_page: i32, second_page: i32 };

const ParsedInput = struct { rules: []const Rule, rows: []const []const i32 };

fn parseInput(allocator: std.mem.Allocator) !ParsedInput {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var rules_list = std.ArrayList(Rule).init(allocator);
    defer rules_list.deinit();

    var rows_list = std.ArrayList([]i32).init(allocator);
    defer rows_list.deinit();

    var readingRules = true;
    var i: i32 = 0;

    while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 20_000)) |line| {
        i += 1;
        if (line.len == 0) {
            readingRules = false;
            continue;
        }

        if (readingRules) {
            const rule = try parseRule(line);
            try rules_list.append(rule);

            continue;
        }

        try rows_list.append(try parsePages(line, allocator));
    }

    const rules = try rules_list.toOwnedSlice();
    const rows = try rows_list.toOwnedSlice();

    return .{ .rules = rules, .rows = rows };
}

fn parseRule(line: []const u8) !Rule {
    var it = std.mem.splitScalar(u8, line, '|');
    const first = try std.fmt.parseInt(i32, it.first(), 10);
    const second = try std.fmt.parseInt(i32, it.next().?, 10);

    return .{ .first_page = first, .second_page = second };
}

fn parsePages(line: []const u8, allocator: std.mem.Allocator) ![]i32 {
    var it = std.mem.splitScalar(u8, line, ',');

    var page_nums = std.ArrayList(i32).init(allocator);
    defer page_nums.deinit();

    while (it.next()) |n| {
        const page_num: i32 = try std.fmt.parseInt(i32, n, 10);
        try page_nums.append(page_num);
    }

    return try page_nums.toOwnedSlice();
}

fn getSumOfMidNumsOnValidLines(input: ParsedInput) i32 {
    var sum: i32 = 0;
    for (input.rows) |row| {
        if (isLineValid(row, input.rules)) {
            const idx_mid: usize = row.len / 2;
            sum += row[idx_mid];
        }
    }

    return sum;
}

fn isLineValid(row: []const i32, rules: []const Rule) bool {
    for (rules) |rule| {
        const idx1 = std.mem.indexOfScalar(i32, row, rule.first_page) orelse continue;
        const idx2 = std.mem.indexOfScalar(i32, row, rule.second_page) orelse continue;

        if (idx1 >= idx2) {
            return false;
        }
    }
    return true;
}

test "part1" {
    const input_rules = [_]Rule{
        .{ .first_page = 47, .second_page = 53 },
        .{ .first_page = 97, .second_page = 13 },
        .{ .first_page = 97, .second_page = 61 },
        .{ .first_page = 97, .second_page = 47 },
        .{ .first_page = 75, .second_page = 29 },
        .{ .first_page = 61, .second_page = 13 },
        .{ .first_page = 75, .second_page = 53 },
        .{ .first_page = 29, .second_page = 13 },
        .{ .first_page = 97, .second_page = 29 },
        .{ .first_page = 53, .second_page = 29 },
        .{ .first_page = 61, .second_page = 53 },
        .{ .first_page = 97, .second_page = 53 },
        .{ .first_page = 61, .second_page = 29 },
        .{ .first_page = 47, .second_page = 13 },
        .{ .first_page = 75, .second_page = 47 },
        .{ .first_page = 97, .second_page = 75 },
        .{ .first_page = 47, .second_page = 61 },
        .{ .first_page = 75, .second_page = 61 },
        .{ .first_page = 47, .second_page = 29 },
        .{ .first_page = 75, .second_page = 13 },
        .{ .first_page = 53, .second_page = 13 },
    };

    var known_at_runtime_zero: usize = 0;
    _ = &known_at_runtime_zero;

    const input_rows = [_][]const i32{
        ([5]i32{ 75, 47, 61, 53, 29 })[known_at_runtime_zero..5],
        ([5]i32{ 97, 61, 53, 29, 13 })[known_at_runtime_zero..5],
        ([3]i32{ 75, 29, 13 })[known_at_runtime_zero..3],
        ([5]i32{ 75, 97, 47, 61, 53 })[known_at_runtime_zero..5],
        ([3]i32{ 61, 13, 29 })[known_at_runtime_zero..3],
        ([5]i32{ 97, 13, 75, 29, 47 })[known_at_runtime_zero..5],
    };

    const input = ParsedInput{ .rules = &input_rules, .rows = &input_rows };
    const result = getSumOfMidNumsOnValidLines(input);

    try expectEqual(143, result);
}
