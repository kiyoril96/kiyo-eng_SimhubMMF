-- クルマ・モデル・取付位置の単位でセクションを持ったコンフィグの定義
-- モデル操作ポップアップが閉じた瞬間にコンフィグを保存するように（そのほかは操作した瞬間）
-- 起動時の読み込み ⇒ 保存したコンフィグからデバイス・モデル情報を復元（デバイス情報はどこに保存するか）

local ModelManager = require('src/ModelManager')
local DeviceManager = require('src/DeviceManager')

local appInit = false

local carId
local configPath
local config

local deviceFamilyId = '8d297eae-fc40-4229-943c-0eba7402673c'

local modelMnger

local devMnger

function Initialize()

    -- 車ごとのコンフィグを読み込み
    -- ファイルが無ければ生成
    local configDir = ac.getFolder(ac.FolderID.ScriptConfig)
    carId = ac.getCarID(0)
    configPath = configDir .. '/' .. carId .. '.ini'

    if not io.dirExists(configDir) then
        io.createDir(configDir)
    end
    if not io.fileExists(configPath) then 
        local defaultConfigPath = ac.getFolder(ac.FolderID.ScriptOrigin) .. '/config/default.ini'
        local defaultConfig =  ac.INIConfig.load(defaultConfigPath,ac.INIFormat.Extended)
        defaultConfig:save(configPath)
    end

    config = ac.INIConfig.load(configPath,ac.INIFormat.Extended)

    local configVersion = config:get('GENERAL','Version',0)

    if configVersion < 2 then
        --再生成
        config=nil
        local defaultConfigPath = ac.getFolder(ac.FolderID.ScriptOrigin) .. '/config/default.ini'
        local defaultConfig =  ac.INIConfig.load(defaultConfigPath,ac.INIFormat.Extended)
        defaultConfig:save(configPath)
    end

    config = ac.INIConfig.load(configPath,ac.INIFormat.Extended)

    -- デバイス（SimhubMMFの初期化）
    devMnger = DeviceManager.new(deviceFamilyId):start()
    devMnger:setup(config)

    modelMnger = ModelManager.new()
    modelMnger:setup(config,devMnger)

    appInit = true
end

function SimUpdate()

    if not appInit then
        Initialize()
    end

    if appInit and #devMnger.devices~=0 then
        devMnger:update()

        if ac.getSim().isWindowForeground 
            and (ui.mouseClicked(ui.MouseButton.Left) or ui.mouseReleased(ui.MouseButton.Left))
            and not ac.getUI().wantCaptureMouse then
            devMnger:checkTouchPoint(ui.mouseClicked(ui.MouseButton.Left))
        end
    end
end

function WindowMain()

    ui.tabBar('###mainWindowTab', function ()
      ui.tabItem('Device', function () DeviceList() end )
      ui.tabItem('Model', function () ModelList() end)
      ui.tabItem('Settings', function () Setting() end)
    end)

end

