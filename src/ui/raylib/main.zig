const std = @import("std");
const Game = @import("../../model/game.zig").Game;
const Action = @import("../../model/action.zig").Action;
const Scene = @import("./render.zig").Scene;
const res = @import("./resources.zig");
const Textures = res.Textures;

const r = @cImport({
    @cInclude("raylib.h");
});

/// the main loop of the raylib based UI
pub fn run(game: *Game) !void {
    const allocator = std.heap.page_allocator;

    r.InitWindow(1280, 720, "Piou Piou");
    defer r.CloseWindow();

    r.SetTargetFPS(60);

    // load resources
    const textures = &Textures.LoadAllTextures();
    defer @constCast(textures).deinit();

    // init scene
    var scene = Scene.init(allocator, @constCast(textures));
    defer scene.deinit();

    var counter: usize = 0;

    var cache_version: usize = 0;
    var state = game.getState();
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
