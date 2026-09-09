---@class ModelInstance
---@field definition {modelID: string ,modelName: string ,path: string ,displayEnable: boolean ,displayMesh: string ,DefaultDisplayWidth: integer ,DefaultDisplayHeight :integer,ledsEnable :boolean ,ledMesh :string ,instanceCount : integer}
---@field node ac.SceneReference
---@field attach string
---@field displayMesh ac.SceneReference
---@field ledMeshes ac.SceneReference
---@field deviceIndex integer
local ModelInstance = {}

function ModelInstance.new(definition)
    local self = {
        definition = definition,
        node = nil,
        attach = 'COCKPIT_HR',
        displayMesh = ac.emptySceneReference(),
        ledMeshes = ac.emptySceneReference(),
        deviceIndex = 1
    }

    return setmetatable(self, { __index = ModelInstance })
end

function ModelInstance:load(Attach)

    local parent = ac.findNodes('carsRoot:yes'):findNodes(Attach and Attach or self.attach)
    local attachNode = parent:findNodes('SimHubDeviceModel')

    if attachNode:empty() then parent:createNode('SimHubDeviceModel',false) end
    self.node = parent:findNodes('SimHubDeviceModel'):loadKN5(self.definition.path)

    return true
end

function ModelInstance:setDevice(deviceIndex)
    deviceIndex = deviceIndex
end

function ModelInstance:changeModel(definition)
    
end

function ModelInstance:destroy() 
    
end

function ModelInstance:setTransform(...) 
    
end

return ModelInstance