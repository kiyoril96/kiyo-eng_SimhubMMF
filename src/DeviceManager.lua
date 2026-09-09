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

return DeviceManager