RealisticLivestock_PlaceableHusbandryPallets = {}

function RealisticLivestock_PlaceableHusbandryPallets:onHusbandryAnimalsUpdate(superFunc, animals)

    local spec = self.spec_husbandryPallets

    for fillTypeIndex, _  in pairs(spec.litersPerHour) do
        spec.litersPerHour[fillTypeIndex] = 0
    end

    spec.activeFillTypes = {}

    for _, animal in pairs(animals) do
        local subType = animal:getSubType()
        if subType ~= nil then
            local pallets = subType.output.pallets
            if pallets ~= nil then

                local minTemp = spec.minTemp
                local age = animal:getAge()
                local litersPerAnimals = pallets.curve:get(age)
                local litersPerDay = litersPerAnimals
                local productivity = 1

                if animal.genetics.productivity ~= nil then productivity = animal.genetics.productivity end

                if animal.animalTypeIndex == AnimalType.SHEEP then
                    if pallets.fillType == 42 and minTemp ~= nil and minTemp < 10 then litersPerDay = 0 end

                    if pallets.fillType == 42 and minTemp == nil and math.floor(g_currentMission.environment.weather.temperatureUpdater.currentMin) < 10 then litersPerDay = 0 end
                end

                spec.litersPerHour[pallets.fillType] = spec.litersPerHour[pallets.fillType] + ((litersPerDay / 24) * productivity)

                table.addElement(spec.activeFillTypes, pallets.fillType)
            end
        end
    end

end

PlaceableHusbandryPallets.onHusbandryAnimalsUpdate = Utils.overwrittenFunction(PlaceableHusbandryPallets.onHusbandryAnimalsUpdate, RealisticLivestock_PlaceableHusbandryPallets.onHusbandryAnimalsUpdate)