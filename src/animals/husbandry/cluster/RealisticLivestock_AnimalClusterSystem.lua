RealisticLivestock_AnimalClusterSystem = {}
local AnimalClusterSystem_mt = Class(AnimalClusterSystem)

-- TESTING FILE

function RealisticLivestock_AnimalClusterSystem.new(superFunc, isServer, owner, customMt)

    local self = setmetatable({}, customMt or AnimalClusterSystem_mt)

    self.isServer = isServer
    self.owner = owner
    self.clusters = {}
    self.idToIndex = {}
    self.clustersToAdd = {}
    self.clustersToRemove = {}
    self.needsUpdate = false
    self.animals = {}
    self.currentAnimalId = 0

    return self

end

AnimalClusterSystem.new = Utils.overwrittenFunction(AnimalClusterSystem.new, RealisticLivestock_AnimalClusterSystem.new)

function RealisticLivestock_AnimalClusterSystem:delete()

    for _, animal in pairs(self.animals) do
        animal:delete()
    end

    self.animals = {}
    self.currentAnimalId = 0
end

AnimalClusterSystem.delete = Utils.appendedFunction(AnimalClusterSystem.delete, RealisticLivestock_AnimalClusterSystem.delete)

function RealisticLivestock_AnimalClusterSystem:getNextAnimalId()
    self.currentAnimalId = self.currentAnimalId + 1
    return self.currentAnimalId
end

AnimalClusterSystem.getNextAnimalId = RealisticLivestock_AnimalClusterSystem.getNextAnimalId

function RealisticLivestock_AnimalClusterSystem:getAnimals()
    return self.animals or {}
end

AnimalClusterSystem.getAnimals = RealisticLivestock_AnimalClusterSystem.getAnimals

function RealisticLivestock_AnimalClusterSystem:loadFromXMLFile(superFunc, xmlFile, key)

    local i = 0
    local totalAnimals = 0

    while true do

        local animalKey = string.format("%s.animal(%d)", key, i)
        local rlAnimalKey = string.format("%s.RLAnimal(%d)", key, i)

        if not xmlFile:hasProperty(animalKey) and not xmlFile:hasProperty(rlAnimalKey) then break end

        if xmlFile:getString(rlAnimalKey .. "#subType") ~= nil then

            local animal = Animal.loadFromXMLFile(xmlFile, rlAnimalKey, self)
            if animal == nil then continue end
            table.insert(self.animals, animal)

            i = i + 1

            continue

        end

        local subTypeName = xmlFile:getString(animalKey .. "#subType", "")
        local subType = g_currentMission.animalSystem:getSubTypeByName(subTypeName)
        local subTypeIndex = g_currentMission.animalSystem:getSubTypeIndexByName(subTypeName)

        if subType == nil then
            Logging.xmlWarning(xmlFile, "SubType '%s' not defined. Ignoring animal '%s'.", tostring(subTypeName), animalKey)
        else
            local cluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subType.subTypeIndex)

            if cluster:loadFromXMLFile(xmlFile, animalKey) then
                --self:addPendingAddCluster(cluster)

                local monthsSinceLastBirth = cluster.monthsSinceLastBirth or 0
                local lactatingAnimals = cluster.lactatingAnimals or 0
                local isParent = cluster.isParent or false
                local gender = subType.gender or "female"
                local minWeight = subType.minWeight
                local targetWeight = subType.targetWeight
                local maxWeight = subType.maxWeight
                local weightPerMonth = (targetWeight - minWeight) / 18

                for index=1, cluster.numAnimals do

                    -- not an exact calculation for every subtype but it is relatively accurate
                    local weight = math.clamp((minWeight + (weightPerMonth * math.clamp(cluster.age, 0, 20))) * (math.random(85, 115) / 100), minWeight, maxWeight)

                    local isLactating = index <= lactatingAnimals

                    local animal = Animal.new(cluster.age, cluster.health, monthsSinceLastBirth, gender, subTypeIndex, cluster.reproduction, isParent, false, isLactating, self, nil, nil, nil, nil, nil, nil, nil, nil, nil, weight)

                    if string.contains(animal.subType, "HORSE") or string.contains(animal.subType, "STALLION") then
                        animal.dirt = cluster.dirt or 0
                        if cluster.name ~= nil and cluster.name ~= "" then animal.name = cluster.name end
                        animal.fitness = cluster.fitness or 0
                        animal.riding = cluster.riding or 0
                    end
                    table.insert(self.animals, animal)
                    totalAnimals = totalAnimals + 1
                end

            end
        end

        i = i + 1

    end

    self:updateClusters()

    self.needsUpdate = false

    if self.owner ~= nil and self.owner.spec_husbandryFood ~= nil then SpecializationUtil.raiseEvent(self.owner, "onHusbandryAnimalsUpdate", self.animals) end

