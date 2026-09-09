local curDir = ac.getFolder(ac.FolderID.ScriptOrigin)
local ModelDefinition ={}

function ModelDefinition.new(modelID)

    local configPath = curDir..'./model/'..modelID..'/model.ini'
    if not io.fileExists(configPath) then 
        ac.log('KE-SimHubMMF: Model: model.ini is not found')
        return
    end
    local config = ac.INIConfig.load(configPath)
    local modelName = config:get('MODEL','name','model.kn5')

    local self = {
        modelID = modelID,
        modelName = modelName,
        path = curDir..'./model/'..modelID..'/'..modelName,
        displayEnable = config:get('DISPLAY','display',0),
        displayMesh = config:get('DISPLAY','mesh','Display'),
        DefaultDisplayWidth = config:get('DISPLAY','width',320),
        DefaultDisplayHeight = config:get('DISPLAY','height',180),
        ledsEnable = config:get('LED','led',0),
        ledMesh = config:get('LED','mesh','LED'),
        instanceCount = 0
    }
    return setmetatable(self, { __index = ModelDefinition })
end

return ModelDefinition