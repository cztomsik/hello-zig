const nvg = @import("nanovg");

pub const Display = enum { none, block, flex };

pub const Dimension = f32;

pub const Color = nvg.Color;

pub const TRANSPARENT = nvg.rgba(0, 0, 0, 0);

pub const Style = struct {
    display: Display,

    width: Dimension,
    height: Dimension,

    min_width: Dimension,
    min_height: Dimension,

    max_width: Dimension,
    max_height: Dimension,

    padding_top: Dimension,
    padding_right: Dimension,
    padding_bottom: Dimension,
    padding_left: Dimension,

    margin_top: Dimension,
    margin_right: Dimension,
    margin_bottom: Dimension,
    margin_left: Dimension,

    border_top: Dimension,
    border_right: Dimension,
    border_bottom: Dimension,
    border_left: Dimension,

    top: Dimension,
    right: Dimension,
    bottom: Dimension,
    left: Dimension,

    // TODO: flex

    opacity: f32 = 1,
    border_radius: [4]f32 = .{ 0, 0, 0, 0 },
    background_color: Color = TRANSPARENT,
};
