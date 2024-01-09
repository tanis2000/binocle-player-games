local util = {
}

---@param fn function
function util.line(x, y, x2, y2, fn, data)
    local dx = x
    local dy = y
    local res = nil
    local distX = math.abs(x2 - x)
    local distY = math.abs(y2 - y)
    local len = math.max(distX, distY)

    for i = 1, len do
        if data ~= nil then
            res = fn(data, math.floor(dx), math.floor(dy))
        else
            res = fn(math.floor(dx), math.floor(dy))
        end
        if res then
            break
        end

        dx = dx + distX / len
        dy = dy + distY / len
    end

    return res

end

return util