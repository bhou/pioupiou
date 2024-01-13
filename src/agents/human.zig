const std = @import("std");
const thread = std.Thread;
const Game = @import("../model/game.zig").Game;
const State = @import("../model/game.zig").State;
const Action = @import("../model/action.zig").Action;

const r = @cImport({
    @cInclude("raylib.h");
});

pub const HumanAgent = struct {
    game: *Game,

    game_version: usize,
    state: *State,

    pub fn init(game: *Game) HumanAgent {
        return HumanAgent{
            .game = game,
            .game_version = game.getVersion(),
            .state = @constCast(&game.getState()),
        };
    }

    pub fn run(self: *HumanAgent) !void {
        var game = self.game;
        while (!r.WindowShouldClose()) {
            if (self.game_version != game.getVersion()) {
                self.game_version = game.getVersion();
                self.state = @constCast(&game.getState());
            }

            if (r.IsKeyPressed(r.KEY_SPACE)) {
                std.debug.print("space pressed\n", .{});
                std.time.sleep(100 * std.time.ns_per_ms);
            }
            if (r.IsKeyPressed(r.KEY_ONE)) {
                try game.handle(self.state.turn_idx, Action.EXCHANGE_CARD_1);
                std.time.sleep(100 * std.time.ns_per_ms);
            }
            if (r.IsKeyPressed(r.KEY_TWO)) {
                try game.handle(self.state.turn_idx, Action.EXCHANGE_CARD_2);
                std.time.sleep(100 * std.time.ns_per_ms);
            }
            if (r.IsKeyPressed(r.KEY_THREE)) {
                try game.handle(self.state.turn_idx, Action.EXCHANGE_CARD_3);
                std.time.sleep(100 * std.time.ns_per_ms);
            }
            if (r.IsKeyPressed(r.KEY_FOUR)) {
                try game.handle(self.state.turn_idx, Action.EXCHANGE_CARD_4);
                std.time.sleep(100 * std.time.ns_per_ms);
            }
            if (r.IsKeyPressed(r.KEY_L)) {
                try game.handle(self.state.turn_idx, Action.LAY_EGG);
                std.time.sleep(100 * std.time.ns_per_ms);
            }
            if (r.IsKeyPressed(r.KEY_H)) {
                try game.handle(self.state.turn_idx, Action.HATCH_EGG);
                std.time.sleep(100 * std.time.ns_per_ms);
            }
            if (r.IsKeyPressed(r.KEY_S)) {
                try game.handle(self.state.turn_idx, Action.STEAL_EGG);
                std.time.sleep(100 * std.time.ns_per_ms);
            }
            if (r.IsKeyPressed(r.KEY_D)) {
                try game.handle(self.state.turn_idx, Action.DEFEND_EGG);
                std.time.sleep(100 * std.time.ns_per_ms);
            }
        }
    }
};

/// an agent to manage the interaction between the game and the user
pub fn run(game: *Game, state: *State) !void {
    while (!r.WindowShouldClose()) {
        if (r.IsKeyPressed(r.KEY_SPACE)) {
            std.debug.print("space pressed\n", .{});
            std.time.sleep(100 * std.time.ns_per_ms);
        }
        if (r.IsKeyPressed(r.KEY_ONE)) {
            try game.handle(state.turn_idx, Action.EXCHANGE_CARD_1);
            std.time.sleep(100 * std.time.ns_per_ms);
        }
        if (r.IsKeyPressed(r.KEY_TWO)) {
            try game.handle(state.turn_idx, Action.EXCHANGE_CARD_2);
            std.time.sleep(100 * std.time.ns_per_ms);
        }
        if (r.IsKeyPressed(r.KEY_THREE)) {
            try game.handle(state.turn_idx, Action.EXCHANGE_CARD_3);
            std.time.sleep(100 * std.time.ns_per_ms);
        }
        if (r.IsKeyPressed(r.KEY_FOUR)) {
            try game.handle(state.turn_idx, Action.EXCHANGE_CARD_4);
            std.time.sleep(100 * std.time.ns_per_ms);
        }
        if (r.IsKeyPressed(r.KEY_L)) {
            try game.handle(state.turn_idx, Action.LAY_EGG);
            std.time.sleep(100 * std.time.ns_per_ms);
        }
        if (r.IsKeyPressed(r.KEY_H)) {
            try game.handle(state.turn_idx, Action.HATCH_EGG);
            std.time.sleep(100 * std.time.ns_per_ms);
        }
        if (r.IsKeyPressed(r.KEY_S)) {
            try game.handle(state.turn_idx, Action.STEAL_EGG);
            std.time.sleep(100 * std.time.ns_per_ms);
        }
        if (r.IsKeyPressed(r.KEY_D)) {
            try game.handle(state.turn_idx, Action.DEFEND_EGG);
            std.time.sleep(100 * std.time.ns_per_ms);
        }
    }
}