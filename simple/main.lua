local const = require("const")

main = {
    TEX_WIDTH = 1682,
    TEX_HEIGHT = 479,
    default_font = nil
}

---@type table
G = {
    title = "Binocle Player Simple Game",
    viewport = nil,
    win = nil,
    input_mgr = nil,
    adapter = nil,
    cam = nil,
    gd_instance = nil,
    sb = nil,
    audio_instance = nil,
}

local assets_dir = app.assets_dir()
log.info(assets_dir .. "\n")
log.info("Begin of main.lua\n");

local setup_done = false

-- Global constants
color.black = color.new(0, 0, 0, 1.0)

local quit_requests = 0

function on_init()
    ---@type Window
    G.win = window.new(const.DESIGN_WIDTH * const.SCALE, const.DESIGN_HEIGHT * const.SCALE, G.title)
    io.write("win: " .. tostring(G.win) .."\n")
    local bg_color = color.black
    io.write("bg_color: " .. tostring(bg_color) .."\n")
    window.set_background_color(G.win, bg_color)
    window.set_minimum_size(G.win, const.DESIGN_WIDTH, const.DESIGN_HEIGHT)

    G.input_mgr = input.new()

    G.adapter = viewport_adapter.new(G.win, "scaling", "pixel_perfect",
            const.DESIGN_WIDTH, const.DESIGN_HEIGHT, const.DESIGN_WIDTH, const.DESIGN_HEIGHT);
    io.write("adapter: " .. tostring(G.adapter) .."\n")

    G.cam = camera.new(G.adapter)
    io.write("cam: " .. tostring(G.cam) .."\n")

    G.gd_instance = gd.new()
    gd.init(G.gd_instance, G.win)
    io.write("gd_instance: " .. tostring(G.gd_instance) .. "\n")

    G.sb = sprite_batch.new()
    sprite_batch.set_gd(G.sb, G.gd_instance)

    -- Create a viewport that corresponds to the size of our render target
    ---@class kmVec2
    local center = lkazmath.kmVec2New();
    center.x = const.DESIGN_WIDTH / 2;
    center.y = const.DESIGN_HEIGHT / 2;
    G.viewport = lkazmath.kmAABB2New();
    lkazmath.kmAABB2Initialize(G.viewport, center, const.DESIGN_WIDTH, const.DESIGN_HEIGHT, 0)

    G.audio_instance = audio.new()
    audio.init(G.audio_instance)
    io.write("audio_instance: " .. tostring(G.audio_instance) .. "\n")
end

function main.on_update(dt)
    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
        DEBUGGER.pullBreakpoints()
    end
    sprite_batch.begin(G.sb, G.cam, shader.defaultShader(), G.viewport, "BINOCLE_SPRITE_SORT_MODE_FRONT_TO_BACK")

    if not setup_done then
        main.setup(shader.defaultShader())
    end

    if input.is_key_down(G.input_mgr, key.KEY_ESCAPE) then
        quit_requests = quit_requests + 1
        print(quit_requests)
        if quit_requests > 1 then
            input.set_quit_requested(G.input_mgr, true)
        end
    end

    main.local_update(dt)

    local screenViewport = viewport_adapter.get_viewport(G.adapter)
    gd.begin_screen_pass(G.gd_instance, G.win)
    gd.apply_viewport(screenViewport)
    gd.render_screen(G.gd_instance, G.win, const.DESIGN_WIDTH, const.DESIGN_HEIGHT, G.viewport, G.cam)
    gd.end_screen_pass()
    gd.commit()

    sprite_batch.finish(G.sb, G.cam, G.viewport)
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

    gd.set_offscreen_clear_color(G.gd_instance, 1, 1, 1, 1)

    main.default_font = ttfont.from_assets(app.assets_dir() .. "font/default.ttf", 8, shader.defaultShader());

    setup_done = true
end

function main.local_update(dt)
    local scale_x = const.DESIGN_WIDTH / main.TEX_WIDTH
    local scale_y = const.DESIGN_HEIGHT / main.TEX_WIDTH

    -- Center the logo in the render target
    local x = (const.DESIGN_WIDTH - (main.TEX_WIDTH * scale_x)) / 2.0
    local y = (const.DESIGN_HEIGHT - (main.TEX_HEIGHT * scale_y)) / 2.0

    sprite.draw(main.logo, G.gd_instance, x, y, G.viewport, 0, scale_x, scale_y, G.cam, 0)

    local s = "Just displaying this image. Nothing else to see here :)"
    local width = ttfont.get_string_width(main.default_font, s)
    ttfont.draw_string(main.default_font, s, G.gd_instance, (const.DESIGN_WIDTH - width)/2, 80, G.viewport, color.black, G.cam, 0);

    s = "Press ESC twice to QUIT"
    width = ttfont.get_string_width(main.default_font, s)
    ttfont.draw_string(main.default_font, s, G.gd_instance, (const.DESIGN_WIDTH - width)/2, 50, G.viewport, color.black, G.cam, 0);

end

function on_destroy()
    if main.default_font ~= nil then
        ttfont.destroy(main.default_font)
    end
end

function get_window()
    io.write("get_window win: " .. tostring(G.win) .."\n")
    return G.win
end

function get_adapter()
    io.write("get_adapter adapter: " .. tostring(G.adapter) .."\n")
    return G.adapter
end

function get_camera()
    io.write("get_camera cam: " .. tostring(G.cam) .."\n")
    return G.cam
end

function get_input_mgr()
    io.write("get_input_mgr input_mgr: " .. tostring(G.input_mgr) .."\n")
    return G.input_mgr
end

function get_gd_instance()
    io.write("get_gd_instance gd: " .. tostring(G.gd_instance) .."\n")
    return G.gd_instance
end

function get_sprite_batch_instance()
    io.write("get_sprite_batch_instance sb: " .. tostring(G.sb) .."\n")
    return G.sb
end

function get_audio_instance()
    io.write("get_audio_instance audio_instance: " .. tostring(G.audio_instance) .."\n")
    return G.audio_instance
end

function get_design_width()
    return const.DESIGN_WIDTH
end

function get_design_height()
    return const.DESIGN_HEIGHT
end

io.write("End of main.lua\n")
