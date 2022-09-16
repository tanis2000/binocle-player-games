local const = require("const")

main = {
    TEX_WIDTH = 1682,
    TEX_HEIGHT = 479,
    default_font = nil
}

---@type table
G = {
    title = "Binocle Player Simple Game",
}

local assets_dir = sdl.assets_dir()
log.info(assets_dir .. "\n")
log.info("Begin of main.lua\n");

local setup_done = false

-- Global constants
color.black = color.new(0, 0, 0, 1.0)

local quit_requests = 0

function on_init()
    ---@type Window
    win = window.new(const.DESIGN_WIDTH * const.SCALE, const.DESIGN_HEIGHT * const.SCALE, G.title)
    io.write("win: " .. tostring(win) .."\n")
    local bg_color = color.black
    io.write("bg_color: " .. tostring(bg_color) .."\n")
    window.set_background_color(win, bg_color)
    window.set_minimum_size(win, const.DESIGN_WIDTH, const.DESIGN_HEIGHT)

    input_mgr = input.new()

    adapter = viewport_adapter.new(win, "scaling", "pixel_perfect",
            const.DESIGN_WIDTH, const.DESIGN_HEIGHT, const.DESIGN_WIDTH, const.DESIGN_HEIGHT);
    io.write("adapter: " .. tostring(adapter) .."\n")

    cam = camera.new(adapter)
    io.write("cam: " .. tostring(cam) .."\n")

    gd_instance = gd.new()
    gd.init(gd_instance, win)
    io.write("gd_instance: " .. tostring(gd_instance) .. "\n")

    sb = sprite_batch.new()
    sprite_batch.set_gd(sb, gd_instance)

    -- Create a viewport that corresponds to the size of our render target
    center = lkazmath.kmVec2New();
    center.x = const.DESIGN_WIDTH / 2;
    center.y = const.DESIGN_HEIGHT / 2;
    viewport = lkazmath.kmAABB2New();
    lkazmath.kmAABB2Initialize(viewport, center, const.DESIGN_WIDTH, const.DESIGN_HEIGHT, 0)

    audio_instance = audio.new()
    audio.init(audio_instance)
    io.write("audio_instance: " .. tostring(audio_instance) .. "\n")
end

function main.on_update(dt)
    sprite_batch.begin(sb, cam, shader.defaultShader())

    if not setup_done then
        main.setup(shader.defaultShader())
    end

    if input.is_key_down(input_mgr, key.KEY_ESCAPE) then
        quit_requests = quit_requests + 1
        print(quit_requests)
        if quit_requests > 1 then
            input.set_quit_requested(input_mgr, true)
        end
    end

    main.local_update(dt)
    gd.render_screen(gd_instance, win, const.DESIGN_WIDTH, const.DESIGN_HEIGHT, viewport, cam)

    sprite_batch.finish(sb, cam)
end

function main.setup(shd)
    main.name = "intro"
    local assets_dir = sdl.assets_dir()
    local image_filename = assets_dir .. "data/img/binocle-logo-full.png"
    main.img = image.load(image_filename)
    main.tex = texture.from_image(main.img)
    main.mat = material.new()

    io.write("intro.mat: " .. tostring(main.mat) .."\n")
    io.write("material: " .. tostring(material) .."\n")
    io.write("shd: " .. tostring(shd) .."\n")
    material.set_texture(main.mat, main.tex)
    material.set_shader(main.mat, shd)
    main.logo = sprite.from_material(main.mat)
    main.shader = shd

    main.azure_color = color.new(191.0 / 255.0, 1.0, 1.0, 1.0)
    main.white_color = color.new(1.0, 1.0, 1.0, 1.0)
    main.black_color = color.new(0, 0, 0, 1.0)

    gd.set_offscreen_clear_color(gd_instance, 1, 1, 1, 1)

    main.default_font = ttfont.from_file(assets_dir .. "font/default.ttf", 8, shader.defaultShader());

    setup_done = true
end

function main.local_update(dt)
    local scale_x = const.DESIGN_WIDTH / main.TEX_WIDTH
    local scale_y = const.DESIGN_HEIGHT / main.TEX_WIDTH

    -- Center the logo in the render target
    local x = (const.DESIGN_WIDTH - (main.TEX_WIDTH * scale_x)) / 2.0
    local y = (const.DESIGN_HEIGHT - (main.TEX_HEIGHT * scale_y)) / 2.0

    sprite.draw(main.logo, gd_instance, x, y, viewport, 0, scale_x, scale_y, cam)

    local s = "Press ESC twice to QUIT"
    local width = ttfont.get_string_width(main.default_font, s)
    ttfont.draw_string(main.default_font, s, gd_instance, (const.DESIGN_WIDTH - width)/2, 50, viewport, color.black, cam);

end

function on_destroy()
    if main.default_font ~= nil then
        ttfont.destroy(main.default_font)
    end
end

function get_window()
    io.write("get_window win: " .. tostring(win) .."\n")
    return win
end

function get_adapter()
    io.write("get_adapter adapter: " .. tostring(adapter) .."\n")
    return adapter
end

function get_camera()
    io.write("get_camera cam: " .. tostring(cam) .."\n")
    return cam
end

function get_input_mgr()
    io.write("get_input_mgr input_mgr: " .. tostring(input_mgr) .."\n")
    return input_mgr
end

function get_gd_instance()
    io.write("get_gd_instance gd: " .. tostring(gd_instance) .."\n")
    return gd_instance
end

function get_sprite_batch_instance()
    io.write("get_sprite_batch_instance sb: " .. tostring(sb) .."\n")
    return sb
end

function get_audio_instance()
    io.write("get_audio_instance audio_instance: " .. tostring(audio_instance) .."\n")
    return audio_instance
end

io.write("End of main.lua\n")
