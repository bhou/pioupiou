const std = @import("std");
const thread = std.thread;
const Game = @import("../model/game.zig").Game;
const State = @import("../model/game.zig").State;
const Action = @import("../model/action.zig").Action;

const http = std.http;
const Allocator = std.mem.Allocator;

const r = @cImport({
    @cInclude("raylib.h");
});

const HttpClient = http.Client;

fn httpGet(allocator: Allocator, url: []const u8) ![]const u8 {
    var client = HttpClient{ .allocator = allocator };
    errdefer client.deinit();

    {
        var h = http.Headers{ .allocator = allocator };
        defer h.deinit();

        const uri = try std.Uri.parse(url);

        var req = try client.request(.GET, uri, h, .{});
        defer req.deinit();

        try req.start();
        try req.wait();

        const body = try req.reader().readAllAlloc(allocator, 8192000);
        return body;
    }
}

const Image = struct {
    width: usize,
    height: usize,
    id: []u8,
    url: []u8,
    author: []u8 = "",
};

pub const GptAgent = struct {
    player_idx: u8,

    game: *Game,

    game_version: usize,
    state: *State,
    turn_idx_cache: u8,

    pub fn init(game: *Game, player_idx: u8) GptAgent {
        var allocator = std.heap.page_allocator;
        // const body = httpGet(allocator, "http://google.com/") catch |err| x: {
        //     std.debug.print("error: {}\n", .{err});
        //     break :x "";
        // };
        const body = httpGet(allocator, "https://api.thecatapi.com/v1/images/search") catch unreachable;
        defer allocator.free(body);
        std.debug.print("body: {s}\n", .{body});
        const parsed = std.json.parseFromSlice([]Image, allocator, body, .{
            .ignore_unknown_fields = true,
        }) catch unreachable;
        defer parsed.deinit();

        std.debug.print("parsed: {d}\n", .{parsed.value.len});

        std.debug.print("image id: {s}\n", .{parsed.value[0].id});
        std.debug.print("image url: {s}\n", .{parsed.value[0].url});
        std.debug.print("image width: {d}\n", .{parsed.value[0].width});
        std.debug.print("image height: {d}\n", .{parsed.value[0].height});

        return GptAgent{
            .player_idx = player_idx,
            .game = game,
            .game_version = game.getVersion(),
            .state = @constCast(&game.getState()),
            .turn_idx_cache = 255,
        };
    }

    pub fn run(self: *GptAgent) !void {
        while (!r.WindowShouldClose()) {
            if (self.game.getVersion() != self.game_version) {
                self.game_version = self.game.getVersion();
                self.state = @constCast(&self.game.getState());
            }

            if (self.turn_idx_cache == self.state.turn_idx) {
                // the turn doesn't change, do nothing
                std.time.sleep(100 * std.time.ns_per_ms);
                continue;
            }

            // update turn cache
            self.turn_idx_cache = self.state.turn_idx;

            // now contact GPT service for next move
            if (self.turn_idx_cache == self.player_idx) {
                std.debug.print("GPT agent is thinking...\n", .{});

                // interaction with GPT service
                while (true) {
                    std.time.sleep(100 * std.time.ns_per_ms);
                }
            }

            std.time.sleep(100 * std.time.ns_per_ms);
        }
    }
};
