const std = @import("std");
const cli = @import("zig-cli");
const thread = std.Thread;

const Game = @import("./model/game.zig").Game;

const HumanAgent = @import("./agents/human.zig").HumanAgent;
const GptAgent = @import("./agents/gpt.zig").GptAgent;
const SimpleAgent = @import("./agents/simple.zig").SimpleAgent;

const RaylibUI = @import("./ui/raylib/main.zig");
const TerminalUI = @import("./ui/terminal/main.zig");

const AI_ACTION_DELAY = 0;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var config = struct {
    show_version: bool = false,
    headless: bool = false,
    auto_save: bool = false,
    replay: []const u8 = "",
}{};

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

var app = &cli.App{
    .command = cli.Command{
        .name = "pioupiou",
        .options = &.{ &show_version, &headless, &replay },
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
    var game = try Game.init(allocator, "Player 1", "Player AI", 2);
    defer game.deinit();

    // start agents
    var human_agent = HumanAgent.init(&game, 0);
    var human = try thread.spawn(.{}, HumanAgent.run, .{&human_agent});
    human.detach();

    // var simple_agent_1 = SimpleAgent.init(&game, 0, AI_ACTION_DELAY);
    // var simple_1 = try thread.spawn(.{}, SimpleAgent.run, .{&simple_agent_1});
    // simple_1.detach();

    // const gpt_agent = GptAgent.init(&game, 1);
    // _ = gpt_agent;
    // var gpt = try thread.spawn(.{}, GptAgent.run, .{&gpt_agent});
    // gpt.detach();

    var simple_agent = SimpleAgent.init(&game, 1, AI_ACTION_DELAY);
    var simple = try thread.spawn(.{}, SimpleAgent.run, .{&simple_agent});
    simple.detach();

    // now run the main loop of the UI
    if (config.headless) {
        try TerminalUI.run(&game);
    } else {
        try RaylibUI.run(&game);
    }
}

pub fn main() !void {
    return cli.run(app, allocator);
}
