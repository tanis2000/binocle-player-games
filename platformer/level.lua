local const = require("const")
local Process = require("process")
local layers = require("layers")
local lume = require("lib.lume")
local ldtk = require("lib.ldtk")
local SayMark = require("en.saymark")
local Ship = require("en.ship")
local Collector = require("en.collector")

--- @class Level: Process
---@field super Process
local Level = Process:extend()

Level.PlatformEndLeft = 1
Level.PlatformEndRight = 2

function Level:new(filename, index)
    Level.super.new(self)
    self.name = "level"
    self.hero_spawners = {}
    self.cat_spawners = {}
    self.mob_spawners = {}
    self.collectors = {}
    self.marks_map = {}
    self.tilesets = {}
    ---@class kmVec2
    self.scale = lkazmath.kmVec2New()
    self.scale.x = 1.0
    self.scale.y = 1.0

    local assets_dir = app.assets_dir()
	local level_filename = assets_dir .. filename
    local content = fs.load_text_file(level_filename)
    ldtk:load(content)
    self.map = ldtk:goTo(index)
    self.width = self.map.width
    self.height = self.map.height
    self.collision_layer = nil

    -- Build the tilesets
    for idx in pairs(ldtk.data.defs.tilesets) do
        log.info("idx: " .. idx)
        local ts = ldtk.data.defs.tilesets[idx]
        log.info("uid: " .. ts.uid)
        if ts.relPath == nil then
            log.info("tileset " .. tostring(idx) .. " is not a bitmap based tileset. Skipping it.")
        else
            local image_filename = assets_dir .. "data/maps/" .. ts.relPath
            local img = image.load_from_assets(image_filename)
            local tex = texture.from_image(img)
            local mat = material.new()
            material.set_texture(mat, tex)
            material.set_shader(mat, shader.defaultShader())
            local tiles = {}
            log.info("num tiles: " .. tostring(ts.__cWid * ts.__cHei))
            local count = 0
            for ty = ts.__cHei - 1, 0, -1 do
                for tx = 0, ts.__cWid - 1, 1 do
                    tiles[count] = {}
                    tiles[count].gid = count
                    tiles[count].sprite = sprite.from_material(mat)
                    log.info("x: " .. tostring(ts.padding + tx * (ts.tileGridSize + ts.spacing)) .. " y: " .. tostring(ts.padding + ty * (ts.tileGridSize + ts.spacing)) .. " w: " .. tostring(ts.tileGridSize) .. " h: " .. tostring(ts.tileGridSize))
                    local sub = subtexture.subtexture_with_texture(
                        tex,
                        ts.padding + tx * (ts.tileGridSize + ts.spacing),
                        ts.padding + ty * (ts.tileGridSize + ts.spacing),
                        ts.tileGridSize,
                        ts.tileGridSize
                    )
                    sprite.set_subtexture(tiles[count].sprite, sub)
                    sprite.set_origin(tiles[count].sprite, 0, 0)
                    count = count + 1
                end
            end
            self.tilesets[ts.uid] = {
                uid = ts.uid,
                sprite = sprite.from_material(mat),
                tiles = tiles,
            }
        end
    end


    for idx in pairs(self.map.level.layerInstances) do
        local layer = self.map.level.layerInstances[idx]
        if layer.__identifier == "Collisions" then
            -- Setup collision layer for easy reference
            self.collision_layer = layer
            -- for i in pairs(layer.intGridCsv) do
            --     local value = layer.intGridCsv[i]
            --     local cy = layer.__cHei - 1 - math.floor((i-1) / layer.__cWid)
            --     local cx = math.floor((i-1) % layer.__cWid)
            --     if value ~= 0 and value ~= 2 then
            --         --print(cx, cy)
            --         --self:set_collision(cx, cy, true)
            --     end
            -- end

            -- Setup marks
            for cy = 0, self.collision_layer.__cHei do
                for cx = 0, self.collision_layer.__cWid do
                    if not self:has_collision(cx, cy) and self:has_collision(cx, cy-1) then
                        if self:has_collision(cx+1, cy) or not self:has_collision(cx+1, cy-1) then
                            self:set_mark(cx, cy, Level.PlatformEndRight)
                        end
                        if self:has_collision(cx-1, cy) or not self:has_collision(cx-1, cy-1) then
                            self:set_mark(cx, cy, Level.PlatformEndLeft)
                        end
                    end
                end
            end
        end

        if layer.__identifier == "Entities" then
            for i in pairs(layer.entityInstances) do
                local obj = layer.entityInstances[i]
                if obj.__identifier == "Player" then
                    local spawner = {
                        cx = obj.px[1] / layer.__gridSize,
                        cy = layer.__cHei - (obj.px[2] / layer.__gridSize),
                    }
                    self.hero_spawners[#self.hero_spawners+1] = spawner
                end
                if obj.__identifier == "cat" then
                    local spawner = {
                        cx = obj.px[1] / layer.__gridSize,
                        cy = layer.__cHei - (obj.px[2] / layer.__gridSize),
                    }
                    self.cat_spawners[#self.cat_spawners+1] = spawner
                end
                if obj.__identifier == "mob" then
                    local spawner = {
                        cx = obj.px[1] / layer.__gridSize,
                        cy = layer.__cHei - (obj.px[2] / layer.__gridSize),
                    }
                    self.mob_spawners[#self.mob_spawners+1] = spawner
                end
                if obj.__identifier == "collector" then
                    local cx = obj.px[1] / layer.__gridSize
                    local cy = layer.__cHei - (obj.px[2] / layer.__gridSize)
                    Collector(cx, cy)
                end
            end
        end
        if layer.__identifier == "interactive" then
            for i in pairs(layer.objects) do
                local obj = layer.objects[i]
                if obj.__identifier == "collector" then
                    local collector = {
                        cx = obj.px[1] / layer.__gridSize,
                        cy = layer.__cHei - (obj.px[2] / layer.__gridSize),
                    }
                    self.collectors[#self.collectors+1] = collector
                end
                if obj.__identifier == "say" then
                    local s = SayMark(obj.properties["text"], obj.properties["trigger_distance"])
                    local cx = obj.px[1] / layer.__gridSize
                    local cy = layer.__cHei - (obj.px[2] / layer.__gridSize)
                    s:set_pos_grid(cx, cy)
                end
                if obj.__identifier == "ship" then
                    local cx = obj.px[1] / layer.__gridSize
                    local cy = layer.__cHei - (obj.px[2] / layer.__gridSize)
                    Ship(cx, cy)
                end
            end
        end

    end

    return self
end

function Level:coord_id(cx, cy)
    local cy_inverted = self.collision_layer.__cHei - 1 - cy
    return cx + 1 + cy_inverted * self.collision_layer.__cWid
end

function Level:is_valid(cx, cy)
    return cx >= 0 and cx < self.collision_layer.__cWid and cy >= 0 and cy <= self.collision_layer.__cHei
end

function Level:has_collision(x, y)
    -- print(x, y)
    if not self:is_valid(x, y) then
        return true
    else
        local idx = self:coord_id(x, y)
        local value = self.collision_layer.intGridCsv[idx]
        -- print("idx: " .. tostring(idx) .. " value: " .. tostring(value))
        if value == 1 or value == 3 then
            return true
        end
    end
    return false
end

function Level:has_wall_collision(cx, cy)
        -- print(x, y)
        if not self:is_valid(cx, cy) then
            return true
        else
            local idx = self:coord_id(cx, cy)
            local value = self.collision_layer.intGridCsv[idx]
            -- print("idx: " .. tostring(idx) .. " value: " .. tostring(value))
            if value == 1 then
                return true
            end
        end
        return false
end

function Level:has_one_way(cx, cy)
    -- print(x, y)
    if not self:is_valid(cx, cy) then
        return false
    else
        local idx = self:coord_id(cx, cy)
        local value = self.collision_layer.intGridCsv[idx]
        -- print("idx: " .. tostring(idx) .. " value: " .. tostring(value))
        if value == 3 or self:has_ladder(cx, cy) and not self:has_ladder(cx, cy - 1) and not self:has_collision(cx, cy - 1) then
            return true
        end
    end
    return false
end

function Level:has_ladder(cx, cy)
    -- print(x, y)
    if not self:is_valid(cx, cy) then
        return false
    else
        local idx = self:coord_id(cx, cy)
        local value = self.collision_layer.intGridCsv[idx]
        -- print("idx: " .. tostring(idx) .. " value: " .. tostring(value))
        if value == 2 then
            return true
        end
    end
    return false
end

function Level:set_mark(x, y, v)
    print("setting mark " .. tostring(v) .. " at " .. tostring(x) .. "," .. tostring(y))
    if self:is_valid(x, y) then
        if v then
            self.marks_map[self:coord_id(x, y)] = v
        else
            self.marks_map[self:coord_id(x, y)] = nil
        end
    end
end

function Level:has_mark(x, y, mark)
    --print("looking for mark " .. tostring(mark) .. " at " .. tostring(x) .. tostring(y))
    if not self:is_valid(x, y) then
        return false
    else
        local v = self.marks_map[self:coord_id(x, y)]
        --print("found mark " .. tostring(v))
        if v ~= nil  and v == mark then
            return true
        end
    end
    return false
end

function Level:render()
    --io.write(tostring(dump(self.tilesets)))
    for idx in pairs(self.map.level.layerInstances) do
        local layer = self.map.level.layerInstances[idx]
        if layer.visible and (layer.__type == "IntGrid" or layer.__type == "AutoLayer") then
            --log.info("layer uid " .. tostring(layer.layerDefUid) .. " tileset uid " .. tostring(layer.__tilesetDefUid))
            for i in pairs(layer.autoLayerTiles) do
                --log.info(tostring(i))
                local tile = layer.autoLayerTiles[i]
                local px = tile.px[1]
                local py = self.map.level.pxHei - layer.__gridSize - tile.px[2]
                sprite.draw(
                    self.tilesets[layer.__tilesetDefUid].tiles[tile.t].sprite,
                    gd_instance,
                    px,
                    py,
                    viewport, 0, self.scale.x, self.scale.y, cam, layers.BG)
            end
        end
    end
    -- sprite.draw(self.tilesets[2].sprite, gd_instance, 0, 0, viewport, 0, self.scale.x, self.scale.y, cam, layers.BG)
    -- for i in pairs(self.tilesets[2].tiles) do
    --     sprite.draw(self.tilesets[2].tiles[i].sprite, gd_instance, 0, 0, viewport, 0, self.scale.x, self.scale.y, cam, layers.BG)
    -- end
    -- sprite.draw(self.tilesets[2].tiles[0].sprite, gd_instance, 0, 0, viewport, 0, self.scale.x, self.scale.y, cam, layers.BG)
end

function Level:update(dt)
    -- log.info("level update")
    Level.super.update(self, dt)
    --self:render()
end

function Level:post_update(dt)
    Level.super.post_update(self, dt)
    self:render()
end

function Level:get_c_wid()
    return self.width
end

function Level:get_c_hei()
    return self.height
end

function Level:get_px_wid()
    return self:get_c_wid() * const.GRID
end

function Level:get_px_hei()
    return self:get_c_hei() * const.GRID
end

function Level:get_hero_spawner()
    return self.hero_spawners[1]
end

function Level:get_cat_spawner()
    return lume.randomchoice(self.cat_spawners)
end

function Level:get_mob_spawner()
    return lume.randomchoice(self.mob_spawners)
end

return Level