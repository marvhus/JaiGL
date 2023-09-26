/* =========================================================================
 * This is main.jai
 * Copyright (C) 2023  marvhus
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 * ========================================================================== */

width  := 1280;
height := 720;
isRunning := true;
is_fullscreened := false;
saved_window_info : Saved_Window_Info;

main :: () {
    window := create_window(width, height, "JaiGL");
    Simp.set_render_target(window);

    shaderID := link_shaders("default.glsl");

    vao := vao_from_verticies(.[
        .{-0.5, -0.5, 0.0},
        .{ 0.5, -0.5, 0.0},
        .{ 0.0,  0.5, 0.0},
    ]);

    while isRunning {
        handle_events(window);

        glViewport(0, 0, xx width, xx height);
        glClearColor(0.2, 0.3, 0.3, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        glUseProgram(shaderID);
        glBindVertexArray(vao);

        glDrawArrays(GL_TRIANGLES, 0, 3);

        Simp.swap_buffers(window);
    }
}

handle_events :: (window: $T)  {
    toggled_fullscreen := false;

    update_window_events();
    // Keyboard events
    for event: events_this_frame {
        if event.type == {
            case .QUIT; isRunning = false;
            case .KEYBOARD;
            if event.key_pressed if event.key_code == {
                case .ESCAPE; isRunning = false;
                case .F11;
                if !toggled_fullscreen {
                    is_fullscreened = !is_fullscreened;
                    success, w, h := toggle_fullscreen(window, is_fullscreened, *saved_window_info);
                    if success {
                        width = w;
                        height = h;
                        toggled_fullscreen = true;
                    }
                }
            }
        }
    }
    // Resize events
    for get_window_resizes() {
        width = it.width;
        height = it.height;
    }
}

vao_from_verticies :: (verticies: [3]Vector3) -> u32 {
    vao, vbo: u32;
    glGenVertexArrays(1, *vao);
    glBindVertexArray(vao);

    glGenBuffers(1, *vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    //                            Size of verticies in bytes
    glBufferData(GL_ARRAY_BUFFER, size_of(Vector3) * 3, verticies.data, GL_STATIC_DRAW);
    //                       Amount of elements
    //                       |  Element type
    //                       |  |                   Stride in bytes
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vector3), cast(*void) 0);
    glEnableVertexAttribArray(0);
    return vao;
}

#load "shaders.jai";

#import "Window_Creation";
#import "String";
#import "Input";
#import "Basic";
#import "Math";
#import "File";
#import "GL";

Simp :: #import "Simp";
