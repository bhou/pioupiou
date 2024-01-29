const std = @import("std");

const RaylibHumanAgent = @import("./raylib_human.zig").HumanAgent;
const GptAgent = @import("./gpt.zig").GptAgent;
const SimpleAgent = @import("./simple.zig").SimpleAgent;

pub const Agent = union(enum) {
    raylib_human: RaylibHumanAgent,
    gpt: GptAgent,
    simple: SimpleAgent,

    pub fn run(self: *Agent) !void {
        switch (self.*) {
            inline else => |*agent| try agent.run(),
        }
    }
};
