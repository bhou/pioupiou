const std = @import("std");
const Game = @import("../model/game.zig").Game;
const State = @import("../model/game.zig").State;
const Action = @import("../model/action.zig").Action;

pub const SimpleAgent = struct {
    player_idx: u8, // the index of the player that this agent is controlling

    game: *Game,

    game_version: usize,
    state: *State,

    moved_flag: bool,
    action_delay_s: usize,

    pub fn init(game: *Game, player_idx: u8, action_delay_s: usize) SimpleAgent {
        return SimpleAgent{
            .player_idx = player_idx,
            .game = game,
            .game_version = 99,
            .state = @constCast(&game.getState()),
            .moved_flag = false,
            .action_delay_s = action_delay_s,
        };
    }

    pub fn run(self: *SimpleAgent) !void {
        while (true) {
            // check if there is a new version of the game state
            if (self.game_version != self.game.getVersion()) {
                self.game_version = self.game.getVersion();
                self.state = @constCast(&self.game.getState());

                // check if the same is over
                if (self.state.last_event.action == Action.WIN) {
                    // if (self.state.last_event.player_idx == self.player_idx) {
                    //     std.debug.print("I won!", .{});
                    // } else {
                    //     std.debug.print("I lost!", .{});
                    // }
                    continue;
                }

                if (self.state.last_event.action == Action.DRAW) {
                    // std.debug.print("It's a draw!", .{});
                    continue;
                }

                if (self.state.turn_idx == self.player_idx) {
                    // it is our turn, reset the moved flag
                    self.moved_flag = false;
                }
            }

            // check if it is our turn
            if (self.state.turn_idx != self.player_idx) {
                std.time.sleep(100 * std.time.ns_per_ms);
                continue;
            }

            if (self.moved_flag) {
                // we already moved, waiting for another player to move
                std.time.sleep(100 * std.time.ns_per_ms);
                continue;
            }

            const another_player_idx = (self.player_idx + 1) % 2;

            // first mark we have moved
            self.moved_flag = true;
            // wait 5 second to simulate thinking
            if (self.action_delay_s > 0) {
                std.time.sleep(self.action_delay_s * std.time.ns_per_s);
            }

            // now it is our turn, so we need to make a move

            // for the simple agent, we will just pick the first possible action following the order:
            // 1. hatch an egg
            // 2. defend against a steal
            // 3. steal an egg
            // 4. lay an egg
            // 5. exchange a random card

            // hatch an egg
            if (self.state.players[self.player_idx].canHatchEgg()) {
                try self.game.handle(self.player_idx, Action.HATCH_EGG);
                std.time.sleep(100 * std.time.ns_per_ms);
                continue;
            }

            // defend a steal
            if (self.state.players[self.player_idx].canDefendSteal() and
                self.state.last_event.player_idx != self.player_idx and
                self.state.last_event.action == Action.STEAL_EGG)
            {
                try self.game.handle(self.player_idx, Action.DEFEND_EGG);
                std.time.sleep(100 * std.time.ns_per_ms);
                continue;
            }

            // steal
            if (self.state.players[self.player_idx].canStealEgg(self.state.players[another_player_idx])) {
                try self.game.handle(self.player_idx, Action.STEAL_EGG);
                std.time.sleep(100 * std.time.ns_per_ms);
                continue;
            }

            // lay an egg
            if (self.state.players[self.player_idx].canLayEgg()) {
                try self.game.handle(self.player_idx, Action.LAY_EGG);
                std.time.sleep(100 * std.time.ns_per_ms);
                continue;
            }

            // exchange a card
            const timestamp = std.time.timestamp();
            var rnd = std.rand.DefaultPrng.init(@intCast(timestamp));
            const j = rnd.random().intRangeLessThan(usize, 0, 4);
            var exchange_action: Action = undefined;
            switch (j) {
                0 => exchange_action = Action.EXCHANGE_CARD_1,
                1 => exchange_action = Action.EXCHANGE_CARD_2,
                2 => exchange_action = Action.EXCHANGE_CARD_3,
                3 => exchange_action = Action.EXCHANGE_CARD_4,
                else => unreachable,
            }
            try self.game.handle(self.player_idx, exchange_action);
            std.time.sleep(100 * std.time.ns_per_ms);
        }
    }
};