end

AnimalClusterSystem.loadFromXMLFile = Utils.overwrittenFunction(AnimalClusterSystem.loadFromXMLFile, RealisticLivestock_AnimalClusterSystem.loadFromXMLFile)

function RealisticLivestock_AnimalClusterSystem:saveToXMLFile(superFunc, xmlFile, key, usedModNames)

    local toRemove = {}
    for i, animal in pairs(self.animals) do
        if animal == nil or animal.isDead or animal.isSold or animal.numAnimals <= 0 then table.insert(toRemove, i) end
    end

    for i=#toRemove, 1, -1 do
        table.remove(self.animals, toRemove[i])
    end

    for i, animal in pairs(self.animals) do
        --local animalKey = string.format("%s.animal(%d)", key, i - 1)
        --local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)

        --xmlFile:setString(animalKey .. "#subType", subType.name)
        --cluster:saveToXMLFile(xmlFile, animalKey, usedModNames)

        local animalKey = string.format("%s.RLAnimal(%d)", key, i - 1)
        animal:saveToXMLFile(xmlFile, animalKey)

    end

end

AnimalClusterSystem.saveToXMLFile = Utils.overwrittenFunction(AnimalClusterSystem.saveToXMLFile, RealisticLivestock_AnimalClusterSystem.saveToXMLFile)

function RealisticLivestock_AnimalClusterSystem:getClusters(superFunc)
    return self.animals or {}
end

AnimalClusterSystem.getClusters = Utils.overwrittenFunction(AnimalClusterSystem.getClusters, RealisticLivestock_AnimalClusterSystem.getClusters)

function RealisticLivestock_AnimalClusterSystem:getCluster(superFunc, index)
    return self.animals[index] or nil
end

AnimalClusterSystem.getCluster = Utils.overwrittenFunction(AnimalClusterSystem.getCluster, RealisticLivestock_AnimalClusterSystem.getCluster)


function RealisticLivestock_AnimalClusterSystem:getClusterById(superFunc, id)
    local index = self.idToIndex[id]

    if id == nil or self.animals == nil then return end

    for _, animal in pairs(self.animals) do
        if animal.farmId .. " " .. animal.uniqueId == id then return animal end
    end

    if index == nil or self.animals == nil or self.animals[index] == nil then return nil end

    return self.animals[index]
end

AnimalClusterSystem.getClusterById = Utils.overwrittenFunction(AnimalClusterSystem.getClusterById, RealisticLivestock_AnimalClusterSystem.getClusterById)



function RealisticLivestock_AnimalClusterSystem:addCluster(superFunc, animal)

    if animal.uniqueId == nil or animal.uniqueId == "1-1" or animal.uniqueId == "0-0" then return end
    animal:setClusterSystem(self)
    table.insert(self.animals, animal)

    self:updateIdMapping()

end

AnimalClusterSystem.addCluster = Utils.overwrittenFunction(AnimalClusterSystem.addCluster, RealisticLivestock_AnimalClusterSystem.addCluster)


function RealisticLivestock_AnimalClusterSystem:removeCluster(_, animalIndex)

    if self.animals[animalIndex] ~= nil then
        local animal = self.animals[animalIndex]
        table.remove(self.animals, animalIndex)
        animal:setClusterSystem(nil)
    else
        for i, animal in pairs(self.animals) do
            if animal.farmId .. " " .. animal.uniqueId == animalIndex then
                table.remove(self.animals, i)
                animal:setClusterSystem(nil)
                break
            end
        end
    end

    self:updateIdMapping()

end

AnimalClusterSystem.removeCluster = Utils.overwrittenFunction(AnimalClusterSystem.removeCluster, RealisticLivestock_AnimalClusterSystem.removeCluster)


