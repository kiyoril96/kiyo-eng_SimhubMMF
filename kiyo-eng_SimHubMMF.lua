require('src/MMFHeader')

local defaultConfigPath =  ac.getFolder(ac.FolderID.ScriptOrigin) .. '/config/default.ini'
local nodes = {}
local angle
local flip = false
local invert = false
local pos
local look
local orientation = {}
local Ref = ac.emptySceneReference()
local DDURef = ac.emptySceneReference()
local appInit = false
local carId 
local configDir = ac.getFolder(ac.FolderID.ScriptConfig)
local configPath
local config
function Initialize()

    carId = ac.getCarID(0)
    configPath = configDir .. '/' .. carId .. '.ini'

    if not io.dirExists(configDir) then
        io.createDir(configDir)
    end
    if not io.fileExists(configPath) then 
        local defaultConfig =  ac.INIConfig.load(defaultConfigPath,ac.INIFormat.Extended)
        defaultConfig:save(configPath)
    end


    config = ac.INIConfig.load(configPath,ac.INIFormat.Extended)
    for index, section in config:iterate('POS') do
        if section ~= 'GENERAL' then
            nodes[index] = config:get(section,'Node','COCKPIT_HR')
        end
    end
    ac.debug('nodes',nodes)
    angle = config:get('POS_0','Rotation',vec3(0,0,0))
    flip = config:get('POS_0','Flip',false)
    invert = config:get('POS_0','Invert',false)
    pos = config:get('POS_0','Position',vec3(0,0,0))
    look = vec3(0,0,(flip and -1 or 1)):rotate(quat.fromAngleAxis(angle.x,vec3(1,0,0))):rotate(quat.fromAngleAxis(angle.y,vec3(0,1,0))):rotate(quat.fromAngleAxis(angle.z,vec3(0,0,1)))
    Ref = ac.findNodes('carsRoot:yes')
    DDURef = Ref:findNodes('COCKPIT_HR'):createNode('DDU',false):loadKN5('./model/DDU_4inch/VirtualDDU.kn5')
    DDURef:setPosition(pos):setOrientation(look,vec3(0,(invert and -1 or 1),0))
    appInit = true
end

local deviceFamilyId = '8d297eae-fc40-4229-943c-0eba7402673c'
local deviceIndexMMFName = 'SimHubDashIndexV3' .. deviceFamilyId

local dashRenderMMFName = ''

local connectionStatus
local lastError = nil
---@class ui.GIFPlayer
local frameTexture
---@class ui.ExtraCanvas
local displayCanvas

local mappedDeviceIndex =nil
local mappedDashRender = nil

local width = 320
local height = 180

local lastFrame = -1

local DisplayConnected

local function notifyRequest()
    local command = "$event = New-Object System.Threading.EventWaitHandle($false, [System.Threading.EventResetMode]::ManualReset, 'Global\\SHMMFNotification'); $event.Set(); $event.Dispose()"
    os.runConsoleProcess({
        filename = 'powershell.exe',
        arguments = {'-NoProfile', '-NonInteractive', '-Command', command},
        timeout = 5000,
        terminateWithScript = true
    })
end

function StartDevice()

    if mappedDashRender then 
        mappedDashRender.RequestActive = false
        ac.disposeMemoryMappedFile(mappedDashRender) end
    if mappedDeviceIndex then 
        mappedDeviceIndex.AvailableDevice01.Available=false
        ac.disposeMemoryMappedFile(mappedDeviceIndex) end


    local mappedDevice = ac.writeMemoryMappedFile( deviceIndexMMFName, MMFDeviceIndex, true)

    mappedDeviceIndex = mappedDevice
    ac.debug('Index mmf name',deviceIndexMMFName)

    local identifier1 = math.random(1,2147483646)
    local identifier2 = math.random(1,2147483646)
    dashRenderMMFName = 'SimHubDashRenderV3' .. deviceFamilyId .. '_' .. identifier1 .. '_' ..identifier2

    mappedDeviceIndex.AvailableDevice01.DeviceID= {('KE-VirtualDisplay#01'):byte(1,-1)}
    mappedDeviceIndex.AvailableDevice01.MMFIdentifier1=identifier1
    mappedDeviceIndex.AvailableDevice01.MMFIdentifier2=identifier2
    mappedDeviceIndex.AvailableDevice01.DeviceInfo= {('test virtual display'):byte(1,-1)}
    mappedDeviceIndex.AvailableDevice01.Available=true

    return true
