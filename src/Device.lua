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

---@class Device
---@field index integer
---@field id string
---@field width integer
---@field height integer
---@field identifier1 integer
---@field identifier2 integer
---@field mmfName string --Render MMF の名前 
---@field mmf table --Render MMF 本体 MMFHeaderV3 を参照
---@field frameTexture ui.GIFPlayer --MMFからデータを流し込む RGBフォーマットがそろわないので要変換
---@field displayCanvas ui.ExtraCanvas -- Simhubダッシュボードのテクスチャ 色変換済み
---@field displayMeshes ac.SceneReference
---@field ledColors rgbm[]
---@field ledMeshes ac.SceneReference
---@field touchMode MMF.TouchMode
---@field touchTraces boolean
---@field requestId integer -- アクションコマンドを送信するときのID
---@field lastDisplayBrightnessess integer
---@field ledWindowOpen boolean
---@field displayWindowOpen boolean
---@field resolutionIndex integer
---@field config ac.INIConfig
local Device = {}

-- MMF.TouchMode.Unchanged は MMF生成後に変更しても意味ない？ようなのでSimhub側から操作する想定にする
-- ⇒ 基本はUnchangedで良い
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
        displayMeshes = ac.emptySceneReference(),
        ledColors = {},
        ledMeshes = ac.emptySceneReference(),
        touchMode = touchMode and touchMode or MMF.TouchMode.Unchanged,
        touchTraces = touchTraces and touchTraces or false,
        requestId = 0,
        lastDisplayBrightnessess =0,
        ledWindowOpen = false,
        displayWindowOpen = false,
        resolutionIndex = 1,
        config =nil
    }


    return setmetatable(self, { __index = Device })
end

function Device:start()

    if self.index == -1 and self.mmfName then 
        ac.log('KE-SimHubMMF: Device '..self.id..': Device is not registed')
        return 
    end

    if not self.mmf then
        local mmf = ac.writeMemoryMappedFile(self.mmfName, MMF.Header, true)
        self.mmf = mmf.device
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
        self.mmf=nil
    else
        ac.log('KE-SimHubMMF: Device '..self.id..': not Available')
    end
end

---@param ignourLed? boolean
---@param ignourDisplay? boolean
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

---@param size? vec2
function Device:setTexture(size)
    if size then 
        self.width = size.x
        self.height = size.y
    end

    local newSize = nil
    if self.width ~= 0 or self.height ~= 0 then newSize = vec2(self.width,self.height) end

    if self.displayCanvas ~= nil  and newSize  ~= nil then self.displayCanvas:dispose() end
    if self.frameTexture ~= nil and newSize  ~= nil then self.frameTexture = nil end

    if newSize then
        
        if self.mmf then
            self.mmf.RequestActive = false
            self.mmf.RequestedRenderWidthPixels = newSize.x
            self.mmf.RequestedRenderHeightPixels = newSize.y
            ac.log('KE-SimHubMMF: Device '..self.id..': Request Change resolution')
        end

        self.frameTexture = ui.GIFPlayer({width = newSize.x, height = newSize.y})
        self.frameTexture.keepRunning = true
        self.displayCanvas = ui.ExtraCanvas(newSize,1,render.TextureFormat.R8G8B8A8.UNorm)
        
        if self.mmf then
            self.mmf.RequestActive = true
            ac.log('KE-SimHubMMF: Device '..self.id..': Restart data request')
        end

        -- 解像度変更後にも参照を切れないようにする
        self.displayMeshes
            :ensureUniqueMaterials()
            :setMaterialTexture("txDiffuse", self.displayCanvas)
    end

    self:setAndSave()
end

function Device:setDisplayMeshes(ref)
    self.displayMeshes:append(ref)
    self.displayMeshes
        :ensureUniqueMaterials()
        :setMaterialTexture("txDiffuse", self.displayCanvas)
end

function Device:setLedMeshes(ref)
    self.ledMeshes:append(ref)
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

function Device:setAndSave()
    if self.config then
    self.config:set('DEVICE_'..(self.index),'Resolution',vec2(self.width,self.height))
    self.config:save()
    end
end

return Device