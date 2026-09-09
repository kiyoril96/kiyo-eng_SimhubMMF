local LEDs = require('src/Leds')
local Display = require('src/Display')

local function notifyRequest()
    local command = "$event = New-Object System.Threading.EventWaitHandle($false, [System.Threading.EventResetMode]::ManualReset, 'Global\\SHMMFNotification'); $event.Set(); $event.Dispose()"
    os.runConsoleProcess({
        filename = 'powershell.exe',
        arguments = {'-NoProfile', '-NonInteractive', '-Command', command},
        timeout = 5000,
        terminateWithScript = true
    })
end

local Device = {}

---@class Device
---@param DeviceID string
---@param width integer
---@param height integer
---@param touchMode? MMF.TouchMode
---@param touchTraces? boolean
function Device.new(DeviceID, width, height,touchMode,touchTraces)
    local self = {
        index = -1,
        id = DeviceID,
        width = width,
        height = height,
        identifier1 = math.random(1, 2147483646),
        identifier2 = math.random(1, 2147483646),
        mmfName = nil,
        mmf = nil,
        frameTexture = nil,
        displayCanvas = nil,
        ledColors = {},
        touchMode = touchMode and touchMode or MMF.TouchMode.Unchanged,
        touchTraces = touchTraces and touchTraces or false,
        requestId = 0
    }

    return setmetatable(self, { __index = Device })
end

function Device:start()

    if self.index == -1 and self.mmfName then 
        ac.log('KE-SimHubMMF: Device '..self.id..': Device is not registed')
        return 
    end

    if not self.mmf then
        self.mmf = ac.writeMemoryMappedFile(self.mmfName, MMF.Header, true)
        self.mmf.StructVersion = 3
        self.mmf.RequestedRenderHeightPixels = self.height
        self.mmf.RequestedRenderWidthPixels = self.width
        self.mmf.RequestDoubleBuffer = true
        self.mmf.EnableTouchTraces = self.touchTraces
        self.mmf.ReadTimeout = 2
        self.mmf.Requester = {('Assettocrosa Lua App'):byte(1,-1)}
        self.mmf.RequestedTouchMode = self.touchMode
    end

    self.mmf.RequestActive = true

    notifyRequest()

    ac.log('KE-SimHubMMF: Device '..self.id..': Start data request')
end

function Device:stop()
    if self.mmf then
        ac.log('KE-SimHubMMF: Device '..self.id..': Stop data request')
        self.mmf.RequestActive = false
    else
        ac.log('KE-SimHubMMF: Device '..self.id..': not Available')
    end
end

---@param ignourLed boolean
---@param ignourDisplay boolean
function Device:update(ignourLed,ignourDisplay)
    if not ignourLed then
        self:updateLeds()
    end
    if not ignourDisplay then
        self:updateDisplay()
    end
    if self.mmf then
        self.mmf.ReadCount = self.mmf.ReadCount + 1
    end
end

function Device:updateDisplay()
    Display:update(self)
end

function Device:updateLeds()
    LEDs:update(self)
end

---@param point vec2
---@param press boolean
function Device:sendTouch(point,press)
    if self.mmf ~= nil and self.mmf.SimHubConnected then
        self.mmf.Cursor4.CursorCoordinatesX = math.floor(point.x * self.width)
        self.mmf.Cursor4.CursorCoordinatesY = math.floor(point.y * self.height)
        self.mmf.Cursor4.CursorPressed = press
        
        ac.debug('Device '..self.id..': Touch Point', math.floor(point.x * self.width))
        ac.debug('Device '..self.id..': Touch Point', math.floor(point.y * self.height))
    end
end

---@param Action MMF.Action
function Device:enqueAcction(Action)
    if self.mmf ~= nil and self.mmf.SimHubConnected then
        local command = {
            self.mmf.DisplayActionCommand1,
            self.mmf.DisplayActionCommand2,
            self.mmf.DisplayActionCommand3,
            self.mmf.DisplayActionCommand4
        }
        self.requestId = self.requestId + 1

        for i=1 , 4 do
            if not command[i].RequestActive then
                command[i].Action = Action
                command[i].RequestId = self.requestId
                command[i].RequestActive = true
                return
            end
        end
    end
end

return Device