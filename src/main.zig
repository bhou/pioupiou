const std = @import("std");
const res = @import("./resources.zig");
const Game = @import("./model/game.zig").Game;
const State = @import("./model/game.zig").State;
const Player = @import("./model/player.zig").Player;
const Scene = @import("./render.zig").Scene;
const Action = @import("./model/action.zig").Action;
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
    var game = try Game.init(allocator, "Player 1", "Player 2");
    defer game.deinit();

    // init scene
    var scene = Scene.init(allocator, @constCast(textures));
    defer scene.deinit();

    // state cache
    var cache_version: usize = 0;
    var state = game.getState();

    // main loop
    while (!r.WindowShouldClose()) {

        // check inputs
        if (r.IsKeyPressed(r.KEY_Q)) {
            break;
        }
        if (r.IsKeyPressed(r.KEY_R)) {
            try game.handle(state.turn_idx, Action.RESET_GAME);
        }
        if (r.IsKeyPressed(r.KEY_ONE)) {
            try game.handle(state.turn_idx, Action.EXCHANGE_CARD_1);
        }
        if (r.IsKeyPressed(r.KEY_TWO)) {
            try game.handle(state.turn_idx, Action.EXCHANGE_CARD_2);
        }
        if (r.IsKeyPressed(r.KEY_THREE)) {
            try game.handle(state.turn_idx, Action.EXCHANGE_CARD_3);
        }
        if (r.IsKeyPressed(r.KEY_FOUR)) {
            try game.handle(state.turn_idx, Action.EXCHANGE_CARD_4);
        }
        if (r.IsKeyPressed(r.KEY_L)) {
            try game.handle(state.turn_idx, Action.LAY_EGG);
        }
        if (r.IsKeyPressed(r.KEY_H)) {
            try game.handle(state.turn_idx, Action.HATCH_EGG);
        }
        if (r.IsKeyPressed(r.KEY_S)) {
            try game.handle(state.turn_idx, Action.STEAL_EGG);
        }
        if (r.IsKeyPressed(r.KEY_D)) {
            try game.handle(state.turn_idx, Action.DEFEND_EGG);
        }

        // update state
        var new_version = game.getVersion();
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
