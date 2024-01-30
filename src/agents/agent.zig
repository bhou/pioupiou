const std = @import("std");

const RaylibHumanAgent = @import("./raylib_human.zig").HumanAgent;
const GptAgent = @import("./gpt.zig").GptAgent;
const SimpleAgent = @import("./simple.zig").SimpleAgent;
const Game = @import("../model/game.zig").Game;
const Config = @import("../config.zig").Config;

pub const Agent = union(enum) {
    raylib_human: RaylibHumanAgent,
    gpt: GptAgent,
    simple: SimpleAgent,

    pub fn run(self: *Agent) !void {
        switch (self.*) {
            inline else => |*agent| try agent.run(),
        }
    }

    pub fn getAgentByType(config: *Config, player_type: []u8, game: *Game, player_idx: u8) !Agent {
        if (std.mem.eql(u8, player_type, "human")) {
            if (config.headless) {
                // start human agent for terminal
            } else {
                // start human agent for raylib
                std.debug.print("starting raylib human agent for player {d}\n", .{player_idx + 1});
                return Agent{ .raylib_human = RaylibHumanAgent.init(game, player_idx) };
            }
        }
        if (std.mem.eql(u8, player_type, "simple")) {
            std.debug.print("starting simple agent for player {d}\n", .{player_idx + 1});
            return Agent{ .simple = SimpleAgent.init(game, player_idx, config.delay) };
        }
        if (std.mem.eql(u8, player_type, "gpt")) {
            std.debug.print("starting gpt agent for player {d}\n", .{1});
            return Agent{ .gpt = GptAgent.init(game, player_idx) };
        }

        return error.UnknownPlayerType;
    }
};
