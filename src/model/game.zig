const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Player = @import("./player.zig").Player;
const Action = @import("./action.zig").Action;
const Event = @import("./action.zig").Event;
const Card = @import("./card.zig").Card;

const Mutex = std.Thread.Mutex;

var wd_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
var log_path_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;

pub const State = struct {
    version: usize = 0,
    players: [2]Player,
    turn_idx: u8 = 0,

    last_event: Event,

    pub fn clone(self: State) State {
        return State{
            .version = self.version,
            .players = [2]Player{ self.players[0].clone(), self.players[1].clone() },
            .turn_idx = self.turn_idx,
            .last_event = Event{
                .player_idx = self.last_event.player_idx,
                .action = self.last_event.action,
            },
        };
    }
};

const GameError = error{
    InvalidTurn,
    InvalidAction,
};

fn shuffleCards(cards: []Card) void {
    const timestamp = std.time.timestamp();
    var rnd = std.rand.DefaultPrng.init(@intCast(timestamp));

    // repeat random times from 10 to 20
    const repeat = rnd.random().intRangeLessThan(usize, 10, 20);

    for (0..repeat) |r| {
        _ = r;
        for (0..cards.len) |i| {
            const n = cards.len - 1 - i;
            if (n == 0) {
                break;
            }
            const j = rnd.random().intRangeLessThan(usize, 0, n);
            const tmp = cards[i];
            cards[i] = cards[j];
            cards[j] = tmp;
        }
    }
}