function RealisticLivestock_AnimalClusterSystem:updateClusters(superFunc)

    --assert(self.isServer, "AnimalClusterSystem:updateClusters is a server function")

    local isDirty = false
    local removedClusterIndices = {}

    for animalsToAdd, pending in pairs(self.clustersToAdd) do
        if not pending then continue end

        if animalsToAdd.isIndividual ~= nil then
            self:addCluster(animalsToAdd)
            isDirty = true
            continue
        end

        if animalsToAdd.numAnimals ~= nil then
            local subType = g_currentMission.animalSystem:getSubTypeByIndex(animalsToAdd.subTypeIndex)
            for i=1, animalsToAdd.numAnimals do
                local genetics = animalsToAdd.genetics or nil
                local impregnatedBy = animalsToAdd.impregnatedBy or nil
                local animal = Animal.new(animalsToAdd.age, animalsToAdd.health, animalsToAdd.monthsSinceLastBirth or 0, subType.gender, animalsToAdd.subTypeIndex, animalsToAdd.reproduction or 0, animalsToAdd.isParent or false, animalsToAdd.isPregnant or false, animalsToAdd.isLactating or false, self, animalsToAdd.uniqueId, animalsToAdd.motherId, animalsToAdd.fatherId, nil, animalsToAdd.name, animalsToAdd.dirt, animalsToAdd.fitness, animalsToAdd.riding, animalsToAdd.farmId, animalsToAdd.weight, genetics, impregnatedBy, animalsToAdd.variation, animalsToAdd.children)
                self:addCluster(animal)
                isDirty = true
            end

            continue
        end

        for _, animalToAdd in pairs(animalsToAdd) do

            if animalToAdd.isIndividual then
                self:addCluster(animalToAdd)
                isDirty = true

            else
                local subType = g_currentMission.animalSystem:getSubTypeByIndex(animalToAdd.subTypeIndex)
                for i=1, animalToAdd.numAnimals do
                    local genetics = animalToAdd.genetics or nil
                    local impregnatedBy = animalToAdd.impregnatedBy or nil
                    local animal = Animal.new(animalToAdd.age, animalToAdd.health, animalToAdd.monthsSinceLastBirth or 0, subType.gender, animalToAdd.subTypeIndex, animalToAdd.reproduction or 0, animalToAdd.isParent or false, animalToAdd.isPregnant or false, animalToAdd.isLactating or false, self, animalToAdd.uniqueId, animalToAdd.motherId, animalToAdd.fatherId, nil, animalToAdd.name, animalToAdd.dirt, animalToAdd.fitness, animalToAdd.riding, animalToAdd.farmId, animalToAdd.weight, genetics, impregnatedBy, animalToAdd.variation, animalToAdd.children)
                    self:addCluster(animal)
                    isDirty = true
                end
            end

        end

    end


    for animalIndex, animal in pairs(self.animals) do
        if animal.isDirty then
            isDirty = true
            animal.isDirty = false
        end

        --if animal:getNumAnimals() <= 0 and not animal.isDead and not animal.isSold then animal.numAnimals = 1 end

        if self.clustersToRemove[animal] ~= nil or (animal.beingRidden ~= nil and animal.beingRidden) or animal:getNumAnimals() == 0 or animal.uniqueId == "1-1" or animal.uniqueId == "0-0" then table.insert(removedClusterIndices, animalIndex) end
    end


    for i = #removedClusterIndices, 1, -1 do
        isDirty = true
        local animalIndexToRemove = removedClusterIndices[i]

        self:removeCluster(animalIndexToRemove)
    end

    --if isDirty then
       -- g_server:broadcastEvent(AnimalClusterUpdateEvent.new(self.owner, self.animals), true)
        --g_messageCenter:publish(AnimalClusterUpdateEvent, self.owner, self.animals)
    --end

    self.clustersToAdd = {}
    self.clustersToRemove = {}

    self:updateIdMapping()
    if self.owner.spec_husbandryAnimals ~= nil then self.owner.spec_husbandryAnimals:updateVisualAnimals() end


end

AnimalClusterSystem.updateClusters = Utils.overwrittenFunction(AnimalClusterSystem.updateClusters, RealisticLivestock_AnimalClusterSystem.updateClusters)


function RealisticLivestock_AnimalClusterSystem:updateIdMapping(superFunc)
    self.idToIndex = {}

    for index, animal in pairs(self.animals) do
        if index == nil then continue end
        self.idToIndex[animal.farmId .. " " .. animal.uniqueId] = index
    end
        
    if self.owner.updatedClusters ~= nil then self.owner:updatedClusters(self.owner, self.animals) end

    g_server:broadcastEvent(AnimalClusterUpdateEvent.new(self.owner, self.animals))
    g_messageCenter:publish(AnimalClusterUpdateEvent, self.owner, self.animals)
    
end

AnimalClusterSystem.updateIdMapping = Utils.overwrittenFunction(AnimalClusterSystem.updateIdMapping, RealisticLivestock_AnimalClusterSystem.updateIdMapping)