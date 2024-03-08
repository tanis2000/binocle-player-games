local Entity = require("entity")

---@class Ship: Entity
---@field super Entity
local Ship = Entity:extend()

function Ship:new(cx, cy)
    Ship.super.new(self)
    self.cx = cx
    self.cy = cy
end

return Ship