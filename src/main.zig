const std = @import("std");
const thread = std.Thread;
const res = @import("./resources.zig");
const Game = @import("./model/game.zig").Game;
const State = @import("./model/game.zig").State;
const Player = @import("./model/player.zig").Player;
const Scene = @import("./render.zig").Scene;
const Action = @import("./model/action.zig").Action;
const HumanAgent = @import("./agents/human.zig").HumanAgent;
const GptAgent = @import("./agents/gpt.zig").GptAgent;
const SimpleAgent = @import("./agents/simple.zig").SimpleAgent;
const Textures = res.Textures;
const r = @cImport({
    @cInclude("raylib.h");
});

const AI_ACTION_DELAY = 0;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    r.InitWindow(1280, 720, "Piou Piou");
    defer r.CloseWindow();

    r.SetTargetFPS(60);

    // load resources
    const textures = &Textures.LoadAllTextures();
    defer @constCast(textures).deinit();

    // init game state
    var game = try Game.init(allocator, "Player 1", "Player AI", 2);
    defer game.deinit();

    // init scene
    var scene = Scene.init(allocator, @constCast(textures));
    defer scene.deinit();

    // state cache
    var cache_version: usize = 0;
    var state = game.getState();

    // start agents
    // var human_agent = HumanAgent.init(&game, 0);
    // var human = try thread.spawn(.{}, HumanAgent.run, .{&human_agent});
    // human.detach();
    var simple_agent_1 = SimpleAgent.init(&game, 0, AI_ACTION_DELAY);
    var simple_1 = try thread.spawn(.{}, SimpleAgent.run, .{&simple_agent_1});
    simple_1.detach();

    // var gpt_agent = GptAgent.init(&game, 1);
    // var gpt = try thread.spawn(.{}, GptAgent.run, .{&gpt_agent});
    // gpt.detach();

    var simple_agent = SimpleAgent.init(&game, 1, AI_ACTION_DELAY);
    var simple = try thread.spawn(.{}, SimpleAgent.run, .{&simple_agent});
    simple.detach();

    var counter: usize = 0;

    // main loop
    while (!r.WindowShouldClose()) {

        // check inputs
        if (r.IsKeyPressed(r.KEY_Q)) {
            break;
        }
        if (r.IsKeyPressed(r.KEY_R)) {
            counter += 1;
            try game.handle(state.turn_idx, Action.RESET_GAME);
        }

        // update state
        const new_version = game.getVersion();
        if (new_version != cache_version) {
            cache_version = new_version;
            state = game.getState();

            if (state.last_event.action == Action.WIN) {
                try game.handle(state.last_event.player_idx, Action.RESET_GAME);
                std.debug.print("player {d} wins\n", .{state.last_event.player_idx});
            } else if (state.last_event.action == Action.DRAW) {
                try game.handle(state.last_event.player_idx, Action.RESET_GAME);
                std.debug.print("draw\n", .{});
            }
        }

        // draw
        r.BeginDrawing();
        {
            r.ClearBackground(r.RAYWHITE);
            r.DrawFPS(10, 10);
            try scene.render(&state, game.getCardsCount());
        }
        r.EndDrawing();
    }
}
