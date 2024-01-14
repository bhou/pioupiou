const std = @import("std");
const thread = std.thread;
const Game = @import("../model/game.zig").Game;
const State = @import("../model/game.zig").State;
const Action = @import("../model/action.zig").Action;

const r = @cImport({
    @cInclude("raylib.h");
});

pub const GptAgent = struct {
    player_idx: u8,

    game: *Game,

    game_version: usize,
    state: *State,
    turn_idx_cache: u8,

    pub fn init(game: *Game, player_idx: u8) GptAgent {
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
