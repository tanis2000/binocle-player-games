local const = require("const")
local entity = require("entity")
local Intro = require("scenes/intro")
local cache = require("cache")

main = {}
---@type table
G = {
    entities = {}, -- all entities
    mobs = {}, -- all mobs
    cats = {}, -- all cats
    bullets = {}, -- all bullets
    title = "Binocle Player",
    musics = {},
    sounds = {},
    debug = false,
    ---@type Level
    level = nil,
    cache = cache,
    using_game_gui = false,
}
local assets_dir = sdl.assets_dir()
log.info(assets_dir .. "\n")
--package.path = package.path .. ";" .. assets_dir .."?.lua" .. ";?/init.lua"

log.info("Begin of main.lua\n");

-- Global constants

color.azure = color.new(192.0 / 255.0, 1.0, 1.0, 1.0)
color.white = color.new(1.0, 1.0, 1.0, 1.0)
color.black = color.new(0, 0, 0, 1.0)
color.debug_bounds = color.new(0, 1, 0, 0.2)
color.debug_origin = color.new(0, 1, 0, 0.7)
color.trans_green = color.new(0, 1, 0, 0.5)

local quit_requests = 0
---@class Intro
local intro

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

    --default_shader = shader.load_from_file(assets_dir .. "shaders/default_vert.glsl",
    --    assets_dir .. "shaders/default_frag.glsl")
    --io.write("default shader: " .. tostring(default_shader) .. "\n")
    --
    --screen_shader = shader.load_from_file(assets_dir .. "shaders/screen_vert.glsl",
    --    assets_dir .. "shaders/screen_frag.glsl")
    --io.write("screen shader: " .. tostring(screen_shader) .. "\n")

    gd_instance = gd.new()
    gd.init(gd_instance, win)
    io.write("gd_instance: " .. tostring(gd_instance) .. "\n")

    --render_target = gd.create_render_target(const.DESIGN_WIDTH, const.DESIGN_HEIGHT, true, GL_RGBA8)
    --io.write("render_target: " .. tostring(render_target) .. "\n")

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

    local music = audio.load_music_from_assets(audio_instance, app.assets_dir() .. "data/music/theme.mp3")
    G.musics["main"] = music
    audio.play_music(audio_instance, music)
    audio.set_music_volume(audio_instance, G.musics["main"], 0.5)

    main.load_sfx("jump", "data/sfx/jump.wav")
    main.load_sfx("hurt", "data/sfx/hurt.wav")
    main.load_sfx("shoot", "data/sfx/shoot.wav")
    main.load_sfx("purr", "data/sfx/purr.wav")
    main.load_sfx("meow", "data/sfx/meow.mp3")
    main.load_sfx("pickup", "data/sfx/pickup.wav")
    main.load_sfx("powerup", "data/sfx/powerup.wav")
end

function main.on_update(dt)
    --io.write("dt: " .. tostring(dt) .. "\n")
    sprite_batch.begin(sb, cam, shader.defaultShader(), viewport, "BINOCLE_SPRITE_SORT_MODE_FRONT_TO_BACK")
    if not scene then
        intro = Intro()
        intro:init(shader.defaultShader())

        scene = intro
        --return
    end
    --io.write("scene: " .. tostring(scene.name) .. "\n")

    scene:pre_update(dt)

    -- set the render target we want to render to
    --gd.set_render_target(render_target)

    -- clear it
    --window.clear(win)


    -- A simple identity matrix
    --identity_matrix = lkazmath.kmMat4New()
    --lkazmath.kmMat4Identity(identity_matrix)

    if input.is_key_down(input_mgr, key.KEY_1) then
        G.debug = not G.debug
        print(G.debug)
    end

    if input.is_key_down(input_mgr, key.KEY_ESCAPE) then
        quit_requests = quit_requests + 1
        print(quit_requests)
        if quit_requests > 1 then
            input.set_quit_requested(input_mgr, true)
        end
    end

    scene:update(dt)

    -- Gets the viewport calculated by the adapter
    --vp = viewport_adapter.get_viewport(adapter)
    --io.write("vp: " .. tostring(vp) .. "\n")
    --vp_x = viewport_adapter.get_viewport_min_x(adapter)
    --vp_y = viewport_adapter.get_viewport_min_y(adapter)
    --io.write("vp_x: " .. tostring(vp_x) .. "\n")
    --io.write("vp_y: " .. tostring(vp_y) .. "\n")
    -- Reset the render target to the screen
    --gd.set_render_target(nil);
    --gd.clear(color.black)
    --gd.apply_viewport(vp);
    --gd.apply_shader(gd_instance, screen_shader);
    --gd.set_uniform_float2(screen_shader, "resolution", const.DESIGN_WIDTH, const.DESIGN_HEIGHT);
    --gd.set_uniform_mat4(screen_shader, "transform", identity_matrix);
    --gd.set_uniform_float2(screen_shader, "scale", viewport_adapter.get_inverse_multiplier(adapter), viewport_adapter.get_inverse_multiplier(adapter));
    --gd.set_uniform_float2(screen_shader, "viewport", vp_x, vp_y);
    --gd.draw_quad_to_screen(screen_shader, render_target);

    scene:post_update(dt)
    for idx, music in pairs(G.musics) do
        audio.update_music_stream(audio_instance, music)
    end

    local screenViewport = viewport_adapter.get_viewport(adapter)
    gd.begin_screen_pass(gd_instance, win)
    gd.apply_viewport(screenViewport)
    gd.render_screen(gd_instance, win, const.DESIGN_WIDTH, const.DESIGN_HEIGHT, screenViewport, cam)
    if G.debug then
        imgui.SetContext("debug")
        imgui.RenderToScreen("debug", gd_instance, win, const.DESIGN_WIDTH, const.DESIGN_HEIGHT, screenViewport, cam, false)
    end
    if G.using_game_gui then
        imgui.SetContext("game")
        imgui.RenderToScreen("game", gd_instance, win, const.DESIGN_WIDTH, const.DESIGN_HEIGHT, screenViewport, cam, true)
    end
    gd.end_screen_pass()
    gd.commit()

    sprite_batch.finish(sb, cam, viewport)
end

function on_destroy()
    if G.game ~= nil then
        G.game:on_destroy()
    end
end

function main.load_sfx(name, filename)
    local sound = audio.load_sound_from_assets(audio_instance, app.assets_dir() .. filename)
    G.sounds[name] = sound
    audio.set_sound_volume(G.sounds[name], 1.0)
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

function get_design_width()
    io.write("get_design_width: " .. tostring(const.DESIGN_WIDTH) .."\n")
    return const.DESIGN_WIDTH
end

function get_design_height()
    io.write("get_design_height: " .. tostring(const.DESIGN_HEIGHT) .."\n")
    return const.DESIGN_HEIGHT
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

io.write("End of main.lua\n")