end

local read = 0
function StartRender()
    read =0
    ac.debug('Dash mmf name',dashRenderMMFName)
    local DashRender = ac.writeMemoryMappedFile(dashRenderMMFName, MMFHeaderV3, true)

    mappedDashRender = DashRender.mmfHeaderV3
    mappedDashRender.StructVersion = 3
    mappedDashRender.RequestedRenderHeightPixels = height
    mappedDashRender.RequestedRenderWidthPixels = width
    mappedDashRender.RequestDoubleBuffer = true
    mappedDashRender.EnableTouchTraces = false
    mappedDashRender.ReadTimeout = 2;
    mappedDashRender.Requester = {('Assettocrosa Lua App'):byte(1,-1)}
    mappedDashRender.RequestedTouchMode = MMFHeader.TouchMode.Unchanged
    mappedDashRender.RequestActive = true

    notifyRequest()

    frameTexture = ui.GIFPlayer({width = width, height = height}, false)
    if frameTexture then
        frameTexture.keepRunning = true
    end

    displayCanvas = ui.ExtraCanvas(vec2(width, height), 1, render.TextureFormat.R8G8B8A8.UNorm)
    displayCanvas:setName('test')
    connectionStatus = true
    lastError = nil
    return true
end

---@param point vec2
---@param pressed boolean
function UpdateteTouchPoint(point,pressed)
    if mappedDashRender ~= nil and mappedDashRender.SimHubConnected then
        mappedDashRender.Cursor4.CursorCoordinatesX = math.floor(point.x * width)
        mappedDashRender.Cursor4.CursorCoordinatesY = math.floor(point.y * height)
        mappedDashRender.Cursor4.CursorPressed = pressed
        
        ac.debug('floorX', math.floor(point.x * width))
        ac.debug('floorY',math.floor(point.y * height))
    end
end

local requestId = 0
---@param Action MMFHeader.Action
function EnqueAcction(Action)
    if mappedDashRender ~= nil and mappedDashRender.SimHubConnected then
        local command = {
            mappedDashRender.DisplayActionCommand1,
            mappedDashRender.DisplayActionCommand2,
            mappedDashRender.DisplayActionCommand3,
            mappedDashRender.DisplayActionCommand4
        }
        requestId = requestId + 1

        for i=1 , 4 do
            if not command[i].RequestActive then
                command[i].Action = Action
                command[i].RequestId = requestId
                command[i].RequestActive = true
                return
            end
        end
    end
end

local syncFailures = 0

local lastLedsWriteCount = -1
local LedsConnected =false
local lastLedsWrite 
local ledColors = {}
local ledsBrightness = 0
function UpdateLeds()
    if mappedDashRender == nil then
        return
    end

    if not mappedDashRender.SimHubConnected or mappedDashRender.LedsLastFilledBuffer == 0 then
        LedsConnected = false
        return
    end

    local curWriteCount = mappedDashRender.LedsWriteCount
    
    if lastLedsWriteCount == curWriteCount then
        return
    end

    LedsConnected = true
    lastLedsWriteCount = curWriteCount
    lastLedsWrite = os.time()

    local selectedBuffer = mappedDashRender.LedsLastFilledBuffer
    local ledsCount = mappedDashRender.WrittenLedsCount

    if mappedDashRender.LedsBufferCurrentlyWritten == selectedBuffer then
        syncFailures = syncFailures + 1
        return
    end

    local buf = (selectedBuffer == 1) 
        and mappedDashRender.LedsRenderBuffer1.Buffer
        or mappedDashRender.LedsRenderBuffer2.Buffer

    for i = 0,ledsCount -1 do
        ledColors[i+1] = rgbm.from0255(buf[i*3+0],buf[i*3+1],buf[i*3+2],1)
    end
    read = read+1
    mappedDashRender.ReadCount = read

    for i=1 ,#ledColors do
        DDURef:findMeshes('LED.'..string.format( "%03d", i ))
            :ensureUniqueMaterials():setMaterialTexture("txDiffuse",rgbm(0.2,0.2,0.2,0))
            :setMaterialProperty("ksEmissive",vec3(
                ledColors[i].r*1000
                ,ledColors[i].g*1000
                ,ledColors[i].b*1000
            ))
    end
    return
