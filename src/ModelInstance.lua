---@class ModelInstance
---@field definition ModelDefinition
---@field device Device
---@field node ac.SceneReference
---@field attach string
---@field attachIndex integer
---@field displayMesh ac.SceneReference
---@field ledMeshes ac.SceneReference
---@field points table
---@field deviceIndex integer
---@field displayBrightnessess integer
local ModelInstance = {}

function ModelInstance.new(definition)
    local points = {}
    points['COCKPIT_HR'] = {flip = false,invert = false,position = vec3(),rotation = vec3()}
    points['STEER_HR'] = {flip = false,invert = false,position = vec3(),rotation = vec3()}
    local self = {
        definition = definition,
        device = nil,
        node = nil,
        attach = 'COCKPIT_HR',
        attachIndex = 1,
        displayMesh = ac.emptySceneReference(),
        ledMeshes = ac.emptySceneReference(),
        points = points,
        displayBrightnessess = 0,
    }
    return setmetatable(self, { __index = ModelInstance })
end

---@param Attach string?
function ModelInstance:load(Attach)

    if Attach ~= nil and self.attach ~= Attach then self.attach = Attach end

    local parent = ac.findNodes('carsRoot:yes'):findNodes(Attach and Attach or self.attach)
    local attachNode = parent:findNodes('SimHubDeviceModel')

    if attachNode:size() == 0 then parent:createNode('SimHubDeviceModel',false) end
    self.node = parent:findNodes('SimHubDeviceModel'):loadKN5(self.definition.path)

    if self.definition.displayEnable > 0 then
        self.displayMesh = self.node:findMeshes(self.definition.displayMesh)
    end

    if self.definition.ledsCount > 0 then
        self.ledMeshes = self.node:findMeshes(self.definition.ledMesh..'.?')
    end

    self:setFlip(self.points[self.attach].flip)
    self:setInvert(self.points[self.attach].invert)
    self:setPosition(self.points[self.attach].position)
    self:setRotation(self.points[self.attach].rotation)
    

    return true
end

function ModelInstance:reload(Attach)

    if self.node then self.node:dispose() end
    self.attach = Attach and Attach or self.attach

    self:load()
    self:setDevice()
    return true
end
-- function ModelInstance:setDevice(deviceIndex)
--     deviceIndex = deviceIndex
--     self.setDisplayTexture()
-- end

---@param position vec3?
function ModelInstance:setPosition(position)
    if position ~= nil then self.points[self.attach].position = position end
    self.node:setPosition(self.points[self.attach].position)
end

---@param rotation vec3?
function ModelInstance:setRotation(rotation)
    if rotation ~= nil then self.points[self.attach].rotation = rotation end
    local look = vec3(0,0,(self.points[self.attach].flip and -1 or 1))
        :rotate(quat.fromAngleAxis(math.rad(self.points[self.attach].rotation.x),vec3(1,0,0)))
        :rotate(quat.fromAngleAxis(math.rad(self.points[self.attach].rotation.y),vec3(0,1,0)))
    
    self.node:setOrientation(look,vec3(0,(self.points[self.attach].invert and -1 or 1),0)
        :rotate(quat.fromAngleAxis(math.rad(self.points[self.attach].rotation.z),vec3(0,0,1))) )
end

---@param flip boolean?
function ModelInstance:setFlip(flip)
    if flip == nil then
        self.points[self.attach].flip = not self.points[self.attach].flip
    else
        self.points[self.attach].flip = flip
    end
    self:setRotation()
end

---@param invert boolean?
function ModelInstance:setInvert(invert)
    if invert == nil then
        self.points[self.attach].invert = not self.points[self.attach].invert
    else
        self.points[self.attach].invert = invert
    end
    self:setRotation()
end

---@param position? vec3
---@param rotation? vec3
function ModelInstance:setTransform(position,rotation)

end

function ModelInstance:setDevice(device)
    if device then self.device = device end
    self:setDisplayTexture(self.device)
    self:setLedUpdater(self.device)
end

function ModelInstance:setDisplayTexture(device)
    self.displayMesh:setAttribute('DeviceID',device.id)
    self.displayMesh:setAttribute('DeviceIndex',device.index)
    device:setDisplayMeshes(self.displayMesh)
end

function ModelInstance:updateDisplayBrightness(device)
    if device then 
        if device.mmf.DisplayBrightness ~= self.displayBrightnessess then
            local tempBrightness = device.mmf.DisplayBrightness/10
            local brightness = vec3(tempBrightness,tempBrightness,tempBrightness)
            self.displayMesh
                :ensureUniqueMaterials()
                :setMaterialProperty("ksEmissive",brightness)
            self.displayBrightnessess = device.mmf.DisplayBrightness
        end
    end
end


function ModelInstance:setLedUpdater(device)
    device:setLedMeshes( self.ledMeshes)
end

return ModelInstance