function PopOutLEDWindow(device)
    device.ledWindowOpen = true
    ui.popup(function() 
        local ledSize = math.max((ui.availableSpaceX()/ #device.ledColors *0.3),3)
        local height = 30+(ledSize * 0.7)
        local offset = (ui.availableSpaceX()-(ledSize*2)) / (#device.ledColors) 
        for i=1 ,#device.ledColors do
            local p1 = vec2( (offset*i) -5 , height )
            ui.drawCircleFilled(p1,ledSize,device.ledColors[i],20)
            ui.drawCircle(p1,ledSize,rgbm(0,0,0,1),20,1)
        end
    end, {onClose=function () device.ledWindowOpen = false end,title='LED'..device.id,size={initial=vec2(20*#device.ledColors,60)},padding=vec2(0,0)})
end

-- なぜか？タッチできない
function PopOutDisplayWindow(device)
    device.displayWindowOpen = true
    ui.popup(function() 
        local rato = device.displayCanvas:size().y/device.displayCanvas:size().x
        local size = vec2( ui.availableSpaceX(), ui.availableSpaceX()*rato )
        ui.image(device.displayCanvas,size,ui.ImageFit.Stretch)
        local cursory = ui.getCursorY() - size.y
        if ui.itemClicked(ui.MouseButton.Left, false) then 
            local offsetMoucepos = ui.mouseLocalPos()-vec2(0,cursory)
            local clickedAt =  vec2( (offsetMoucepos.x/size.x), (offsetMoucepos.y/size.y))
            device:sendTouch(clickedAt,true)
        end
        if ui.itemClicked(ui.MouseButton.Left, true) then 
            local offsetMoucepos = ui.mouseLocalPos()-vec2(0,cursory)
            local clickedAt =  vec2( (offsetMoucepos.x/size.x), (offsetMoucepos.y/size.y))
            device:sendTouch(clickedAt,false)
        end
    end, {onClose=function () device.displayWindowOpen = false end,title='Display'..device.id,size={initial=vec2(320,220)},padding=vec2(0,0)})
end

function DeviceList()
    local windwoSize = ui.availableSpace()
    if devMnger.devices then
        for i,device in ipairs(devMnger.devices) do
            ui.childWindow('###'..device.id , vec2(windwoSize.x,40), true, ui.WindowFlags.NoScrollbar, function()
                --ui.drawImage(device.displayCanvas,vec2(0,0),vec2(90,70),ui.ImageFit.Fit)
                ui.drawTextClipped(device.id,vec2(10,10),vec2(170,30))
                ui.drawTextClipped('Resolution: '..device.width..'x'..device.height,vec2(100,10),vec2(300,30))
                ui.sameLine()
                ui.offsetCursor(vec2(230,0))
                local res, changed = ui.combo('##res'..device.id..i,device.resolutionIndex,ui.ComboFlags.NoPreview,devMnger.resolutions.strs)
                if changed then
                    device:setTexture(devMnger.resolutions.size[res])
                    device.resolutionIndex = res
                end
                ui.sameLine()
                ui.offsetCursorX(ui.availableSpaceX()-160)
                if ui.button('LED###'..device.id..'leds'..i) and not device.ledWindowOpen then PopOutLEDWindow(device) end
                ui.sameLine()
                if ui.button('Display###'..device.id..'displays'..i) and not device.displayWindowOpen  then PopOutDisplayWindow(device) end

                ui.sameLine()
                if ui.button('Delete###'..device.id..'delete') then 
                    devMnger:remove(i)
                end
            end)
        end
        ui.offsetCursor(vec2((ui.availableSpaceX()/2)-50,20))
        if #devMnger.devices < 10 then 
            if ui.button('Add###addModel',vec2(100,30)) then 
                devMnger:add(160,90)
            end
        end
    end
end

function ModelControllWindowClose(model)
    modelMnger.controllerWindowOpen = false
    model:setAndSave()
end

function ModelControllWindow(model)
    if model then 
        modelMnger.controllerWindowOpen = true
        ui.popup(function()

            ui.offsetCursorX(ui.availableSpaceX()-100)
            if ui.button('Flip###Flip') then model:setFlip() end
            ui.sameLine()
            if ui.button('Invert###Invert') then model:setInvert() end

            ui.text('X:')
            ui.sameLine()
            ui.setNextItemWidth(200)
            local valx,changedx = ui.slider('##posX',model.points[model.attach].position.x,-2,2,'%.04f')
            if changedx then 
                model.points[model.attach].position.x = valx
            end
            if ui.itemClicked(ui.MouseButton.Right,false) then 
                changedx =true
                model.points[model.attach].position.x = 0
            end
            ui.sameLine()
            ui.setNextItemWidth(100)
            local valrx,changedrx = ui.slider('##rotX',model.points[model.attach].rotation.x,-90,90,'%.01f')
            if changedrx then 
                model.points[model.attach].rotation.x = valrx
            end
            if ui.itemClicked(ui.MouseButton.Right,false) then 
                changedrx =true
                model.points[model.attach].rotation.x = 0
            end
        
            ui.text('Y:')
            ui.sameLine()
            ui.setNextItemWidth(200)
            local valy,changedy = ui.slider('##posY',model.points[model.attach].position.y,-2,2,'%.04f')
            if changedy then 
                model.points[model.attach].position.y = valy
            end
            if ui.itemClicked(ui.MouseButton.Right,false) then 
                changedy =true
                model.points[model.attach].position.y = 0
            end
            ui.sameLine()
            ui.setNextItemWidth(100)
            local valry,changedry = ui.slider('##rotY',model.points[model.attach].rotation.y,-90,90,'%.01f')
            if changedry then 
                model.points[model.attach].rotation.y = valry
            end
            if ui.itemClicked(ui.MouseButton.Right,false) then 
                changedry =true
                model.points[model.attach].rotation.y = 0
            end

            ui.text('Z:')
            ui.sameLine()
            ui.setNextItemWidth(200)
            local valz,changedz = ui.slider('##posZ',model.points[model.attach].position.z,-2,2,'%.04f')
            if changedz then 
                model.points[model.attach].position.z = valz
            end
            if ui.itemClicked(ui.MouseButton.Right,false) then 
                changedz =true
                model.points[model.attach].position.z = 0
            end
            ui.sameLine()
            ui.setNextItemWidth(100)
            local valrz,changedrz = ui.slider('##rotZ',model.points[model.attach].rotation.z,-90,90,'%.01f')
            if changedrz then 
                model.points[model.attach].rotation.z = valrz
            end
            if ui.itemClicked(ui.MouseButton.Right,false) then 
                changedrz =true
                model.points[model.attach].rotation.z = 0
            end

            if changedx or changedy or changedz then
                model:setPosition()
            end
            if changedrx or changedry or changedrz then
                model:setRotation()
            end

        end, {onClose=function () ModelControllWindowClose(model) end,size={initial=vec2(320,220)}})
    end
end

function ModelList()
    local windwoSize = ui.availableSpace()
    if modelMnger.models then
        for i,model in ipairs(modelMnger.models) do
            ui.childWindow('###'..model.definition.modelID..i,vec2(windwoSize.x,75),true, ui.WindowFlags.NoScrollbar, function()
                ui.drawTextClipped('#'..i..': ',vec2(10,10),vec2(170,30))
                ui.drawTextClipped(model.definition.modelID,vec2(40,10),vec2(200,80))
                ui.offsetCursor(vec2(130,0))
                local modelIdIndex, changed = ui.combo('##modeldef'..model.definition.modelID..i,model.definition.index,ui.ComboFlags.NoPreview,modelMnger.modelIdList)
                if changed then
                    model.definition.index = modelIdIndex
                    model:changeDefinition(modelMnger.modelDefinitions[modelMnger.modelIdList[modelIdIndex]] )
                end
                ui.sameLine()
                ui.drawTextClipped('Device: '..model.device.id,vec2(200,10),vec2(350,80))
                ui.offsetCursor(vec2(160,0))
                local device, changed = ui.combo('##device'..model.definition.modelID..i,model.device.index+1,ui.ComboFlags.NoPreview,devMnger.deviceStr)
                if changed then
                    model:setDevice(devMnger.devices[device])
                    model:reload()
                end

                ui.offsetCursor(vec2(ui.availableSpaceX()-70,-20))
                if ui.button('Controler###') then 
                    if modelMnger.controllerWindowOpen then ui.closePopup() end
                        ModelControllWindow(model)
                end

                ui.drawTextClipped('Attach: '..model.attach,vec2(10,40),vec2(200,80))
                ui.offsetCursor(vec2(130,0))
                local attach, changed = ui.combo('##attach'..model.definition.modelID..i,model.attachIndex,ui.ComboFlags.NoPreview,modelMnger.nodes)
                if changed then
                    model.attachIndex = attach
                    model:reload(modelMnger.nodes[attach])
                end
                ui.sameLine()
                ui.offsetCursorX(ui.availableSpaceX()-70)
                if ui.button('  Delete  ###'..model.definition.modelID..i..'delete') then 
                    modelMnger:deleteModel(i)
                end
            end)
        end
        ui.offsetCursor(vec2((ui.availableSpaceX()/2)-50,20))
        if #devMnger.devices > 0 then 
            if ui.button('Add###addModel',vec2(100,30)) then 
                local newIndex = modelMnger:addModel(modelMnger.modelIdList[1])
                modelMnger.models[newIndex]:setDevice(devMnger.devices[1])
            end
        end
    end
end

function Setting()
    ui.text('Nothing yet.')
end