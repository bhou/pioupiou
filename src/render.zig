const std = @import("std");
const Allocator = std.mem.Allocator;
const State = @import("./model/game.zig").State;
const Player = @import("./model/player.zig").Player;
const Card = @import("./model/card.zig").Card;
const Action = @import("./model/action.zig").Action;
const res = @import("./resources.zig");
const r = @cImport({
    @cInclude("raylib.h");
});

fn getEventString(allocator: Allocator, player_name: []const u8, action: Action) ![]const u8 {
    switch (action) {
        Action.EXCHANGE_CARD_1 => {
            return try std.fmt.allocPrint(allocator, "{s} exchanged a card", .{player_name});
        },
        Action.EXCHANGE_CARD_2 => {
            return try std.fmt.allocPrint(allocator, "{s} exchanged a card", .{player_name});
        },
        Action.EXCHANGE_CARD_3 => {
            return try std.fmt.allocPrint(allocator, "{s} exchanged a card", .{player_name});
        },
        Action.EXCHANGE_CARD_4 => {
            return try std.fmt.allocPrint(allocator, "{s} exchanged a card", .{player_name});
        },
        Action.STEAL_EGG => {
            return try std.fmt.allocPrint(allocator, "{s} stole an egg", .{player_name});
        },
        Action.DEFEND_EGG => {
            return try std.fmt.allocPrint(allocator, "{s} defend the steal using 2 ROASTERs", .{player_name});
        },
        Action.LAY_EGG => {
            return try std.fmt.allocPrint(allocator, "{s} laid an egg", .{player_name});
        },
        Action.HATCH_EGG => {
            return try std.fmt.allocPrint(allocator, "{s} hatched an egg", .{player_name});
        },
        Action.WIN => {
            return try std.fmt.allocPrint(allocator, "{s} won the game", .{player_name});
        },
        else => {
            return try std.fmt.allocPrint(allocator, "{s}'s turn", .{player_name});
        },
    }
}

pub const Scene = struct {
    allocator: Allocator,
    textures: *res.Textures,

    const v_space: usize = 48;
    const padding: usize = 32;
    const panel_height: usize = 300;

    pub fn init(allocator: Allocator, textures: *res.Textures) Scene {
        return Scene{
            .allocator = allocator,
            .textures = textures,
        };
    }

    pub fn deinit(self: *Scene) void {
        _ = self;
    }

    pub fn render(self: Scene, state: *State) !void {
        try self.renderPlayer(&state.players[0], 150, 100);
        try self.renderPlayer(&state.players[1], 700, 100);

        // draw last event
        const event_str = try getEventString(self.allocator, state.players[state.last_event.player_idx].name, state.last_event.action);
        defer self.allocator.free(event_str);
        r.DrawText(event_str.ptr, 150, 550, 20, r.BLACK);
    }

    fn renderPlayer(self: Scene, player: *Player, x: usize, y: usize) !void {
        // draw background
        // first shadow
        if (player.is_active) {
            r.DrawRectangleRounded(.{
                .x = @floatFromInt(x + 5),
                .y = @floatFromInt(y + 5),
                .width = 440,
                .height = panel_height,
            }, 0.1, 0, r.ORANGE);
        }
        r.DrawRectangleRounded(.{
            .x = @floatFromInt(x),
            .y = @floatFromInt(y),
            .width = 440,
            .height = panel_height,
        }, 0.1, 0, r.WHITE);

        const inner_x = x + padding;
        const inner_y = y + padding;

        // draw name
        r.DrawText(player.name.ptr, @intCast(inner_x), @intCast(inner_y), @intCast(20), r.BLACK);
        // draw eggs and chicken
        r.DrawTextureEx(self.textures.egg, .{
            .x = @floatFromInt(inner_x + 100),
            .y = @floatFromInt(inner_y - 12),
        }, 0, 0.05, r.WHITE);
        const egg_num_str = try std.fmt.allocPrint(self.allocator, "x {d}", .{player.eggs});
        defer self.allocator.free(egg_num_str);
        r.DrawText(egg_num_str.ptr, @intCast(inner_x + 140), @intCast(inner_y), @intCast(20), r.BLACK);

        r.DrawTextureEx(self.textures.chick, .{
            .x = @floatFromInt(inner_x + 200),
            .y = @floatFromInt(inner_y - 12),
        }, 0, 0.05, r.WHITE);
        const chicken_num_str = try std.fmt.allocPrint(self.allocator, "x {d}", .{player.chicken});
        defer self.allocator.free(chicken_num_str);
        r.DrawText(chicken_num_str.ptr, @intCast(inner_x + 245), @intCast(inner_y), @intCast(20), r.BLACK);

        // draw cards
        for (player.cards, 0..) |card, i| {
            r.DrawRectangleRounded(.{
                .x = @floatFromInt(inner_x + i * 100),
                .y = @floatFromInt(inner_y + v_space),
                .width = 80,
                .height = 80,
            }, 0.5, 0, r.GOLD);
            r.DrawTextureEx(self.textures.exchange, .{
                .x = @floatFromInt(inner_x + i * 100 + 30),
                .y = @floatFromInt(inner_y + v_space + 90),
            }, 0, 0.2, r.RED);
            // if (player.show_cards) {
            if (true) {
                switch (card) {
                    Card.ROASTER => {
                        r.DrawTextureEx(self.textures.roaster, .{
                            .x = @floatFromInt(inner_x + i * 100),
                            .y = @floatFromInt(inner_y + v_space),
                        }, 0, 0.1, r.WHITE);
                    },
                    Card.HEN => {
                        r.DrawTextureEx(self.textures.hen, .{
                            .x = @floatFromInt(inner_x + i * 100),
                            .y = @floatFromInt(inner_y + v_space),
                        }, 0, 0.1, r.WHITE);
                    },
                    Card.NEST => {
                        r.DrawTextureEx(self.textures.nest, .{
                            .x = @floatFromInt(inner_x + i * 100),
                            .y = @floatFromInt(inner_y + v_space),
                        }, 0, 0.1, r.WHITE);
                    },
                    Card.FOX => {
                        r.DrawTextureEx(self.textures.fox, .{
                            .x = @floatFromInt(inner_x + i * 100),
                            .y = @floatFromInt(inner_y + v_space),
                        }, 0, 0.1, r.WHITE);
                    },
                    Card.PLACEHOLDER => {},
                    else => {},
                }
            } else {
                r.DrawTextureEx(self.textures.unknown, .{
                    .x = @floatFromInt(inner_x + i * 100),
                    .y = @floatFromInt(inner_y + v_space),
                }, 0, 0.1, r.WHITE);
            }
        }

        // draw seperate line
        r.DrawLine(@intCast(inner_x), @intCast(inner_y + v_space + 130), @intCast(inner_x + 380), @intCast(inner_y + v_space + 130), r.GOLD);
    }
};
