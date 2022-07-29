const std = @import("std");
const c = @import("c.zig");
const Document = @import("document.zig").Document;
const Renderer = @import("renderer.zig").Renderer;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() anyerror!void {
    if (c.glfwInit() == 0) return error.GlfwInitFailed;
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 2);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 0);

    const window = c.glfwCreateWindow(800, 600, "Hello", null, null) orelse return error.GlfwCreateWindowFailed;
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);

    _ = gladLoadGL();

    var renderer = try Renderer.init(allocator);
    var doc = try Document.init(allocator);
    const div = try doc.createElement("div");
    const hello = try doc.createTextNode("Hello");
    try doc.appendChild(div, hello);
    try doc.appendChild(Document.ROOT, div);

    while (c.glfwWindowShouldClose(window) == 0) {
        c.glfwWaitEvents();

        renderer.render(&doc);
        c.glfwSwapBuffers(window);
    }
}

extern fn gladLoadGL() callconv(.C) c_int;
