local curDir = ac.getFolder(ac.FolderID.ScriptOrigin)

---@class ModelDefinition
---@field modelID string
---@field modelName string 
---@field path string
---@field displayEnable boolean
---@field displayMesh string
---@field DefaultDisplayWidth integer
---@field DefaultDisplayHeight integer
---@field ledsCount integer
---@field ledMesh string
local ModelDefinition ={}

function ModelDefinition.new(modelID)

    local configPath = curDir..'/model/'..modelID..'/model.ini'
    if not io.fileExists(configPath) then 
        ac.log('KE-SimHubMMF: Model: model.ini is not found')
        return
    end
    local config = ac.INIConfig.load(configPath,ac.INIFormat.Extended)
    local modelName = config:get('MODEL','name','model.kn5')

    local self = {
        modelID = modelID,
        modelName = modelName,
        path = curDir..'/model/'..modelID..'/'..modelName,
        displayEnable = config:get('DISPLAY','display',0),
        displayMesh = config:get('DISPLAY','mesh','Display'),
        DefaultDisplayWidth = config:get('DISPLAY','width',320),
        DefaultDisplayHeight = config:get('DISPLAY','height',180),
        ledsCount = config:get('LED','led',0),
        ledMesh = config:get('LED','mesh','LED'),
    }
    ac.log('KE-SimHubMMF: ModelDefinition: Load "'.. modelID .. '" ModelDefinition')

    ac.debug('ModelDefinition:'..self.modelID..': Config',config)
    ac.debug('ModelDefinition:'..self.modelID..': Definition',self)

    return setmetatable(self, { __index = ModelDefinition })
end

return ModelDefinition