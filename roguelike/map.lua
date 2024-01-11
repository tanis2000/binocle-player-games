local lume = require("lib.lume")
local bsp = require("lib.bsp")
local Object = require("lib.classic")
local map = Object:extend()

local ROOM_MAX_SIZE = 12
local ROOM_MIN_SIZE = 6

function map.new(self, w, h)
    self.width = w
    self.height = h
    self.tiles = {}
    for i = 1, w*(h+1), 1 do
        lume.push(self.tiles, { can_walk = false, hero_spawner = false })
    end
    local tree = bsp(0, 0, w, h)
    tree:split_recursive(8, ROOM_MAX_SIZE, ROOM_MIN_SIZE, 1.5, 1.5)
    Listener = {
        map = self,
        room_num = 0,
        last_x = 0,
        last_y = 0,
        callback = function(node, user_data)
            Listener.map:print_tiles()
            if node:is_leaf() then
                local w = math.floor(lume.random(ROOM_MIN_SIZE, node.w - 2))
                local h = math.floor(lume.random(ROOM_MIN_SIZE, node.h - 2))
                local x = math.floor(lume.random(node.x + 1, node.x + node.w - w - 1))
                local y = math.floor(lume.random(node.y + 1, node.y + node.h - h - 1))
                local first = Listener.room_num == 0
                Listener.map:create_room(first, x, y, x + w - 1, y + h - 1)
                Listener.map:print_tiles()
                if not first then
                    Listener.map:dig(Listener.last_x, Listener.last_y, x + math.floor(w / 2), Listener.last_y)
                    Listener.map:dig(x + math.floor(w / 2), Listener.last_y, x + math.floor(w / 2), y + math.floor(h / 2))
                end
                Listener.last_x = x + math.floor(w / 2)
                Listener.last_y = y + math.floor(h / 2)
                Listener.room_num = Listener.room_num + 1
                print("room num " .. tostring(Listener.room_num))
            end
            return true
        end,
    }
    tree:traverse_inverted_level_order(Listener.callback)
end

function map:create_room(first, x1, y1, x2, y2)
    self:dig(x1, y1, x2, y2)
    if first then
        self.tiles[x1+y1*self.width].hero_spawner = true
    end
end

function map:dig(x1, y1, x2, y2)
    if x2 < x1 then
        local tmp = x2
        x2 = x1
        x1 = tmp
    end

    if y2 < y1 then
        local tmp = y2
        y2 = y1
        y1 = tmp
    end

    for tile_x = x1, x2, 1 do
        for tile_y = y1, y2, 1 do
            self.tiles[tile_x+tile_y*self.width].can_walk = true
        end
    end
end

function map:print_tiles()
    io.write(" ")
    for x = 1, self.width, 1 do
        io.write(tostring(x % 10))
    end
    io.write("\n")

    for y = 1, self.height, 1 do
        for x = 1, self.width, 1 do
            if x == 1 then
                io.write(tostring(y % 10))
            end
            if self.tiles[x + y * self.width].hero_spawner then
                io.write("@")
            elseif self.tiles[x + y * self.width].can_walk then
                io.write(".")
            else
                io.write("X")
            end
        end
        io.write("\n")
    end
end

return map