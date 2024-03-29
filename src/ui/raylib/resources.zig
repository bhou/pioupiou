const r = @cImport({
    @cInclude("raylib.h");
});

pub const Textures = struct {
    chick: r.Texture2D,
    fox: r.Texture2D,
    hen: r.Texture2D,
    nest: r.Texture2D,
    rooster: r.Texture2D,
    egg: r.Texture2D,
    unknown: r.Texture2D,

    exchange: r.Texture2D,

    pub fn LoadAllTextures() Textures {
        return Textures{
            .chick = loadTexture("resources/dist/chick-800.png"),
            .fox = loadTexture("resources/dist/fox-800.png"),
            .hen = loadTexture("resources/dist/hen-800.png"),
            .nest = loadTexture("resources/dist/nest-800.png"),
            .rooster = loadTexture("resources/dist/roster-800.png"),
            .egg = loadTexture("resources/dist/egg-800.png"),
            .unknown = loadTexture("resources/dist/unknown-800.png"),

            .exchange = loadTexture("resources/dist/exchange-128.png"),
        };
    }

    pub fn deinit(self: *Textures) void {
        r.UnloadTexture(self.chick);
        r.UnloadTexture(self.fox);
        r.UnloadTexture(self.hen);
        r.UnloadTexture(self.nest);
        r.UnloadTexture(self.rooster);
        r.UnloadTexture(self.egg);

        r.UnloadTexture(self.exchange);
    }
};

pub fn loadTexture(path: []const u8) r.Texture2D {
    const image = r.LoadImage(path.ptr);
    defer r.UnloadImage(image);
    const tex = r.LoadTextureFromImage(image);
    return tex;
}