end


local lastDisplayWriteCount = -1
local lastDisplayWrite = -1
local wasDisplayFilled = false
local displayBrightness = 0
local clicked =false
function UpdateDisplay()
    if mappedDashRender == nil then
        return
    end

    if not mappedDashRender.SimHubConnected or mappedDashRender.DisplayLastFilledBuffer == 0 then
        DisplayConnected = false
        return
    end

    local curWriteCount = mappedDashRender.DisplayWriteCount
    
    if lastDisplayWriteCount == curWriteCount then
        return
    end

    DisplayConnected = true
    lastDisplayWriteCount = curWriteCount
    lastDisplayWrite = os.time()

    local selectedBuffer = mappedDashRender.DisplayLastFilledBuffer

    if mappedDashRender.DisplayBufferCurrentlyWritten == selectedBuffer then
        syncFailures = syncFailures + 1
        return
    end

    local buf = ffi.string( (selectedBuffer == 1) 
        and mappedDashRender.DisplayRenderBuffer1.Buffer 
        or mappedDashRender.DisplayRenderBuffer2.Buffer 
    , mappedDashRender.DisplayRenderedDataSize)

    displayBrightness = (mappedDashRender.DisplayBrightness /100) +2

    if frameTexture and displayCanvas then
        frameTexture:push( buf )
        displayCanvas:updateWithShader({
            textures = {txInput = frameTexture},
            shader = [[
                float4 main(PS_IN pin) {
                    float4 color = txInput.Sample(samLinear, pin.Tex);
                    return float4(color.b, color.g, color.r, color.a);
                }
            ]]
        })
        displayCanvas:update(function (dt)
            ui.dummy(vec2(width,height))
            if ui.itemClicked(ui.MouseButton.Left, false) then 
                ui.drawCircleFilled(ui.mouseLocalPos(),10,rgbm(1,1,1,1))
            end
        end)
        read = read+1
        mappedDashRender.ReadCount = read
        wasDisplayFilled = true -- レンダリングの状況確認用
        lastDisplayWrite = os.time() -- レンダリングの状況確認用

        DDURef:findMeshes('Display'):ensureUniqueMaterials()
            :setMaterialTexture("txDiffuse",displayCanvas)
            :setMaterialProperty("ksEmissive",vec3(displayBrightness,displayBrightness,displayBrightness))
    end
    return
end

local isDeviceSet = false
local isRendering = false

function SimUpdate()

    if not appInit then
        Initialize()
    end

    if appInit and not isRendering then
        isRendering= StartDevice()
        isRendering = StartRender()
    end

    if appInit and isRendering then 
        UpdateDisplay()
        UpdateLeds()

        if DDURef then 
            local targetMeshes = DDURef:findMeshes('Display')
            local ref = ac.emptySceneReference()
            local clickPos = vec3()
            local nomal = vec3()
            local uv = vec2()
            local sim = ac.getSim() 
            if sim.isWindowForeground
                and sim.cameraPosition:closerToThan(DDURef:getWorldTransformationRaw().position ,2)
                and ui.mouseClicked(ui.MouseButton.Left)
                and not ac.getUI().wantCaptureMouse
                and (targetMeshes:raycast(render.createMouseRay(), ref,clickPos,nomal,uv,0) ~= -1 )  then
                UpdateteTouchPoint(vec2(uv.x,uv.y+1),true)
            end
            if mappedDashRender.Cursor4.CursorPressed and ui.mouseReleased(ui.MouseButton.Left) then
                UpdateteTouchPoint(vec2(uv.x,uv.y+1),false)
            end

            ac.debug('pressed',mappedDashRender.Cursor4.CursorPressed)
            ac.debug('point',uv)
            ac.debug('pointX',mappedDashRender.Cursor4.CursorCoordinatesX)
            ac.debug('pointY',mappedDashRender.Cursor4.CursorCoordinatesY)
        end
    end

end

