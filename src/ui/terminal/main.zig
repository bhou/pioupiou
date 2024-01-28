const std = @import("std");
const Game = @import("../../model/game.zig").Game;

pub fn run(game: *Game) !void {
    _ = game;
    std.debug.print("Hello from the game!\n", .{});
    std.debug.print("Headless mode is not yet implemented!\n", .{});
}
