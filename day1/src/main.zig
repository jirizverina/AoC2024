const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const parsedInput = try readInput(allocator);

    std.mem.sort(i32, parsedInput.array1, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, parsedInput.array2, {}, comptime std.sort.asc(i32));

    const diff_sum = getDiffSum(parsedInput.array1, parsedInput.array2);

    std.debug.print("Difference: {}\n", .{diff_sum});

    const similarity_sum = try getSimilaritySum(parsedInput.array1, parsedInput.array2);

    std.debug.print("Similarity: {}\n", .{similarity_sum});
}

fn getDiffSum(array1: []i32, array2: []i32) i32 {
    std.debug.assert(array1.len == array2.len);
    var sum: i32 = 0;

    for (array1, array2) |i, j| {
        sum += if (i > j) i - j else j - i;
    }

    return sum;
}

fn getSimilaritySum(array1: []i32, array2: []i32) !i32 {
    std.debug.assert(array1.len == array2.len);
    var sum: i32 = 0;

    var hash_map = std.AutoHashMap(i32, i32).init(std.heap.page_allocator);
    defer hash_map.deinit();

    for (array2) |j| {
        if (hash_map.getEntry(j)) |entry| {
            entry.value_ptr.* += 1;
            std.debug.assert(entry.value_ptr.* == hash_map.get(j));
            continue;
        }

        try hash_map.put(j, 1);
        continue;
    }

    for (array1) |i| {
        if (hash_map.get(i)) |val| {
            sum += i * val;
        }
    }

    return sum;
}

const ParsedInput = struct { array1: []i32, array2: []i32 };

fn readInput(allocator: std.mem.Allocator) !ParsedInput {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var list1 = std.ArrayList(i32).init(allocator);
    var list2 = std.ArrayList(i32).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const split_idx = std.mem.indexOf(u8, line, "   ");
        std.debug.assert(split_idx != null);

        const part1 = line[0..split_idx.?];
        const part2 = line[split_idx.? + 3 ..];

        const num1 = try std.fmt.parseInt(i32, part1, 10);
        const num2 = try std.fmt.parseInt(i32, part2, 10);

        try list1.append(num1);
        try list2.append(num2);
    }

    const arr1 = try list1.toOwnedSlice();
    list1.deinit();
    const arr2 = try list2.toOwnedSlice();
    list2.deinit();

    return ParsedInput{
        .array1 = arr1,
        .array2 = arr2,
    };
}
