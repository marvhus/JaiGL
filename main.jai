VERTEX_SHADER :: #string END
#version 330
layout (location = 0) in vec3 pos;
void main() {
    gl_Position  = vec4(pos.x, pos.y, pos.z, 1.0);
}
END

FRAGMENT_SHADER :: #string END
#version 330
out vec4 color;
void main() {
    color = vec4(1.0, 0.5, 0.2, 1.0);
}
END

width  := 1280;
height := 720;
isRunning := true;
is_fullscreened := false;
saved_window_info : Saved_Window_Info;

main :: () {
    window := create_window(width, height, "JaiGL");
    set_render_target(window);

    shaderID := link_shaders(VERTEX_SHADER, FRAGMENT_SHADER);

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

        swap_buffers(window);
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

link_shaders :: (vert_source: string, frag_source: string) -> GLuint {
    vert_shader := compile_shader(vert_source, .Vertex);
    frag_shader := compile_shader(frag_source, .Fragment);

    shaderID := glCreateProgram();
    glAttachShader(shaderID, vert_shader);
    glAttachShader(shaderID, frag_shader);
    glLinkProgram(shaderID);
    success, infoLog := check_link_errors(shaderID);
    if !success then log_error("Could not link shaders: %\n", infoLog);

    glDeleteShader(vert_shader);
    glDeleteShader(frag_shader);

    return shaderID;
}

compile_shader :: (source: string, kind: enum{Vertex;Fragment;}) -> GLuint {
    shader_kind := ifx kind == .Vertex then GL_VERTEX_SHADER else GL_FRAGMENT_SHADER;
    shader := glCreateShader(xx shader_kind);
    glShaderSource(shader, 1, *source.data, null);
    glCompileShader(shader);
    success, infoLog := check_compile_errors(shader);
    if !success {
        shader_name := ifx kind == .Vertex then "Vertex" else "Fragment";
        log_error("Could not compile % shader: %\n", shader_name, infoLog);
    }
    return shader;
}

check_compile_errors :: (shader : GLuint) -> bool, info_log : string {
    success : s32;
    glGetShaderiv (shader, GL_COMPILE_STATUS, *success);
    if !success {
        info_len : s32;
        glGetShaderiv (shader, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast (*u8) alloc (info_len, temp);
        glGetShaderInfoLog (shader, xx info_len, xx *info_len, info_data);
        result : string;
        result.data = info_data;
        result.count = info_len;

        return false, result;
    }

    return true, "";
}

check_link_errors :: (program : GLuint) -> bool, info_log : string {
    success : s32;
    glGetProgramiv (program, GL_LINK_STATUS, *success);
    if !success {
        info_len : s32;
        glGetProgramiv (program, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast (*u8) alloc (info_len, temp);
        glGetProgramInfoLog (program, xx info_len, xx *info_len, info_data);
        result : string;
        result.data = info_data;
        result.count = info_len;

        return false, result;
    }

    return true, "";
}

#import "Window_Creation";
#import "String";
#import "Input";
#import "Basic";
#import "Math";
#import "Simp";
#import "GL";
