---@class ModelInstance
---@field definition ModelDefinition
---@field node ac.SceneReference
---@field attach string
---@field displayMesh ac.SceneReference
---@field ledMeshes ac.SceneReference
---@field deviceIndex integer
---@field flip boolean
---@field invert boolean
---@field position vec3
---@field rotation vec3
local ModelInstance = {}

function ModelInstance.new(definition)
    local self = {
        definition = definition,
        node = nil,
        attach = 'COCKPIT_HR',
        displayMesh = ac.emptySceneReference(),
        ledMeshes = ac.emptySceneReference(),
        deviceIndex = 1,
        flip = false,
        invert = false,
        position = vec3(),
        rotation = vec3()
    }

    return setmetatable(self, { __index = ModelInstance })
end

function ModelInstance:load(Attach)

    local parent = ac.findNodes('carsRoot:yes'):findNodes(Attach and Attach or self.attach)
    local attachNode = parent:findNodes('SimHubDeviceModel')

    if attachNode:size() == 0 then parent:createNode('SimHubDeviceModel',false) end
    self.node = parent:findNodes('SimHubDeviceModel'):loadKN5(self.definition.path)

    self:setPosition(self.position)
    self:setRotation(self.rotation)
    return true
end

function ModelInstance:setDevice(deviceIndex)
    deviceIndex = deviceIndex
end



function ModelInstance:destroy() 
    
end

---@param position vec3
function ModelInstance:setPosition(position)
    self.position = position
    self.node:setPosition(position)
end

---@param rotation vec3
function ModelInstance:setRotation(rotation)
    local look = vec3(0,0,(self.flip and -1 or 1))
        :rotate(quat.fromAngleAxis(math.rad(rotation.x),vec3(1,0,0)))
        :rotate(quat.fromAngleAxis(math.rad(rotation.y),vec3(0,1,0)))
    
    self.node:setOrientation(look,vec3(0,(self.invert and -1 or 1),0)
        :rotate(quat.fromAngleAxis(math.rad(rotation.z),vec3(0,0,1))) )

end


---@param position? vec3
---@param rotation? vec3
function ModelInstance:setTransform(position,rotation)

end

return ModelInstance