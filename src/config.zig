pub const Config = struct {
    show_version: bool = false,
    headless: bool = false,
    auto_save: bool = false,
    replay: []const u8 = "",
    player1_name: []const u8 = "Player 1",
    player2_name: []const u8 = "Player 2",
    player1_type: []const u8 = "unspecified",
    player2_type: []const u8 = "unspecified",
    delay: usize = 0,
};
