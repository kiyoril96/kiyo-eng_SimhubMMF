-- シングルトンにしたい

local definition = require('src/ModelDefinition')
local instance = require('src/ModelInstance')

---@class ModelManager
---@field modelDefinitions ModelDefinition[]
---@field models ModelInstance[]
---@field modelIdList string[]
---@field config ac.INIConfig
---@field nodes string[]
---@field controllerWindowOpen boolean
local ModelManager = {}

function ModelManager.new()

    local modelIDs = io.scanDir(ac.getFolder(ac.FolderID.ScriptOrigin)..'/model','*')
    local modelDefinitions = {}
    for i = 1,#modelIDs do
        local def = definition.new(modelIDs[i])
        if def then
            def.index = i
            modelDefinitions[modelIDs[i]] = def
        end
    end

    local self = {
        modelDefinitions=modelDefinitions,
        modelIdList = modelIDs,
        models = {},
        config = {},
        nodes ={},
        controllerWindowOpen =false
    }

    return setmetatable(self, { __index = ModelManager })
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
    local newIndex = #self.models+1
    self.models[newIndex]=modelInstance

    return newIndex
end

function ModelManager:deleteModel(modelIndex)
    self.models[modelIndex]:delete()
    table.remove(self.models,modelIndex)
end

function ModelManager:seveTransform(device)
    --config set
    --config save
end


return ModelManager