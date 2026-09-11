-- とりあえずモデルとデバイスを１個読み込んでSimhubを表示することろまで作る
-- そのあと保存の方法を考える （デバイスごと？車ごと？モデルごと？）
-- そして複数モデル・デバイス読み込みに対応する
-- その保存方法を考える

local ModelManager = require('src/ModelManager')
local DeviceManager = require('src/DeviceManager')
local Device = require('src/Device')

local appInit = false

local carId
local configPath
local config
local nodes = {}

local deviceFamilyId = '8d297eae-fc40-4229-943c-0eba7402673c'
local deviceID = 'KE-VDisp'

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

    local configVersion = config:get('GENERAL','version',0)

    if configVersion >= 2 then
        --再生成
        local defaultConfigPath = ac.getFolder(ac.FolderID.ScriptOrigin) .. '/config/default.ini'
        local defaultConfig =  ac.INIConfig.load(defaultConfigPath,ac.INIFormat.Extended)
        defaultConfig:save(configPath)
    end

    for index, section in config:iterate('POS') do
        if section ~= 'GENERAL' then
            nodes[index] = config:get(section,'Node','COCKPIT_HR')
        end
    end

    -- デバイス（SimhubMMFの初期化）
    devMnger = DeviceManager.new(deviceFamilyId):start()
    -- デバイスをとりあえず１台
    devMnger:add( Device.new( deviceID,160,90,MMF.TouchMode.ForceLeftRight ) )
    -- ２台以降
    devMnger:add( Device.new( deviceID,320,200,MMF.TouchMode.ForceAdvanced ) )

    -- モデル定義の初期化
    local modelid = 'DDU_4inch'
    --local modelid = 'tablet'
    modelMnger = ModelManager.new()

    modelMnger:setup(config)
    modelMnger:addModel(modelid)
    --modelMnger:addModel('ringLed','STEER_HR')

    modelMnger.models[1].flip = false
    modelMnger.models[1]:setPosition(vec3(0.2,0.25,-0.15))
    modelMnger.models[1]:setRotation(vec3(0,0,0))
    
    devMnger.devices[1]:setTexture()

    modelMnger.models[1]:setDisplayTexture(devMnger.devices[1])
    modelMnger.models[1]:setLedUpdater(devMnger.devices[1])

    modelMnger:addModel('tablet')

    modelMnger.models[2].flip = false
    modelMnger.models[2]:setPosition(vec3(0,0.25,-0.15))
    modelMnger.models[2]:setRotation(vec3(0,0,0))
    
    devMnger.devices[2]:setTexture()
    
    modelMnger.models[2]:setDisplayTexture(devMnger.devices[2])
    modelMnger.models[2]:setLedUpdater(devMnger.devices[2])

    modelMnger:addModel('ringLed','STEER_HR')

    modelMnger.models[3].flip = false
    modelMnger.models[3]:setPosition(vec3(0,0,0))
    modelMnger.models[3]:setRotation(vec3(0,0,0))
    
    modelMnger.models[3]:setDisplayTexture(devMnger.devices[2])
    modelMnger.models[3]:setLedUpdater(devMnger.devices[2])


    appInit = true
end

function SimUpdate()

    if not appInit then
        Initialize()
    end

    if appInit then
        devMnger:update()

        if ac.getSim().isWindowForeground 
            and (ui.mouseClicked(ui.MouseButton.Left) or ui.mouseReleased(ui.MouseButton.Left))
            and not ac.getUI().wantCaptureMouse then
            devMnger:checkTouchPoint(ui.mouseClicked(ui.MouseButton.Left))
        end
    end

ac.debug('testTouch',devMnger.devices[1].mmf.Cursor4.CursorPressed )
end


local modelidlistIndex = 1
local resolutions = {vec2(160,90) ,vec2(320,180) ,vec2(160,100) , vec2(320,200) ,vec2(800,600) ,vec2( 400,640)}
local resolutionStr = {'160x90' ,'320x180' ,'160x100' , '320x200' ,'800x600' ,' 400x640'}
local resIndex = 1
function WindowMain()

    
    local index, changed = ui.combo("##model",modelidlistIndex,ui.ComboFlags.HeightLargest,modelMnger.modelIdList)
    if changed then
        
        modelMnger:changeModel( modelMnger.modelIdList[modelidlistIndex]..1 
            , modelMnger.modelDefinitions[modelMnger.modelIdList[index]] ,ui.ButtonFlags.PressedOnClickRelease)
        modelidlistIndex = index
    end

    local res, changed = ui.combo("##res",resIndex,ui.ComboFlags.HeightLargest,resolutionStr)
    if changed then
        
        devMnger.devices[1]:setTexture(resolutions[res])
        resIndex = res
    end

end