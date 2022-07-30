const nvg = @import("nanovg");

pub const Color = nvg.Color;

pub const TRANSPARENT = nvg.rgba(0, 0, 0, 0);

pub const Style = struct {
    opacity: f32 = 1,
    border_radius: [4]f32 = .{ 0, 0, 0, 0 },
    background_color: Color = TRANSPARENT,
};
