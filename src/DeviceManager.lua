require('src/MMFHeader')

---@class DeviceManager
---@field deviceFamilyId string
---@field indexMMFname string
---@field devices Device[]
---@field indexMMF table
---@field deviceCounter integer
local DeviceManager = {}

function DeviceManager.new(deviceFamilyId)
    local self = {
        deviceFamilyId = deviceFamilyId ,
        indexMMFname = 'SimHubDashIndexV3' .. deviceFamilyId ,
        devices = {},
        lastTouchDevice = -1
    }

    return setmetatable(self, { __index = DeviceManager })
end

function DeviceManager:start()
    local indexMmf = ac.writeMemoryMappedFile( self.indexMMFname, MMF.DeviceIndex,true )
    self.indexMMF = indexMmf.deviceIndex
    return self
end

function DeviceManager:add(device)
    local curIndex = #self.devices
    if curIndex >= 10 then
        ac.log('KE-SimHubMMF: DeviceManager: Device entry is Full')
        return nil
    end
    device.index = curIndex
    device.id = ((device.id and device.id or 'KE-VirtualDisplay')..'#'..device.index +1)
    device.mmfName = 'SimHubDashRenderV3' .. self.deviceFamilyId .. '_' .. device.identifier1 .. '_' ..device.identifier2
    device:start()

    self.devices[curIndex+1]=device

    self.indexMMF.Device[device.index].DeviceID = {device.id:byte(1,-1)}
    self.indexMMF.Device[device.index].MMFIdentifier1 = device.identifier1
    self.indexMMF.Device[device.index].MMFIdentifier2 = device.identifier2
    self.indexMMF.Device[device.index].DeviceInfo = {(''):byte(1,-1)}
    self.indexMMF.Device[device.index].Available = true
    return true
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

    if mouseClicked
        and ac.getSim().cameraPosition:closerToThan(targetMeshes:getWorldTransformationRaw().position ,2) 
        and (targetMeshes:raycast(render.createMouseRay(), hitsRef,nil,nil,hitsUV,0) ~= -1 ) then
            self.lastTouchDevice = hitsRef:getAttribute('DeviceIndex')
            self.devices[self.lastTouchDevice +1]:sendTouch(vec2(hitsUV.x,hitsUV.y+1),mouseClicked)
    else
        self.devices[self.lastTouchDevice +1]:sendTouch(vec2(0,0),mouseClicked)
    end

end

return DeviceManager