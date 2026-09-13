-- シングルトンにしたい

local definition = require('src/ModelDefinition')
local instance = require('src/ModelInstance')

---@class ModelManager
---@field modelDefinitions ModelDefinition[]
---@field models ModelInstance[]
---@field modelIdList string[]
---@field config ac.INIConfig
---@field nodes string[]
local ModelManager = {}

function ModelManager.new()

    local modelIDs = io.scanDir(ac.getFolder(ac.FolderID.ScriptOrigin)..'/model','*')
    local modelDefinitions = {}
    for i = 1,#modelIDs do
        local def = definition.new(modelIDs[i])
        if def then 
            modelDefinitions[modelIDs[i]] = def 
        end
    end

    local self = {
        modelDefinitions=modelDefinitions,
        modelIdList = modelIDs,
        models = {},
        config = {},
        nodes ={}
    }

    return setmetatable(self, { __index = ModelManager })
end

function ModelManager:getDefinition(id)
    return self.modelDefinitions[id]
end

---@param modelId string --Models folder name
---@param attach? string
function ModelManager:addModel(modelId,attach)

    -- ん～～
    local attachIndex = 1
    if attach ~= nil then
        for i,node in ipairs(self.nodes) do
            if node == attach then
                attachIndex = i
            end
        end
    end

    local def = self.modelDefinitions[modelId]
    local modelInstance = instance.new(def)
    modelInstance.attachIndex = attachIndex
    modelInstance:load(attach)
    self.models[#self.models+1]=modelInstance
end


--車ごとの設定ファイルを受け取ってモデルの読み込み、配置をやる
--設定ファイルにはモデルを設置している位置ごとにモデルとその設定値を定義
---@param config ac.INIConfig
function ModelManager:setup(config)

    self.config = config

    for index, section in config:iterate('POS') do
        if section ~= 'GENERAL' then
            self.nodes[index] = config:get(section,'Node','COCKPIT_HR')
        end
    end

end


-- 上手く行ってない
function ModelManager:changeModel(modelIndex ,definition)
    local modelInstance = self.models[modelIndex]
    local oldModelId = definition.modelID

    modelInstance.definition = definition
    local deviceCount = definition.instanceCount +1
    if modelInstance.node then modelInstance.node:dispose() end
    modelInstance:load()
    self.models[definition.modelID..deviceCount] = modelInstance
end

function ModelManager:deleteModel(id,modelIndex)

end

return ModelManager