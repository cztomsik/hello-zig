const std = @import("std");
const nvg = @import("nanovg");
const Document = @import("document.zig").Document;
const NodeId = @import("document.zig").NodeId;

const Color = nvg.Color;

const ContainerStyle = struct {
    // transform: ?Matrix,
    opacity: f32 = 1,
    border_radii: ?[4]f32 = null,
    // shadow: ?Shadow,
    // outline: ?Outline,
    // TODO: enum(u2) or packed struct { bool, bool } with same size
    clip: bool = false,
    bg_color: ?Color = null,
    // TODO: images/gradients
    // border: ?Border,
};

const Shape = union(enum) { rect: Rect, rrect: RRect };

const Rect = struct { left: f32 = 0, top: f32 = 0, right: f32 = 0, bottom: f32 = 0 };

const RRect = struct { rect: Rect, radii: [4]f32 };

pub const Renderer = struct {
    vg: nvg,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) anyerror!Self {
        const vg = try nvg.gl.init(allocator, .{
            .antialias = true,
            .stencil_strokes = false,
            .debug = true,
        });

        const font = @embedFile("../nanovg-zig/examples/Roboto-Regular.ttf");
        _ = vg.createFontMem("sans", font);

        return Self{ .vg = vg };
    }

    pub fn deinit(self: *Self) void {
        self.vg.deinit();
    }

    pub fn render(self: *Self, document: *const Document) void {
        self.vg.reset();
        self.vg.beginFrame(800, 600, 1.0);
        defer self.vg.endFrame();

        // white bg
        self.fillShape(&.{ .rect = .{ .right = 800, .bottom = 600 } }, nvg.rgb(255, 255, 255));

        self.renderNode(document, Document.ROOT, 0);
    }

    fn renderNode(self: *Self, document: *const Document, node: NodeId, index: usize) void {
        std.debug.print("renderNode {} {}\n", .{ node, index });

        const rect = Rect{ .top = 60 * @intToFloat(f32, index), .right = 600, .bottom = 60 * @intToFloat(f32, index) + 40.0 };

        switch (document.node_type(node)) {
            .document, .element => {
                if (self.openContainer(rect, &.{ .bg_color = nvg.rgba(255, 0, 0, 127), .opacity = 0.75 })) {
                    for (document.children(node)) |ch, i| {
                        self.renderNode(document, ch, i);
                    }

                    self.closeContainer();
                }
            },
            .text => self.drawText(rect, document.text(node)),
        }
    }

    fn openContainer(self: *Self, rect: Rect, style: *const ContainerStyle) bool {
        // we don't have to save/restore() if we can skip the whole subtree
        if (style.opacity == 0) {
            return false;
        }

        // restored later
        self.vg.save();

        if (style.opacity != 1.0) {
            const current = self.vg.ctx.getState().alpha;
            self.vg.globalAlpha(current * style.opacity);
        }

        const shape = if (style.border_radii) |radii|
            Shape{ .rrect = .{ .rect = rect, .radii = radii } }
        else
            Shape{ .rect = rect };

        // if let Some(matrix) = &style.transform {
        //     self.canvas.concat(matrix);
        // }

        // if (style.shadow) |shadow| {
        //     self.drawShadow(&shape, shadow);
        // }

        // if (style.outline) |outline| {
        //     self.drawOutline(&shape, outline);
        // }

        // if style.clip {
        //     self.clipShape(&shape, ClipOp::Intersect, true /*style.transform.is_some()*/);
        // }

        if (style.bg_color) |color| {
            self.drawBgColor(&shape, color);
        }

        // TODO: image(s)

        // TODO: scroll
        // self.vg.translate(dx, dy);

        return true;
    }

    fn closeContainer(self: *Self) void {
        // TODO: optional border

        self.vg.restore();
    }

    fn drawBgColor(self: *Self, shape: *const Shape, color: Color) void {
        self.fillShape(shape, color);
    }

    fn fillShape(self: *Self, shape: *const Shape, color: Color) void {
        self.vg.beginPath();

        switch (shape.*) {
            .rect => |rect| self.vg.rect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top),
            .rrect => |rrect| {
                const rect = &rrect.rect;
                // TODO: if (radii[0] == radii[1] ...)
                self.vg.roundedRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, rrect.radii[0]);
            },
        }

        self.vg.fillColor(color);
        self.vg.fill();
    }

    fn drawText(self: *Self, rect: Rect, text: []const u8) void {
        self.vg.fontFace("sans");
        self.vg.fontSize(16);
        self.vg.fillColor(nvg.rgb(0, 0, 0));
        _ = self.vg.text(rect.left, rect.top + 16, text);
    }
};
