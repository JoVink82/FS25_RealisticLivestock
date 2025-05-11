RL_AnimalScreenTrailer = {}

function RL_AnimalScreenTrailer:initTargetItems(_)

    self.targetItems = {}
    local animals = self.trailer:getClusters()

    if animals ~= nil then
        for _, animal in pairs(animals) do
            local item = AnimalItemStock.new(animal)
            table.insert(self.targetItems, item)
        end
    end

    table.sort(self.targetItems, RL_AnimalScreenBase.sortAnimals)

end

AnimalScreenTrailer.initTargetItems = Utils.overwrittenFunction(AnimalScreenTrailer.initTargetItems, RL_AnimalScreenTrailer.initTargetItems)