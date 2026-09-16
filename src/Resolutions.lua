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
    local ret = nil
    for i,val in ipairs(self.size) do
        if val == res then 
            ret = i 
            break
        end 
    end
    return ret
end

---@param res vec2
function Resolutions:add(res)
    local ret = nil
    local string = res.x..'x'..res.y
    local existIndex = self:checkRes(res)
    ret = existIndex
    if existIndex == nil then
        local newindex = #self.size+1
        self.size[newindex]=res
        self.strs[newindex]=string
        ret = newindex
    end
    return ret
end

return Resolutions