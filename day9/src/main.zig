const std = @import("std");
const expectEqual = std.testing.expectEqual;
const math = std.math;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    try solvePart1(gpa.allocator());
    try solvePart2(gpa.allocator());
}

fn getInput(allocator: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    const result = try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 20_000);

    return result.?;
}

fn solvePart1(allocator: std.mem.Allocator) !void {
    const input = try getInput(allocator);

    const disc_composition = try getDiscComposition(input, allocator);
    reorderFiles(disc_composition);
    const check_sum = calculateCheckSum(disc_composition);

    std.debug.print("Result for part 1 is {}\n", .{check_sum});
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
            continue;
        }

        sum += @as(usize, @intCast(val.?)) * i;
    }

    return sum;
}

fn solvePart2(allocator: std.mem.Allocator) !void {
    const input = try getInput(allocator);

    const disc_composition = try getDiscComposition(input, allocator);
    reorderFiles2(disc_composition);
    const check_sum = calculateCheckSum(disc_composition);

    std.debug.print("Result for part 2 is {}\n", .{check_sum});
}

fn reorderFiles2(disc_composition: []?u32) void {
    var j: usize = @intCast(disc_composition.len);

    outer: while (j > 1) {
        j -= 1;

        const b = disc_composition[j] orelse continue;
        var size_b: usize = 1;
        var x: usize = j - 1;
        while (x > 0 and disc_composition[x] == b) {
            x -= 1;
            size_b += 1;
        }

        var i: usize = 0;
        while (i < j - size_b + 1) {
            if (disc_composition[i]) |_| {
                i += 1;
                continue;
            }

            var size_s: usize = 1;
            var y: usize = i + 1;
            while (y < (j - size_b + 1) and disc_composition[y] == null) {
                y += 1;
                size_s += 1;
            }

            if (size_b > size_s) {
                i += 1;
                continue;
            }

            for (0..size_b) |z| {
                disc_composition[i + z] = disc_composition[j - z];
                disc_composition[j - z] = null;
            }

            j = j - size_b + 1;
            continue :outer;
        }

        j = j - size_b + 1;
    }
}

test "part1" {
    const input: []const u8 = "2333133121414131402";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator(); //std.testing.allocator;
    const disc = try getDiscComposition(input, allocator);
    reorderFiles(disc);
    const result = calculateCheckSum(disc);

    try expectEqual(1928, result);
}

test "part2" {
    const input: []const u8 = "2333133121414131402";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator(); //std.testing.allocator;
    const disc = try getDiscComposition(input, allocator);
    printSlice(disc);
    reorderFiles2(disc);
    printSlice(disc);
    const result = calculateCheckSum(disc);

    try expectEqual(2858, result);
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