local attachto =1
local touchModeIndex = 1
function WindowMain()
    
    if isRendering then

        local ledSize = math.max((ui.availableSpaceX()/ #ledColors *0.3),3)
        local height = 20+(ledSize * 0.7)
        local offset = (ui.availableSpaceX()-(ledSize*2)) / (#ledColors) 
        for i=1 ,#ledColors do
            local p1 = vec2( (offset*i) -5 , height )
            ui.drawCircleFilled(p1,ledSize,ledColors[i],20)
            ui.drawCircle(p1,ledSize,rgbm(0,0,0,1),20,1)
            DDURef:findMeshes('LED.'..string.format( "%03d", i ))
                :ensureUniqueMaterials():setMaterialTexture("txDiffuse",rgbm(0.2,0.2,0.2,0))
                :setMaterialProperty("ksEmissive",vec3(
                    ledColors[i].r*1000
                    ,ledColors[i].g*1000
                    ,ledColors[i].b*1000
                ))
        end

        if displayCanvas then 
            ui.offsetCursor(vec2(0,height*2))
            local rato = displayCanvas:size().y/displayCanvas:size().x
            local size = vec2( ui.availableSpaceX(), ui.availableSpaceX()*rato )
            ui.image(displayCanvas,size,ui.ImageFit.Stretch)
            local cursory = ui.getCursorY() - size.y
            if ui.itemClicked(ui.MouseButton.Left, false) then 
                local offsetMoucepos = ui.mouseLocalPos()-vec2(0,cursory)
                local clickedAt =  vec2( (offsetMoucepos.x/size.x), (offsetMoucepos.y/size.y))
                UpdateteTouchPoint(clickedAt,true)
            end

            if ui.itemClicked(ui.MouseButton.Left, true) then 
                local offsetMoucepos = ui.mouseLocalPos()-vec2(0,cursory)
                local clickedAt =  vec2( (offsetMoucepos.x/size.x), (offsetMoucepos.y/size.y))
                UpdateteTouchPoint(clickedAt,false)
            end
        end

        if mappedDashRender then
            ac.debug('mmf001 StructVersion', mappedDashRender.StructVersion)
            ac.debug('mmf002 RequestActive', mappedDashRender.RequestActive)
            ac.debug('mmf003 SimHubConnected', mappedDashRender.SimHubConnected)
            ac.debug('mmf004 ReadCount', mappedDashRender.ReadCount)
        end

    end

    if ui.button('<##prev',vec2(20,20),ui.ButtonFlags.PressedOnClickRelease) then EnqueAcction(MMFHeader.Action.PreviousScreen) end
    ui.sameLine()
    if ui.button('F##First',vec2(20,20),ui.ButtonFlags.PressedOnClickRelease) then EnqueAcction(MMFHeader.Action.FirstScreen) end
    ui.sameLine()
    if ui.button('>##next',vec2(20,20),ui.ButtonFlags.PressedOnClickRelease) then EnqueAcction(MMFHeader.Action.NextScreen) end
    ui.sameLine()
    if ui.button('A##A',vec2(20,20),ui.ButtonFlags.PressedOnClickRelease) then EnqueAcction(MMFHeader.Action.ActionA) end
    ui.sameLine()
    if ui.button('B##B',vec2(20,20),ui.ButtonFlags.PressedOnClickRelease) then EnqueAcction(MMFHeader.Action.ActionB) end
    ui.sameLine()
    if ui.button('C##C',vec2(20,20),ui.ButtonFlags.PressedOnClickRelease) then EnqueAcction(MMFHeader.Action.ActionC) end
    ui.sameLine()
    if ui.button('D##D',vec2(20,20),ui.ButtonFlags.PressedOnClickRelease) then EnqueAcction(MMFHeader.Action.ActionD) end

    ui.text('Attach to')
    local attach, changed = ui.combo("##attachNode",attachto,ui.ComboFlags.HeightLargest,nodes)
    if changed then
        attachto = attach
        config:setAndSave('GENERAL','AttachTo',attach)
        if DDURef then DDURef:dispose() end

        DDURef = Ref:findNodes(config:get('POS_'..attachto-1,'Node','COCKPIT_HR')):createNode('DDU',false):loadKN5('./model/DDU_4inch/VirtualDDU.kn5')

        angle = config:get('POS_'..attachto-1,'Rotation',vec3(0,0,0))
        flip = config:get('POS_'..attachto-1,'Flip',false)
        invert = config:get('POS_'..attachto-1,'Invert',false)
        pos = config:get('POS_'..attachto-1,'Position',vec3(0,0,0))
        look = vec3(0,0,(flip and -1 or 1))
            :rotate(quat.fromAngleAxis(math.rad(angle.x),vec3(1,0,0)))
            :rotate(quat.fromAngleAxis(math.rad(angle.y),vec3(0,1,0)))
        Ref = ac.findNodes('carsRoot:yes')
        DDURef:setPosition(pos):setOrientation(look,vec3(0,(invert and -1 or 1),0):rotate(quat.fromAngleAxis(math.rad(angle.z),vec3(0,0,1))))
    end

    ui.text('X:')
    ui.sameLine()
    ui.setNextItemWidth(200)
    local valx,changedx = ui.slider('##posX',pos.x,-2,2,'%.04f')
    if changedx then 
        pos.x = valx
    end
    if ui.itemClicked(ui.MouseButton.Right,false) then 
        changedx =true
        pos.x = 0
    end
    ui.sameLine()
    ui.setNextItemWidth(100)
    local valrx,changedrx = ui.slider('##rotX',angle.x,-90,90,'%.01f')
    if changedrx then 
        angle.x = valrx
    end
    if ui.itemClicked(ui.MouseButton.Right,false) then 
        changedrx =true
        angle.x = 0
    end
 
    ui.text('Y:')
    ui.sameLine()
    ui.setNextItemWidth(200)
    local valy,changedy = ui.slider('##posY',pos.y,-2,2,'%.04f')
    if changedy then 
        pos.y = valy
    end
    if ui.itemClicked(ui.MouseButton.Right,false) then 
        changedy =true
        pos.y = 0
    end
    ui.sameLine()
    ui.setNextItemWidth(100)
    local valry,changedry = ui.slider('##rotY',angle.y,-90,90,'%.01f')
    if changedry then 
        angle.y = valry
    end
    if ui.itemClicked(ui.MouseButton.Right,false) then 
        changedry =true
        angle.y = 0
    end

    ui.text('Z:')
    ui.sameLine()
    ui.setNextItemWidth(200)
    local valz,changedz = ui.slider('##posZ',pos.z,-2,2,'%.04f')
    if changedz then 
        pos.z = valz
    end
    if ui.itemClicked(ui.MouseButton.Right,false) then 
        changedz =true
        pos.z = 0
    end
    ui.sameLine()
    ui.setNextItemWidth(100)
    local valrz,changedrz = ui.slider('##rotZ',angle.z,-90,90,'%.01f')
    if changedrz then 
        angle.z = valrz
    end
    if ui.itemClicked(ui.MouseButton.Right,false) then 
        changedrz =true
        angle.z = 0
    end


    local changeflip =false
    if ui.checkbox('Flip',flip) then
        changeflip = true
        flip = not flip
    end
    ui.sameLine()
    local changeInvert =false
    if ui.checkbox('Invert',invert) then
        changeInvert = true
        invert = not invert
    end


    if changedx or changedy or changedz then
        DDURef:setPosition(pos)
        config:set('POS_'..attachto-1,'Position',pos)
        config:save()
    end
    if changedrx or changedry or changedrz or changeflip or changeInvert then

        look = vec3(0,0,(flip and -1 or 1))
            :rotate(quat.fromAngleAxis(math.rad(angle.x),vec3(1,0,0)))
            :rotate(quat.fromAngleAxis(math.rad(angle.y),vec3(0,1,0)))

        DDURef:setOrientation(look,vec3(0,(invert and -1 or 1),0):rotate(quat.fromAngleAxis(math.rad(angle.z),vec3(0,0,1))) )

        config:set('POS_'..attachto-1,'Rotation',angle)
        config:set('POS_'..attachto-1,'Flip',flip)
        config:set('POS_'..attachto-1,'Invert',invert)
        config:save()
    end

    ac.debug('attachto',attachto)
    ac.debug('ddu',DDURef)
end