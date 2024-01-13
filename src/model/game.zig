const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Player = @import("./player.zig").Player;
const Action = @import("./action.zig").Action;
const Event = @import("./action.zig").Event;
const Card = @import("./card.zig").Card;

const Mutex = std.Thread.Mutex;

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
    var timestamp = std.time.timestamp();
    var rnd = std.rand.DefaultPrng.init(@intCast(timestamp));
    for (0..cards.len) |i| {
        var n = cards.len - 1 - i;
        if (n == 0) {
            break;
        }
        var j = rnd.random().intRangeLessThan(usize, 0, n);
        var tmp = cards[i];
        cards[i] = cards[j];
        cards[j] = tmp;
    }
}

/// Game struct keeps the state of the game and the interface to the
pub const Game = struct {
    allocator: Allocator,

    lock: Mutex = .{},

    state: State,
    cards: ArrayList(Card),

    pub fn init(allocator: Allocator, player1: []const u8, player2: []const u8) !Game {
        var card_array_list = ArrayList(Card).init(allocator);
        var cards = [_]Card{Card.FOX} ** 12 ++ [_]Card{Card.ROASTER} ** 30 ++ [_]Card{Card.HEN} ** 30 ++ [_]Card{Card.NEST} ** 22;
        for (0..10) |i| {
            _ = i;
            shuffleCards(cards[0..]);
        }

        try card_array_list.appendSlice(cards[0..]);

        var p1 = Player.init(player1, true);
        p1.is_active = true;
        var p2 = Player.init(player2, false);
        p2.is_active = false;

        p1.addCard(card_array_list.pop());
        p1.addCard(card_array_list.pop());
        p1.addCard(card_array_list.pop());
        p1.addCard(card_array_list.pop());

        p2.addCard(card_array_list.pop());
        p2.addCard(card_array_list.pop());
        p2.addCard(card_array_list.pop());
        p2.addCard(card_array_list.pop());

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
        };
    }

    pub fn deinit(self: *Game) void {
        self.cards.deinit();
    }

    pub fn reset(self: *Game) !void {
        self.lock.lock();
        defer self.lock.unlock();

        self.cards.deinit();

        var card_array_list = ArrayList(Card).init(self.allocator);
        var cards = [_]Card{Card.FOX} ** 12 ++ [_]Card{Card.ROASTER} ** 30 ++ [_]Card{Card.HEN} ** 30 ++ [_]Card{Card.NEST} ** 22;
        for (0..10) |i| {
            _ = i;
            shuffleCards(cards[0..]);
        }
        try card_array_list.appendSlice(cards[0..]);
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

        self.state.turn_idx = 0;
    }

    fn shuffle(self: *Game) void {
        self.lock.lock();
        defer self.lock.unlock();

        var timestamp = std.time.timestamp();
        var rnd = std.rand.DefaultPrng.init(@intCast(timestamp));
        for (0..self.cards.items.len) |i| {
            var n = self.cards.items.len - 1 - i;
            if (n == 0) {
                break;
            }
            var j = rnd.random().intRangeLessThan(usize, 0, n);
            var tmp = self.cards.items[i];
            self.cards.items[i] = self.cards.items[j];
            self.cards.items[j] = tmp;
        }
    }

    pub fn getVersion(self: *Game) usize {
        self.lock.lock();
        defer self.lock.unlock();

        return self.state.version;
    }

    pub fn getState(self: *Game) State {
        self.lock.lock();
        defer self.lock.unlock();

        return self.state.clone();
    }

    pub fn handle(self: *Game, player_idx: u8, action: Action) !void {
        self.lock.lock();
        defer self.lock.unlock();
        // if (player_idx != self.state.turn_idx and action != Action.RESET_GAME) {
        //     std.debug.print("Player {d} tried to play out of turn\n", .{player_idx});
        //     return;
        // }

        switch (action) {
            Action.RESET_GAME => {
                try self.reset();
                self.state.version += 1;
            },
            Action.EXCHANGE_CARD_1 => {
                if (self.cards.items.len == 0) {
                    return;
                }
                self.state.players[player_idx].exchangeCard(0, self.cards.pop());
            },
            Action.EXCHANGE_CARD_2 => {
                if (self.cards.items.len == 0) {
                    return;
                }
                self.state.players[player_idx].exchangeCard(1, self.cards.pop());
            },
            Action.EXCHANGE_CARD_3 => {
                if (self.cards.items.len == 0) {
                    return;
                }
                self.state.players[player_idx].exchangeCard(2, self.cards.pop());
            },
            Action.EXCHANGE_CARD_4 => {
                if (self.cards.items.len == 0) {
                    return;
                }
                self.state.players[player_idx].exchangeCard(3, self.cards.pop());
            },
            Action.LAY_EGG => {
                if (!self.state.players[player_idx].canLayEgg() or self.cards.items.len < 3) {
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
                self.state.players[player_idx].hatchEgg();
                self.state.players[player_idx].addCard(self.cards.pop());
                self.state.players[player_idx].addCard(self.cards.pop());
            },
            Action.STEAL_EGG => {
                var other_player = &self.state.players[(player_idx + 1) % 2];
                if (!self.state.players[player_idx].canStealEgg(other_player.*)) {
                    return;
                }
                self.state.players[player_idx].stealEgg(other_player);
                self.state.players[player_idx].addCard(self.cards.pop());
            },
            Action.DEFEND_EGG => {
                if (self.state.last_event.action != Action.STEAL_EGG or !self.state.players[player_idx].canDefendSteal()) {
                    return;
                }
                var other_player = &self.state.players[(player_idx + 1) % 2];
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
    }
};
