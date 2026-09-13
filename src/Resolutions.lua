---@class Resolutions
---@field size table
---@field strs table
local Resolutions = {}

function Resolutions.new()
    local self = {
        size = {vec2(160,90),vec2(160,100),vec2(320,180),vec2(320,200),vec2(480,270),vec2(480,300),vec2(640,360),vec2(640,400)},
        strs = {'160x90','160x100','320x180','320x200','480x270','480x300','640x360','640x400'}
    }
    return setmetatable(self, { __index = Resolutions })
end

---@param res vec2
function Resolutions:checkRes(res)
    local ret = false
    for _,val in ipairs(self.size) do
        if val == res then ret = true end 
    end
    return ret
end

---@param res vec2
function Resolutions:add(res)
    local string = res.x..'x'..res.y
    if not self:checkRes(res) then
        self.size.append(res)
        self.strs.appned(string)
    end
end

return Resolutions