require('src/MMFHeader')
local res = require('src/resolutions')
local Device = require('src/Device')

---@class DeviceManager
---@field deviceFamilyId string
---@field indexMMFname string
---@field devices Device[]
---@field deviceStr string[]
---@field resolutions Resolutions
---@field indexMMF table
---@field config ac.INIConfig
local DeviceManager = {}

function DeviceManager.new(deviceFamilyId)
    local newResolution = res.new()

    local self = {
        deviceFamilyId = deviceFamilyId ,
        indexMMFname = 'SimHubDashIndexV3' .. deviceFamilyId ,
        devices = {},
        deviceStr = {},
        resolutions = newResolution,
        lastTouchDevice = -1,
        indexMMF = nil,
        config = nil
    }

    return setmetatable(self, { __index = DeviceManager })
end

function DeviceManager:start()
    local indexMmf = ac.writeMemoryMappedFile( self.indexMMFname, MMF.DeviceIndex,true )
    self.indexMMF = indexMmf.deviceIndex
    return self
end


---@param width integer?
---@param height integer?
function DeviceManager:add(width,height)
    local newWidth = width and width or 160
    local newHeight = height and height or 90
    local newDevice = Device.new('KE-VDisp',newWidth,newHeight,MMF.TouchMode.Unchanged)

    local curIndex = #self.devices
    if curIndex >= 10 then
        ac.log('KE-SimHubMMF: DeviceManager: Device entry is Full')
        return nil
    end

    local size = vec2(newDevice.width,newDevice.height)
    self.resolutions:add(size)
    newDevice.index = curIndex
    newDevice.id = ((newDevice.id and newDevice.id or 'KE-VirtualDisplay')..'#'..newDevice.index +1)
    newDevice.mmfName = 'SimHubDashRenderV3' .. self.deviceFamilyId .. '_' .. newDevice.identifier1 .. '_' ..newDevice.identifier2
    newDevice.config = self.config
    newDevice:start()
    newDevice:setTexture(vec2(width,height))

    self.devices[curIndex+1]=newDevice
    self.deviceStr[curIndex+1]=newDevice.id

    self.indexMMF.Device[newDevice.index].DeviceID = {newDevice.id:byte(1,-1)}
    self.indexMMF.Device[newDevice.index].MMFIdentifier1 = newDevice.identifier1
    self.indexMMF.Device[newDevice.index].MMFIdentifier2 = newDevice.identifier2
    self.indexMMF.Device[newDevice.index].DeviceInfo = {(''):byte(1,-1)}
    self.indexMMF.Device[newDevice.index].Available = true
    self:setAndSave()
    return true
end


--車とデバイスごとのコンフィグを受け取るのでそれに従ってデバイスを生成する １０個まで
---@param config ac.INIConfig
function DeviceManager:setup(config)

    self.config = config

    for index, section in self.config:iterate('DEVICE') do
        if index > 10 then return end
        local size = self.config:get(section,'Resolution',vec2(0,0))
        ac.log(size)
        self:add(size.x,size.y)
    end
end

function DeviceManager:remove(devicesIndex)
    self.devices[devicesIndex]:stop()
    table.remove(self.devices,devicesIndex)
    table.remove(self.deviceStr,devicesIndex)
    self:setAndSave()
end


function DeviceManager:update()
    for i = 1, #self.devices do
        self.devices[i]:update()
    end
end

function DeviceManager:checkTouchPoint(mouseClicked)
    local targetMeshes = ac.emptySceneReference()
    local hitsRef = ac.emptySceneReference()
    local hitsUV =vec2()
    for _,device in ipairs(self.devices) do
        targetMeshes:append(device.displayMeshes)
    end

    if #self.devices>0 and targetMeshes:size() ~= 0 and mouseClicked
        and ac.getSim().cameraPosition:closerToThan(targetMeshes:getWorldTransformationRaw().position ,3) 
        and (targetMeshes:raycast(render.createMouseRay(), hitsRef,nil,nil,hitsUV,0) ~= -1 ) then
            self.lastTouchDevice = hitsRef:getAttribute('DeviceIndex')
            self.devices[self.lastTouchDevice +1]:sendTouch(vec2(hitsUV.x,hitsUV.y+1),mouseClicked)
    elseif not mouseClicked and self.lastTouchDevice ~= -1 then
        self.devices[self.lastTouchDevice +1]:sendTouch(vec2(0,0),mouseClicked)
        self.lastTouchDevice = -1
    end
end

function DeviceManager:setAndSave()
    if self.config then 
    for _,section in self.config:iterate('DEVICE') do
        self.config.sections[section] = nil
    end

    for index, device in ipairs(self.devices) do
        if device then
            self.config:set('DEVICE_'..(index-1),'Resolution',vec2(self.devices[index].width,self.devices[index].height))
        end
    end
    self.config:save()
    end
end

return DeviceManager