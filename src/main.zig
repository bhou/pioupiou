const std = @import("std");
const cli = @import("zig-cli");
const thread = std.Thread;

const Game = @import("./model/game.zig").Game;

const RaylibHumanAgent = @import("./agents/raylib_human.zig").HumanAgent;
const GptAgent = @import("./agents/gpt.zig").GptAgent;
const SimpleAgent = @import("./agents/simple.zig").SimpleAgent;
const Agent = @import("./agents/agent.zig").Agent;

const RaylibUI = @import("./ui/raylib/main.zig");
const TerminalUI = @import("./ui/terminal/main.zig");

const AI_ACTION_DELAY = 0;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Config = @import("./config.zig").Config;

var config = Config{};

// options
var show_version = cli.Option{
    .short_alias = 'v',
    .long_name = "version",
    .help = "Display version",
    .value_ref = cli.mkRef(&config.show_version),
};

var headless = cli.Option{
    .short_alias = 'l',
    .long_name = "headless",
    .help = "Run in terminal mode",
    .value_ref = cli.mkRef(&config.headless),
};

var replay = cli.Option{
    .short_alias = 'r',
    .long_name = "replay",
    .help = "Replay a game from a file",
    .value_ref = cli.mkRef(&config.replay),
};

var auto_save = cli.Option{
    .short_alias = 's',
    .long_name = "auto-save",
    .help = "Save the game automatically",
    .value_ref = cli.mkRef(&config.auto_save),
};

var player1_type = cli.Option{
    .long_name = "p1",
    .help = "Player 1 type: one of human, simple, gpt. Default: unspecified",
    .value_ref = cli.mkRef(&config.player1_type),
};

var player2_type = cli.Option{
    .long_name = "p2",
    .help = "Player 2 type: one of human, simple, gpt. Default: unspecified",
    .value_ref = cli.mkRef(&config.player2_type),
};

var player1_name = cli.Option{
    .long_name = "name1",
    .help = "Player 1 name. Default: Player 1",
    .value_ref = cli.mkRef(&config.player1_name),
};

var player2_name = cli.Option{
    .long_name = "name2",
    .help = "Player 2 name. Default: Player 2",
    .value_ref = cli.mkRef(&config.player2_name),
};

var delay = cli.Option{
    .long_name = "delay",
    .help = "Delay between AI actions in seconds. Default: 0",
    .value_ref = cli.mkRef(&config.delay),
};

var app = &cli.App{
    .command = cli.Command{
        .name = "pioupiou",
        .options = &.{
            &show_version,
            &headless,
            &replay,
            &player1_name,
            &player2_name,
            &player1_type,
            &player2_type,
            &delay,
        },
        .target = cli.CommandTarget{
            .action = cli.CommandAction{
                .exec = run,
            },
        },
    },
    .version = "0.1.0",
};

fn run() !void {
    if (config.show_version) {
        std.debug.print("pioupiou 0.1.0\n", .{});
        return;
    }
    if (std.mem.eql(u8, config.replay, "")) {
        std.debug.print("no replay\n", .{});
    } else {
        std.debug.print("replay {s}\n", .{config.replay});
    }

    // init game state
    var game = try Game.init(allocator, config.player1_name, config.player2_name, 2);
    defer game.deinit();

    // now run the main loop of the UI
    if (config.headless) {
        try TerminalUI.run(&game, &config);
    } else {
        try RaylibUI.run(&game, &config);
    }
}

pub fn main() !void {
    return cli.run(app, allocator);
}
