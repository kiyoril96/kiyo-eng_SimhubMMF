local definition = require('src/ModelDefinition')
local instance = require('src/ModelInstance')

local ModelManager = {
    modelDefinitions = {}, 
    models = {}
}

function ModelManager.new()

    local models = io.scanDir(ac.getFolder(ac.FolderID.ScriptOrigin)..'/model','*')
    local modelDefinitions = {}
    for i = 1,#models do
        local def = definition.new(models[i])
        if def then 
            modelDefinitions[models[i]] = def 
        end
    end

    local self = {
        ModelDefinitions=modelDefinitions,
        models = {}
    }

    return setmetatable(self, { __index = ModelManager })
end

function ModelManager:getDefinition(id)
    return self.ModelDefinitions[id]
end

---@param id string
---@param deviceIndex? integer
---@param attach? string
function ModelManager:addModel(id,deviceIndex,attach)
    local deviceCount = self.modelDefinitions[id].instanceCount +1
    self.modelDefinitions[id].instanceCount = deviceCount
    local def = self.modelDefinitions[id]
    local modelInstance = instance.new(def)
    modelInstance:setDevice(deviceIndex and deviceIndex or 1)
    modelInstance:load(attach)
    self.models[id..deviceCount]=modelInstance
end

function ModelManager:deleteModel(id,modelIndex)

end


return ModelManager