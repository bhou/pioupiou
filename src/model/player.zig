const std = @import("std");
const ArrayList = std.ArrayList;
const Card = @import("./card.zig").Card;

pub const Player = struct {
    name: []const u8,
    cards: [4]Card,
    eggs: u8,
    chicken: u8,
    is_active: bool,
    show_cards: bool = true,

    pub fn init(name: []const u8, show_cards: bool) Player {
        return Player{
            .name = name,
            .cards = [_]Card{ Card.PLACEHOLDER, Card.PLACEHOLDER, Card.PLACEHOLDER, Card.PLACEHOLDER },
            .eggs = 0,
            .chicken = 0,
            .is_active = false,
            .show_cards = show_cards,
        };
    }

    pub fn reset(self: *Player) void {
        self.cards = [_]Card{ Card.PLACEHOLDER, Card.PLACEHOLDER, Card.PLACEHOLDER, Card.PLACEHOLDER };
        self.eggs = 0;
        self.chicken = 0;
        self.is_active = false;
    }

    pub fn clone(self: Player) Player {
        return Player{
            .name = self.name,
            .cards = [_]Card{ self.cards[0], self.cards[1], self.cards[2], self.cards[3] },
            .eggs = self.eggs,
            .chicken = self.chicken,
            .is_active = self.is_active,
            .show_cards = self.show_cards,
        };
    }

    pub fn exchangeCard(self: *Player, card_idx: u8, new_card: Card) void {
        if (card_idx >= 4) {
            return;
        }
        self.cards[card_idx] = new_card;
    }

    pub fn layEgg(self: *Player) void {
        if (!self.canLayEgg()) {
            return;
        }
        var change_roaster: bool = false;
        var change_hen: bool = false;
        var change_nest: bool = false;
        for (self.cards, 0..) |card, i| {
            switch (card) {
                Card.ROASTER => {
                    if (!change_roaster) {
                        change_roaster = true;
                        self.cards[i] = Card.PLACEHOLDER;
                    }
                },
                Card.HEN => {
                    if (!change_hen) {
                        change_hen = true;
                        self.cards[i] = Card.PLACEHOLDER;
                    }
                },
                Card.NEST => {
                    if (!change_nest) {
                        change_nest = true;
                        self.cards[i] = Card.PLACEHOLDER;
                    }
                },
                else => {},
            }
        }
        self.eggs += 1;
    }

    pub fn getCardCount(self: Player) u8 {
        var count: u8 = 0;
        for (self.cards) |card| {
            if (card != Card.PLACEHOLDER) {
                count += 1;
            }
        }
        return count;
    }

    pub fn addCard(self: *Player, card: Card) void {
        if (self.getCardCount() == 4) {
            return;
        }
        for (self.cards, 0..) |c, i| {
            if (c == Card.PLACEHOLDER) {
                self.cards[i] = card;
                return;
            }
        }
    }

    pub fn hatchEgg(self: *Player) void {
        if (self.eggs == 0) {
            return;
        }
        var hens: u8 = 0;
        for (self.cards, 0..) |card, i| {
            switch (card) {
                Card.HEN => {
                    if (hens < 2) {
                        hens += 1;
                        self.cards[i] = Card.PLACEHOLDER;
                    }
                },
                else => {},
            }
        }
        self.eggs -= 1;
        self.chicken += 1;
    }

    pub fn stealEgg(self: *Player, other: *Player) void {
        if (other.eggs <= 0) {
            return;
        }
        var fox: u8 = 0;
        for (self.cards, 0..) |card, i| {
            switch (card) {
                Card.FOX => {
                    if (fox < 1) {
                        fox += 1;
                        self.cards[i] = Card.PLACEHOLDER;
                    }
                },
                else => {},
            }
        }
        other.eggs -= 1;
        self.eggs += 1;
    }

    pub fn defendSteal(self: *Player, other: *Player) void {
        if (!self.canDefendSteal()) {
            return;
        }
        var roaster: u8 = 0;
        for (self.cards, 0..) |card, i| {
            switch (card) {
                Card.ROASTER => {
                    if (roaster < 2) {
                        roaster += 1;
                        self.cards[i] = Card.PLACEHOLDER;
                    }
                },
                else => {},
            }
        }
        self.eggs += 1;
        other.eggs -= 1;
    }

    pub fn canLayEgg(self: Player) bool {
        var hasRoaster: bool = false;
        var hasHen: bool = false;
        var hasNest: bool = false;
        for (self.cards) |card| {
            switch (card) {
                Card.ROASTER => hasRoaster = true,
                Card.HEN => hasHen = true,
                Card.NEST => hasNest = true,
                else => {},
            }
        }
        return hasRoaster and hasHen and hasNest;
    }

    pub fn canHatchEgg(self: Player) bool {
        var hens: u8 = 0;
        for (self.cards) |card| {
            if (card == Card.HEN) {
                hens += 1;
            }
        }
        return self.eggs > 0 and hens >= 2;
    }

    pub fn canStealEgg(self: Player, other: Player) bool {
        var hasFox: bool = false;
        for (self.cards) |card| {
            if (card == Card.FOX) {
                hasFox = true;
                break;
            }
        }
        return hasFox and other.eggs > 0;
    }

    pub fn canDefendSteal(self: Player) bool {
        var roaster: u8 = 0;
        for (self.cards) |card| {
            if (card == Card.ROASTER) {
                roaster += 1;
            }
        }
        return roaster >= 2;
    }
};
