RealisticLivestock_PlaceableHusbandryFood = {}

function RealisticLivestock_PlaceableHusbandryFood:onHusbandryAnimalsUpdate(superFunc, animals)
    local spec = self.spec_husbandryFood

    spec.litersPerHour = 0

    for _, animal in pairs(animals) do
        local subType = animal:getSubType()
        if subType ~= nil then
            local food = subType.input.food
            if food ~= nil then
                local age = animal:getAge()
                local litersPerDay = food:get(age)

                local reproduction = animal.reproduction
                local milkSpec = self.spec_husbandryMilk

                if milkSpec ~= nil and animal.isLactating then
                    litersPerDay = litersPerDay * 1.25
                end

                if reproduction ~= nil and reproduction > 0 and animal.pregnancy ~= nil and animal.pregnancy.pregnancies ~= nil then
                    litersPerDay = litersPerDay * math.pow(1 + ((reproduction / 100) / 5), #animal.pregnancy.pregnancies)
                end

                if animal.genetics.metabolism ~= nil then litersPerDay = litersPerDay * animal.genetics.metabolism end

                litersPerDay = litersPerDay * (RealisticLivestock_PlaceableHusbandryFood.foodScale or 1)

                spec.litersPerHour = spec.litersPerHour + (litersPerDay / 24)
                --print("current food litres per hour: " .. spec.litersPerHour .. "L")
            end
        end
    end
end

PlaceableHusbandryFood.onHusbandryAnimalsUpdate = Utils.overwrittenFunction(PlaceableHusbandryFood.onHusbandryAnimalsUpdate, RealisticLivestock_PlaceableHusbandryFood.onHusbandryAnimalsUpdate)


function RealisticLivestock_PlaceableHusbandryFood:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_husbandryFood

    if spec.animalTypeIndex == 1 then spec.capacity = spec.capacity * 1.5 end

end

PlaceableHusbandryFood.loadFromXMLFile = Utils.appendedFunction(PlaceableHusbandryFood.loadFromXMLFile, RealisticLivestock_PlaceableHusbandryFood.loadFromXMLFile)


function RealisticLivestock_PlaceableHusbandryFood.onSettingChanged(name, state)

    RealisticLivestock_PlaceableHusbandryFood[name] = state

end