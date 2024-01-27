const std = @import("std");
const Allocator = std.mem.Allocator;

const http = std.http;
const HttpClient = http.Client;

// general http result
pub fn HttpResult(comptime T: type) type {
    return struct {
        allocator: Allocator,
        status: std.http.Status,
        body: []const u8 = "",
        err: []const u8 = "",
        has_error: bool = false,
        parsed: ?std.json.Parsed(T),

        pub fn deinit(self: *HttpResult(T)) void {
            self.allocator.free(self.body);
            self.allocator.free(self.err);
            if (self.parsed != null) {
                self.parsed.?.deinit();
            }
        }
    };
}

/// GET a response with type T from http get request.
/// The caller must deinit the returned result
pub fn get_json(allocator: Allocator, comptime T: type, url: []const u8, headers: anytype) !HttpResult(T) {
    var result = HttpResult(T){ .status = std.http.Status.ok, .parsed = null, .allocator = allocator };
    var client = HttpClient{ .allocator = allocator };
    errdefer client.deinit();
    defer client.deinit();

    var h = http.Headers{ .allocator = allocator };
    defer h.deinit();

    const headers_type = @TypeOf(headers);

    const headers_type_info = @typeInfo(headers_type);
    if (headers_type_info != .Struct) {
        @compileError("expected tuple or struct argument, found " ++ @typeName(headers_type));
    }
    const fields_info = headers_type_info.Struct.fields;
    comptime var i: usize = 0;
    inline while (i < fields_info.len) {
        const field = fields_info[i];
        const field_type_info = @typeInfo(field.type);
        if (field_type_info != .Struct) {
            @compileError("expected tuple or struct as header, found " ++ @typeName(field.type));
        }
        if (field_type_info.Struct.fields.len != 2) {
            @compileError("expected tuple of length 2 as header");
        }

        // TODO: check that the field names are strings
        try h.append(headers[i][0], headers[i][1]);

        i += 1;
    }

    const uri = try std.Uri.parse(url);
    var req = try client.request(.GET, uri, h, .{});
    defer req.deinit();

    try req.start();
    try req.wait();

    var reader = req.reader();
    var buffer: [1024]u8 = undefined;
    var len = try reader.read(&buffer);
    var output = std.ArrayList(u8).init(allocator);
    while (len != 0) {
        try output.appendSlice(buffer[0..len]);
        len = try reader.read(&buffer);
    }
    const body = try output.toOwnedSlice();

    const parsed = try std.json.parseFromSlice(T, allocator, body, .{ .ignore_unknown_fields = true });

    result.status = req.response.status;
    result.body = body;
    result.parsed = parsed;
    return result;
}

test "test http get" {
    const Image = struct {
        width: usize,
        height: usize,
        id: []u8,
        url: []u8,
        author: []u8 = "",
    };
    var hello: []u8 = try std.testing.allocator.alloc(u8, 5);
    defer std.testing.allocator.free(hello);
    hello[0] = 'h';
    hello[1] = 'e';
    hello[2] = 'l';
    hello[3] = 'l';
    hello[4] = 'o';

    var result = try get_json(std.testing.allocator, []Image, "https://api.thecatapi.com/v1/images/search", .{
        .{ "Content-Type", "application/xml" },
        .{ "Another", hello },
    });
    defer result.deinit();

    for (result.parsed.?.value) |item| {
        std.debug.print("item.width: {d}\n", .{item.width});
        std.debug.print("item.height: {d}\n", .{item.height});
        std.debug.print("item.url: {s}\n", .{item.url});
        std.debug.print("item.id: {s}\n", .{item.id});
    }
}