/// Game struct keeps the state of the game and the interface to the
pub const Game = struct {
    allocator: Allocator,

    lock: Mutex = .{},

    state: State,
    cards: ArrayList(Card),
    deck_multiplier: usize = 1,

    game_root: []const u8,
    game_seed: i64 = 0,
    game_id: usize = 0,
    game_log_path: []const u8 = undefined,

    auto_save: bool = false,

    const CARD_MULTIPLIER: usize = 1;
    const FOX_COUNT: usize = 6 * CARD_MULTIPLIER;
    const ROOSTER_COUNT: usize = 15 * CARD_MULTIPLIER;
    const HEN_COUNT: usize = 15 * CARD_MULTIPLIER;
    const NEST_COUNT: usize = 11 * CARD_MULTIPLIER;

    pub fn init(allocator: Allocator, player1: []const u8, player2: []const u8, deck_multiplier: usize, auto_save: bool) !Game {
        var card_array_list = ArrayList(Card).init(allocator);
        var cards = [_]Card{Card.FOX} ** FOX_COUNT ++ [_]Card{Card.ROOSTER} ** ROOSTER_COUNT ++ [_]Card{Card.HEN} ** HEN_COUNT ++ [_]Card{Card.NEST} ** NEST_COUNT;
        for (0..deck_multiplier) |i| {
            _ = i;
            try card_array_list.appendSlice(cards[0..]);
        }

        shuffleCards(card_array_list.items);

        var p1 = Player.init(player1, true);
        p1.is_active = true;
        var p2 = Player.init(player2, true);
        p2.is_active = false;

        p1.addCard(card_array_list.pop());
        p1.addCard(card_array_list.pop());
        p1.addCard(card_array_list.pop());
        p1.addCard(card_array_list.pop());

        p2.addCard(card_array_list.pop());
        p2.addCard(card_array_list.pop());
        p2.addCard(card_array_list.pop());
        p2.addCard(card_array_list.pop());

        const game_root = try std.posix.getcwd(&wd_buffer);

        return Game{
            .allocator = allocator,
            .state = State{
                .version = 0,
                .turn_idx = 0,
                .players = [2]Player{ p1, p2 },
                .last_event = Event{
                    .player_idx = 0,
                    .action = Action.NONE,
                },
            },
            .cards = card_array_list,
            .deck_multiplier = deck_multiplier,
            .game_root = game_root,
            .game_seed = std.time.timestamp(),
            .auto_save = auto_save,
        };
    }

    pub fn deinit(self: *Game) void {
        self.cards.deinit();
    }

    fn reset(self: *Game) !void {
        self.cards.deinit();

        var card_array_list = ArrayList(Card).init(self.allocator);
        for (0..self.deck_multiplier) |i| {
            _ = i;
            var cards = [_]Card{Card.FOX} ** FOX_COUNT ++ [_]Card{Card.ROOSTER} ** ROOSTER_COUNT ++ [_]Card{Card.HEN} ** HEN_COUNT ++ [_]Card{Card.NEST} ** NEST_COUNT;
            try card_array_list.appendSlice(cards[0..]);
        }
        shuffleCards(card_array_list.items);
        self.cards = card_array_list;

        self.state.players[0].reset();
        self.state.players[0].exchangeCard(0, self.cards.pop());
        self.state.players[0].exchangeCard(1, self.cards.pop());
        self.state.players[0].exchangeCard(2, self.cards.pop());
        self.state.players[0].exchangeCard(3, self.cards.pop());

        self.state.players[1].reset();
        self.state.players[1].exchangeCard(0, self.cards.pop());
        self.state.players[1].exchangeCard(1, self.cards.pop());
        self.state.players[1].exchangeCard(2, self.cards.pop());
        self.state.players[1].exchangeCard(3, self.cards.pop());

        self.state.last_event = Event{
            .player_idx = 0,
            .action = Action.NONE,
        };

        self.state.version = 0;

        self.state.turn_idx = 0;

        self.game_id += 1;

        try self.updateLogPath();
    }

    fn updateLogPath(self: *Game) !void {
        if (self.auto_save == false) {
            return;
        }

        const log_sub_dir = try std.fmt.allocPrint(self.allocator, "./logs/{d}", .{self.game_seed});
        defer self.allocator.free(log_sub_dir);

        const log_dir = try std.fmt.allocPrint(self.allocator, "{s}/logs/{d}", .{ self.game_root, self.game_seed });
        defer self.allocator.free(log_dir);

        // first open the log root directory
        var root_dir = try std.fs.openDirAbsolute(self.game_root, .{});
        defer root_dir.close();

        try root_dir.makePath(log_sub_dir);

        const log_path = try std.fmt.allocPrint(self.allocator, "{s}/{d}.log", .{ log_dir, self.game_id });
        defer self.allocator.free(log_path);

        std.mem.copyForwards(u8, log_path_buffer[0..], log_path[0..]);
        self.game_log_path = log_path_buffer[0..log_path.len];

        var file = std.fs.createFileAbsolute(log_path, .{ .exclusive = true }) catch |e| {
            switch (e) {
                error.PathAlreadyExists => {
                    std.debug.print("log path already exists", .{});
                    return;
                },
                else => {
                    return e;
                },
            }
        };
        defer file.close();
        // return error.UnexpectedError;
    }

    pub fn getVersion(self: *Game) usize {
        self.lock.lock();
        defer self.lock.unlock();

        return self.state.version;
    }

    pub fn getCardsCount(self: *Game) usize {
        self.lock.lock();
        defer self.lock.unlock();

        return self.cards.items.len;
    }

    pub fn getState(self: *Game) State {
        self.lock.lock();
        defer self.lock.unlock();

        return self.state.clone();
    }

    pub fn handle(self: *Game, player_idx: u8, action: Action) !void {
        self.lock.lock();
        defer self.lock.unlock();

        try self.updateLogPath();

        // if (player_idx != self.state.turn_idx and action != Action.RESET_GAME) {
        //     std.debug.print("Player {d} tried to play out of turn\n", .{player_idx});
        //     return;
        // }

        switch (action) {
            Action.RESET_GAME => {
                try self.reset();
            },
            Action.EXCHANGE_CARD_1 => {
                if (self.cards.items.len == 0) {
                    self.draw(player_idx);
                    return;
                }
                self.state.players[player_idx].exchangeCard(0, self.cards.pop());
            },
            Action.EXCHANGE_CARD_2 => {
                if (self.cards.items.len == 0) {
                    self.draw(player_idx);
                    return;
                }
                self.state.players[player_idx].exchangeCard(1, self.cards.pop());
            },
            Action.EXCHANGE_CARD_3 => {
                if (self.cards.items.len == 0) {
                    self.draw(player_idx);
                    return;
                }
                self.state.players[player_idx].exchangeCard(2, self.cards.pop());
            },
            Action.EXCHANGE_CARD_4 => {
                if (self.cards.items.len == 0) {
                    self.draw(player_idx);
                    return;
                }
                self.state.players[player_idx].exchangeCard(3, self.cards.pop());
            },
            Action.LAY_EGG => {
                if (!self.state.players[player_idx].canLayEgg() or self.cards.items.len < 3) {
                    if (self.cards.items.len < 3) {
                        self.draw(player_idx);
                    }
                    return;
                }
                self.state.players[player_idx].layEgg();
                self.state.players[player_idx].addCard(self.cards.pop());
                self.state.players[player_idx].addCard(self.cards.pop());
                self.state.players[player_idx].addCard(self.cards.pop());
            },
            Action.HATCH_EGG => {
                if (!self.state.players[player_idx].canHatchEgg()) {
                    return;
                }
                if (self.cards.items.len < 2) {
                    self.draw(player_idx);
                    return;
                }
                self.state.players[player_idx].hatchEgg();
                self.state.players[player_idx].addCard(self.cards.pop());
                self.state.players[player_idx].addCard(self.cards.pop());
            },
            Action.STEAL_EGG => {
                const other_player = &self.state.players[(player_idx + 1) % 2];
                if (!self.state.players[player_idx].canStealEgg(other_player.*)) {
                    return;
                }
                if (self.cards.items.len < 1) {
                    self.draw(player_idx);
                    return;
                }
                self.state.players[player_idx].stealEgg(other_player);
                self.state.players[player_idx].addCard(self.cards.pop());
            },
            Action.DEFEND_EGG => {
                if (self.state.last_event.action != Action.STEAL_EGG or !self.state.players[player_idx].canDefendSteal()) {
                    return;
                }
                if (self.cards.items.len < 2) {
                    self.draw(player_idx);
                    return;
                }
                const other_player = &self.state.players[(player_idx + 1) % 2];
                self.state.players[player_idx].defendSteal(other_player);
                self.state.players[player_idx].addCard(self.cards.pop());
                self.state.players[player_idx].addCard(self.cards.pop());
            },
            else => {
                std.debug.print("Player {d} tried to perform invalid action {}\n", .{ player_idx, action });
                return error.InvalidAction;
            },
        }

        // check win condition
        if (self.state.players[player_idx].chicken == 3) {
            self.state.last_event = Event{
                .player_idx = player_idx,
                .action = Action.WIN,
            };
            self.state.version += 1;
            try self.persistState();
            return;
        }

        // check draw condition
        if (self.cards.items.len == 0) {
            self.draw(player_idx);
            return;
        }

        self.state.players[self.state.turn_idx].is_active = false;
        self.state.turn_idx = (self.state.turn_idx + 1) % 2;
        self.state.players[self.state.turn_idx].is_active = true;

        self.state.last_event = Event{
            .player_idx = player_idx,
            .action = action,
        };
        // update the version
        self.state.version += 1;
        try self.persistState();
    }

    fn draw(self: *Game, player_idx: u8) void {
        self.state.last_event = Event{
            .player_idx = player_idx,
            .action = Action.DRAW,
        };
        self.state.version += 1;
    }

    fn persistState(self: Game) !void {
        if (self.auto_save == false) {
            return;
        }
        var out = ArrayList(u8).init(self.allocator);
        defer out.deinit();

        std.debug.print("persisting state to {s}\n", .{self.game_log_path});
        var f = try std.fs.openFileAbsolute(self.game_log_path, .{ .mode = std.fs.File.OpenMode.read_write });
        defer f.close();

        const stat = try f.stat();
        try f.seekTo(stat.size);

        std.json.stringify(self.state, .{}, f.writer()) catch |err| {
            std.debug.print("Error: {}\n", .{err});
            return;
        };
        _ = try f.write("\n");
    }
};

test "game init and update log path should not leak memory" {
    // to test if it leaks memory with error, modify the code to return an error from updateLogPath
    var game = try Game.init(std.testing.allocator, "player1", "player2", 2, true);

    game.updateLogPath() catch |err| {
        std.debug.print("Error: {}\n", .{err});
    };

    game.reset() catch |err| {
        std.debug.print("Error: {}\n", .{err});
    };

    defer game.deinit();
}
