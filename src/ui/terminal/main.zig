const std = @import("std");
const Game = @import("../../model/game.zig").Game;
const Config = @import("../../config.zig").Config;

pub fn run(game: *Game, config: *Config) !void {
    _ = config;
    _ = game;
    std.debug.print("Hello from the game!\n", .{});
    std.debug.print("Headless mode is not yet implemented!\n", .{});
}
