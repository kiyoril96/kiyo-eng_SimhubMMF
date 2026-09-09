require('src/MMFHeader')

local DeviceManager = {
    deviceFamilyId = '',
    indexMMFname = '',
    devices = {},
    indexMMF = nil
}

function DeviceManager.new(deviceFamilyId)
    local self = {
        deviceFamilyId = deviceFamilyId ,
        indexMMFname = 'SimHubDashIndexV3' .. deviceFamilyId ,
        devices = {},
    }

    return setmetatable(self, { __index = DeviceManager })
end

function DeviceManager:add(device)
    local curIndex = #self.devices
    if curIndex >= 10 then
        ac.log('KE-SimHubMMF: DeviceManager: Device entry is Full')
        return nil
    end
    device.index = curIndex
    device.mmfName = 'SimHubDashRenderV3' .. self.deviceFamilyId .. '_' .. device.identifier1 .. '_' ..device.identifier2
    self.indexMMF[curIndex].DeviceID = {((device.id and device.id or 'KE-VirtualDisplay')..'#'..curIndex+1):byte(1,-1)}
    self.indexMMF[curIndex].MMFIdentifier1 = device.identifier1
    self.indexMMF[curIndex].MMFIdentifier2 = device.identifier2
    self.indexMMF[curIndex].DeviceInfo = {(''):byte(1,-1)}
    self.indexMMF[curIndex].Available = true
    table.insert(self.devices,curIndex+1,device)
    return device
end

function DeviceManager:update()
    for _, device in ipairs(self.devices) do
        device:update()
    end
end

function DeviceManager:start()
    self.indexMMF = ac.writeMemoryMappedFile(
        self.indexMMFname,
        MMF.DeviceIndex,
        true
    )
end

return DeviceManager