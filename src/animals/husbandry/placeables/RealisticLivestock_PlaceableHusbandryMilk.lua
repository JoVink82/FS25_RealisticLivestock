RealisticLivestock_PlaceableHusbandryMilk = {}

function RealisticLivestock_PlaceableHusbandryMilk:onHusbandryAnimalsUpdate(superFunc, animals)
    local spec = self.spec_husbandryMilk

    for fillType, _ in pairs(spec.litersPerHour) do
        spec.litersPerHour[fillType] = 0
    end

    spec.activeFillTypes = {}

    for _, animal in pairs(animals) do
        local subType = animal:getSubType()

        if subType ~= nil then
            local milk = subType.output.milk

            if milk ~= nil and animal.isParent == true and animal.isLactating and animal.monthsSinceLastBirth ~= nil then

                local age = animal:getAge()
                local litersPerAnimals = milk.curve:get(age)
                local litersPerDay = litersPerAnimals
                local monthsSinceLastBirth = animal.monthsSinceLastBirth
                local factor = 0.8
                local productivity = 1

                if animal.genetics.productivity ~= nil then productivity = animal.genetics.productivity end

                -- cows get pregnant after 2 months, dry off 8 months after impregnation, calf 10 months after impregnation
                -- cows will give birth 12 months after the previous birth

                if monthsSinceLastBirth >= 10 then
                    -- drying off period - no milk
                    animal.isLactating = false
                    factor = 0
                elseif monthsSinceLastBirth <= 3 then
                    -- lactation increases fast immediately after calving for 3 months (colostrum is still produced for 1 week after calving but this is not simulated here)
                    factor = factor + (monthsSinceLastBirth / 6)
                else
                    -- lactation starts to slowly fall after 4 months
                    factor = factor + ((11 - monthsSinceLastBirth) / 15)
                end

                spec.litersPerHour[milk.fillType] = spec.litersPerHour[milk.fillType] + ((litersPerDay / 24) * factor * productivity)

                table.addElement(spec.activeFillTypes, milk.fillType)

                --print("current milk litres per hour: " .. spec.litersPerHour[milk.fillType] .. "L at" .. factor .. "% efficiency")

            end

        end

    end

end

PlaceableHusbandryMilk.onHusbandryAnimalsUpdate = Utils.overwrittenFunction(PlaceableHusbandryMilk.onHusbandryAnimalsUpdate, RealisticLivestock_PlaceableHusbandryMilk.onHusbandryAnimalsUpdate)