const std = @import("std");
const nvg = @import("nanovg");
const Document = @import("document.zig").Document;
const NodeId = @import("document.zig").NodeId;
const Style = @import("style.zig").Style;
const Color = @import("style.zig").Color;
const TRANSPARENT = @import("style.zig").TRANSPARENT;

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

        var ctx = RenderContext{ .document = document, .vg = &self.vg, .avail_w = 600 };

        // white bg
        ctx.fillShape(&.{ .rect = .{ .right = 800, .bottom = 600 } }, nvg.rgb(255, 255, 255));

        ctx.renderNode(Document.ROOT);
    }
};

const RenderContext = struct {
    document: *const Document,
    vg: *nvg,

    // TODO: layout engine
    y: f32 = 0,
    avail_w: f32,

    const Self = @This();

    fn renderNode(self: *Self, node: NodeId) void {
        std.debug.print("renderNode {}\n", .{node});

        self.y += 20;

        var rect = Rect{ .top = self.y, .left = (800 - self.avail_w) / 2, .right = 800 / 2 + (self.avail_w / 2), .bottom = self.y + 40.0 };

        switch (self.document.node_type(node)) {
            .element => self.drawContainer(rect, self.document.element_style(node), self.document.children(node)),
            .text => self.drawText(rect, self.document.text(node)),
            .document => self.drawContainer(rect, &.{}, self.document.children(node)),
        }
    }

    fn drawContainer(self: *Self, rect: Rect, style: *const Style, children: []const NodeId) void {
        // split open/close so we can skip invisibles AND we can also reduce stack usage per each recursion
        // TODO: @call(.{ .modifier = .never_inline }, ...)
        if (self.openContainer(rect, style)) {
            for (children) |ch| {
                self.renderNode(ch);
            }

            self.closeContainer();
        }
    }

    fn openContainer(self: *Self, rect: Rect, style: *const Style) bool {
        // we don't have to save/restore() if we can skip the whole subtree
        if (style.opacity == 0) {
            return false;
        }

        // TODO: layout
        self.avail_w -= 40;

        // restored later
        self.vg.save();

        if (style.opacity != 1.0) {
            const current = self.vg.ctx.getState().alpha;
            self.vg.globalAlpha(current * style.opacity);
        }

        const shape = if (!std.meta.eql(style.border_radius, .{ 0, 0, 0, 0 }))
            Shape{ .rrect = .{ .rect = rect, .radii = style.border_radius } }
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

        if (!std.meta.eql(style.background_color, TRANSPARENT)) {
            self.drawBgColor(&shape, style.background_color);
        }

        // TODO: image(s)

        // TODO: scroll
        // self.vg.translate(dx, dy);

        return true;
    }

    fn closeContainer(self: *Self) void {
        // TODO: optional border

        // TODO: layout
        self.avail_w += 40;
        self.y += 60;

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
