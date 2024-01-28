const std = @import("std");
const thread = std.Thread;

const Game = @import("./model/game.zig").Game;

const HumanAgent = @import("./agents/human.zig").HumanAgent;
const GptAgent = @import("./agents/gpt.zig").GptAgent;
const SimpleAgent = @import("./agents/simple.zig").SimpleAgent;

const RaylibUI = @import("./ui/raylib/main.zig");

const AI_ACTION_DELAY = 0;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // init game state
    var game = try Game.init(allocator, "Player 1", "Player AI", 2);
    defer game.deinit();

    // start agents
    // var human_agent = HumanAgent.init(&game, 0);
    // var human = try thread.spawn(.{}, HumanAgent.run, .{&human_agent});
    // human.detach();
    var simple_agent_1 = SimpleAgent.init(&game, 0, AI_ACTION_DELAY);
    var simple_1 = try thread.spawn(.{}, SimpleAgent.run, .{&simple_agent_1});
    simple_1.detach();

    const gpt_agent = GptAgent.init(&game, 1);
    _ = gpt_agent;
    // var gpt = try thread.spawn(.{}, GptAgent.run, .{&gpt_agent});
    // gpt.detach();

    var simple_agent = SimpleAgent.init(&game, 1, AI_ACTION_DELAY);
    var simple = try thread.spawn(.{}, SimpleAgent.run, .{&simple_agent});
    simple.detach();

    // now run the main loop of the UI
    try RaylibUI.run(&game);
}
