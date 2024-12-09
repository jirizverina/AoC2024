const std = @import("std");
const expectEqual = std.testing.expectEqual;
const math = std.math;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const input = try getInput(allocator);
    const disc_composition = try getDiscComposition(input, allocator);

    //var len: u64 = 0;
    //for (input) |i| {}

    reorderFiles(disc_composition);
    const check_sum = calculateCheckSum(disc_composition);

    std.debug.print("Result for part 1 is {}\n", .{check_sum});
}

fn getInput(allocator: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    const result = try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 20_000);

    return result.?;
}

fn getDiscComposition(disk_map: []const u8, allocator: std.mem.Allocator) ![]?u32 {
    var list = std.ArrayList(?u32).init(allocator);
    defer list.deinit();

    var id: u32 = 0;

    for (disk_map, 0..disk_map.len) |block_size, i| {
        const size = try std.fmt.charToDigit(block_size, 10);
        if ((i & 1) == 1) {
            try list.appendNTimes(null, size);
            continue;
        }

        try list.appendNTimes(id, size);
        id += 1;
    }

    return list.toOwnedSlice();
}

fn reorderFiles(disc_composition: []?u32) void {
    var j: usize = disc_composition.len;
    var i: usize = 0;

    while (i < j) {
        if (disc_composition[i]) |_| {
            i += 1;
            continue;
        }

        while (i < j) {
            j -= 1;
            const val = disc_composition[j];

            if (val) |v| {
                disc_composition[i] = v;
                disc_composition[j] = null;
                break;
            }
        }

        i += 1;
    }
}

fn calculateCheckSum(disc_composition: []?u32) usize {
    var sum: usize = 0;
    for (disc_composition, 0..disc_composition.len) |val, i| {
        if (val == null) {
            break;
        }

        sum += @as(usize, @intCast(val.?)) * i;
    }

    return sum;
}

test "part1" {
    const input: []const u8 = "2333133121414131402";
    const allocator = std.heap.page_allocator;
    const disc = try getDiscComposition(input, allocator);
    std.debug.print("{s}\n", .{input});
    printSlice(disc);
    reorderFiles(disc);
    printSlice(disc);
    const result = calculateCheckSum(disc);

    try expectEqual(1928, result);
}

inline fn printSlice(slice: []?u32) void {
    for (slice) |s| {
        if (s) |val| {
            std.debug.print("{} ", .{val});
        } else {
            std.debug.print(".", .{});
        }
    }

    std.debug.print("\n", .{});
}
