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
        config = nil,
        nodes ={},
        controllerWindowOpen =false
    }

    return setmetatable(self, { __index = ModelManager })
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
    modelInstance.config = self.config
    local newIndex = #self.models+1
    modelInstance.index = newIndex
    self.models[newIndex]=modelInstance

    self:setAndSave()
    return newIndex
end

function ModelManager:deleteModel(modelIndex)
    self.models[modelIndex]:delete()
    table.remove(self.models,modelIndex)
    self:setAndSave()
end

--車ごとの設定ファイルを受け取ってモデルの読み込み、配置をやる
--設定ファイルにはモデルを設置している位置ごとにモデルとその設定値を定義
---@param config ac.INIConfig
---@param deviceManager DeviceManager
function ModelManager:setup(config,deviceManager)

    self.config = config

    self.nodes=self.config:get('GENERAL','Nodes',{'COCKPIT_HR','STEER_HR'})

    for _, section in self.config:iterate('MODEL') do
        local newIndex = self:addModel(self.config:get(section,'Model','DDU_4inch'),self.config:get(section,'Node','COCKPIT_HR'))
        self.models[newIndex]:setDevice(deviceManager.devices[self.config:get(section,'Device',1)])
        for _ ,value in ipairs(self.nodes) do
            local keyPrefix = value..'.'
            self.models[newIndex].points[value].position = self.config:get(section,keyPrefix..'Position',vec3(0,0,0))
            self.models[newIndex].points[value].rotation = self.config:get(section,keyPrefix..'Rotation',vec3(0,0,0))
            self.models[newIndex].points[value].flip = self.config:get(section,keyPrefix..'Flip',false)
            self.models[newIndex].points[value].invert = self.config:get(section,keyPrefix..'Invert',false)
        end
        self.models[newIndex]:setPosition()
        self.models[newIndex]:setRotation()
    end
end

function ModelManager:setAndSave()
    if self.config then
    for _,section in self.config:iterate('MODEL') do
        self.config.sections[section] = nil
    end

    for index, model in ipairs(self.models) do
        if model then
            self.config:set('MODEL_'..(index-1),'Model',model.definition.modelID)
            self.config:set('MODEL_'..(index-1),'Node',model.attach)
            if model.device then self.config:set('MODEL_'..(index-1),'Device',model.device.index+1) end
            if model.points then 
                for k,v in pairs(model.points) do
                    self.config:set('MODEL_'..(index-1),k..'.Position',v.position)
                    self.config:set('MODEL_'..(index-1),k..'.Rotation',v.rotation)
                    self.config:set('MODEL_'..(index-1),k..'.Flip',v.flip)
                    self.config:set('MODEL_'..(index-1),k..'.Invert',v.invert)
                end
            end
        end
    end
    self.config:save()
    end
end


return ModelManager