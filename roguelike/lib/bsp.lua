local lume = require("lib.lume")
local Object = require("lib.classic")

---@class Bsp
---@field next Bsp?
---@field father Bsp?
---@field sons Bsp?
---@field x number
---@field y number
---@field w number
---@field h number
---@field position number
---@field level number
---@field horizontal boolean
local bsp = Object:extend()

---@param father Bsp
---@param left boolean
function bsp.new(self, x, y, w, h, father, left)
    self.next = nil
    self.father = nil
    self.sons = nil
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.position = 0
    self.level = 0
    self.horizontal = false

    if father ~= nil then
        if father.horizontal then
            self.x = father.x
            self.w = father.w
            if left then
                self.y = father.y
                self.h = father.position - self.y
            else
                self.y = father.position
                self.h = father.y + father.h - father.position
            end
        else
            self.y = father.y
            self.h = father.h
            if left then
                self.x = father.x
                self.w = father.position - self.x
            else
                self.x = father.position
                self.w = father.x + father.w - father.position
            end
        end
        self.level = father.level + 1
    end
end

---Add a son to the tree
---@param son Bsp
function bsp:add_son(son)
    local last_son = self.sons
    son.father = self
    while last_son and last_son.next do
        last_son = last_son.next
    end
    if last_son then
        last_son.next = son
    else
        self.sons = son
    end
end

---Gets the left tree
---@return Bsp?
function bsp:left()
    return self.sons
end

---Gets the right tree
---@return Bsp?
function bsp:right()
    if self.sons then
        return self.sons.next
    else
        return nil
    end
end

---Return the father of this node
---@return Bsp?
function bsp:get_father()
    return self.father
end

function bsp:is_leaf()
    return self.sons == nil
end

function bsp:split_once(horizontal, position)
    self.horizontal = horizontal
    self.position = position
    self:add_son(bsp(0, 0, 0, 0, self, true))
    self:add_son(bsp(0, 0, 0, 0, self, false))
end

---Split the BSP recursively
---@param nb number
---@param min_h_size number
---@param min_v_size number
---@param max_h_ratio number
---@param max_v_ratio number
function bsp:split_recursive(nb, min_h_size, min_v_size, max_h_ratio, max_v_ratio)
    local horiz
    local position
    if nb == 0 or (self.w < 2 * min_h_size and self.h < 2 * min_v_size) then
        return
    end
    -- Promote square rooms
    if self.h < 2 * min_v_size or self.w > self.h * max_h_ratio then
        horiz = false
    elseif self.w < 2 * min_h_size or self.h > self.w * max_v_ratio then
        horiz = true
    else
        local r = lume.random(0, 1)
        if r == 0 then
            horiz = true
        else
            horiz = false
        end
    end
    if horiz then
        position = math.floor(lume.random(self.y + min_v_size, self.y + self.h - min_v_size))
    else
        position = math.floor(lume.random(self.x + min_h_size, self.x + self.w - min_h_size))
    end
    self:split_once(horiz, position)
    self:left():split_recursive(nb - 1, min_h_size, min_v_size, max_h_ratio, max_v_ratio)
    self:right():split_recursive(nb - 1, min_h_size, min_v_size, max_h_ratio, max_v_ratio)
end

function bsp:traverse_inverted_level_order(listener, user_data)
    local stack1 = {}
    local stack2 = {}
    lume.push(stack1, self)
    while #stack1 > 0 do
        local node = stack1[1]
        lume.push(stack2, node)
        lume.remove(stack1, node)
        local left = node:left()
        if left then
            lume.push(stack1, left)
        end
        local right = node:right()
        if right then
            lume.push(stack1, right)
        end
    end

    while #stack2 > 0 do
        local node = stack2[#stack2]
        lume.remove(stack2, node)
        if not listener(node, user_data) then
            return false
        end
    end

    return true
end

return bsp