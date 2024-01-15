pub const Action = enum(u8) {
    NONE,
    RESET_GAME,
    WIN,
    DRAW,

    EXCHANGE_CARD_1,
    EXCHANGE_CARD_2,
    EXCHANGE_CARD_3,
    EXCHANGE_CARD_4,
    LAY_EGG,
    HATCH_EGG,
    STEAL_EGG,
    DEFEND_EGG,
};

pub const Event = struct {
    player_idx: u8,
    action: Action,
};
