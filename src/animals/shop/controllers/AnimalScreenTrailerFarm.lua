RL_AnimalScreenTrailerFarm = {}

function RL_AnimalScreenTrailerFarm:initTargetItems(_)

    self.targetItems = {}
    local animals = self.husbandry:getClusters()

    if animals ~= nil then
        for _, animal in pairs(animals) do
            local item = AnimalItemStock.new(animal)
            table.insert(self.targetItems, item)
        end
    end

    table.sort(self.targetItems, RL_AnimalScreenBase.sortAnimals)

end

AnimalScreenTrailerFarm.initTargetItems = Utils.overwrittenFunction(AnimalScreenTrailerFarm.initTargetItems, RL_AnimalScreenTrailerFarm.initTargetItems)


function RL_AnimalScreenTrailerFarm:initSourceItems(_)

    self.sourceItems = {}

    local animalType = self.trailer:getCurrentAnimalType()
    if animalType == nil then return end

    local animals = self.trailer:getClusters()

    if animals ~= nil then
        for _, animal in pairs(animals) do
            local item = AnimalItemStock.new(animal)

            if self.sourceItems[animalType.typeIndex] == nil then self.sourceItems[animalType.typeIndex] = {} end

            table.insert(self.sourceItems[animalType.typeIndex], item)
        end
    end


    for _, category in pairs(self.sourceItems) do
        table.sort(category, RL_AnimalScreenBase.sortAnimals)
    end

end

AnimalScreenTrailerFarm.initSourceItems = Utils.overwrittenFunction(AnimalScreenTrailerFarm.initSourceItems, RL_AnimalScreenTrailerFarm.initSourceItems)