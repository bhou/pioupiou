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
const Textures = res.Textures;
const r = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    r.InitWindow(1280, 720, "Piou Piou");
    defer r.CloseWindow();

    r.SetTargetFPS(60);

    // load resources
    const textures = &Textures.LoadAllTextures();
    defer @constCast(textures).deinit();

    // init game state
    var game = try Game.init(allocator, "Player 1", "Player AI");
    defer game.deinit();

    // init scene
    var scene = Scene.init(allocator, @constCast(textures));
    defer scene.deinit();

    // state cache
    var cache_version: usize = 0;
    var state = game.getState();

    // start agents
    var human_agent = HumanAgent.init(&game);
    var human = try thread.spawn(.{}, HumanAgent.run, .{&human_agent});
    human.detach();

    var gpt_agent = GptAgent.init(&game, 1);
    var gpt = try thread.spawn(.{}, GptAgent.run, .{&gpt_agent});
    gpt.detach();

    var counter: usize = 0;

    // main loop
    while (!r.WindowShouldClose()) {

        // check inputs
        if (r.IsKeyPressed(r.KEY_Q)) {
            break;
        }
        if (r.IsKeyPressed(r.KEY_R)) {
            std.debug.print("reset game {d}\n", .{counter});
            counter += 1;
            try game.handle(state.turn_idx, Action.RESET_GAME);
        }

        // update state
        const new_version = game.getVersion();
        if (new_version != cache_version) {
            cache_version = new_version;
            state = game.getState();
        }

        // draw
        r.BeginDrawing();
        {
            r.ClearBackground(r.RAYWHITE);
            r.DrawFPS(10, 10);
            try scene.render(&state);
        }
        r.EndDrawing();
    }
}
