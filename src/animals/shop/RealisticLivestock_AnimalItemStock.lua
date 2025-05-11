RealisticLivestock_AnimalItemStock = {}
local mt = Class(AnimalItemStock)

function RealisticLivestock_AnimalItemStock:getClusterId(_)
    return self.cluster.isIndividual == nil and self.cluster.id or (self.cluster.farmId .. " " .. self.cluster.uniqueId)
end

AnimalItemStock.getClusterId = Utils.overwrittenFunction(AnimalItemStock.getClusterId, RealisticLivestock_AnimalItemStock.getClusterId)


function RealisticLivestock_AnimalItemStock.new(animal)

    local self = setmetatable({}, mt)

    self.cluster = animal
	self.visual = g_currentMission.animalSystem:getVisualByAge(animal.subTypeIndex, animal:getAge())
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(animal.subTypeIndex)
	self.title = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)
	
	self.infos = {
		{
			title = g_i18n:getText("ui_age"),
			value = g_i18n:formatNumMonth(animal:getAge())
		},
		{
			title = g_i18n:getText("ui_horseHealth"),
			value = string.format("%.f%%", animal:getHealthFactor() * 100)
		}
	}
	
	if subType.supportsReproduction and animal.reproduction > 0 and animal:getAge() >= subType.reproductionMinAgeMonth then
		local newInfo = {
			title = g_i18n:getText("infohud_reproductionStatus"),
			value = string.format("%.f%%", animal:getReproductionFactor() * 100)
		}
		table.insert(self.infos, newInfo)
	end

	local isHorse = string.contains(subType.name, "HORSE", true) or string.contains(subType.name, "STALLION", true) 

	if animal.isIndividual and not isHorse then

		local yes = g_i18n:getText("rl_ui_yes")
		local no = g_i18n:getText("rl_ui_no")

		if subType.supportsReproduction and animal.reproduction <= 0 then

			local valueText = nil
			local healthFactor = animal:getHealthFactor()

            if animal.age < subType.reproductionMinAgeMonth then
                valueText = g_i18n:getText("rl_ui_tooYoung")
            elseif animal.isParent and animal.monthsSinceLastBirth <= 2 then
                valueText = g_i18n:getText("rl_ui_recoveringLastBirth")
            elseif not RealisticLivestock.hasMaleAnimalInPen(animal.clusterSystem, animal.subTypeName, animal) then
                valueText = g_i18n:getText("rl_ui_noMaleAnimal")
            elseif healthFactor < subType.reproductionMinHealth then
                valueText = g_i18n:getText("rl_ui_unhealthy")
            end

            if valueText ~= nil then
				table.insert(self.infos, {
					title = g_i18n:getText("rl_ui_canReproduce"),
					value = valueText
				})
			end

		end

		table.insert(self.infos, {
			title = g_i18n:getText("rl_ui_weight"),
			value = string.format("%.2f", animal.weight or 50) .. "kg"
		})
		
		table.insert(self.infos, {
			title = g_i18n:getText("rl_ui_targetWeight"),
			value = string.format("%.2f", animal.targetWeight or 50) .. "kg"
		})
		
		if animal.animalTypeIndex == AnimalType.COW and animal.gender == "female" and animal:getAge() >= subType.reproductionMinAgeMonth then
		
			table.insert(self.infos, {
				title = g_i18n:getText("rl_ui_lactating"),
				value = animal.isLactating and yes or no
			})

		end

		if animal.gender == "male" and animal:getAge() >= subType.reproductionMinAgeMonth then
			
			table.insert(self.infos, {
				title = g_i18n:getText("rl_ui_maleNumImpregnatable"),
				value = animal:getNumberOfImpregnatableFemalesForMale() or 0
			})

		end

	end
	
	if animal.getFitnessFactor ~= nil then
		local newInfo = {
			title = g_i18n:getText("ui_horseFitness"),
			value = string.format("%.f%%", animal:getFitnessFactor() * 100)
		}
		table.insert(self.infos, newInfo)
	end
	
	if animal.getRidingFactor ~= nil then
		local newInfo = {
			title = g_i18n:getText("ui_horseDailyRiding"),
			value = string.format("%.f%%", animal:getRidingFactor() * 100)
		}
		table.insert(self.infos, newInfo)
	end
	
	if Platform.gameplay.needHorseCleaning and animal.getDirtFactor ~= nil then
		local newInfo = {
			title = g_i18n:getText("statistic_cleanliness"),
			value = string.format("%.f%%", (1 - animal:getDirtFactor()) * 100)
		}
		table.insert(self.infos, newInfo)
	end
	
	return self
end

AnimalItemStock.new = RealisticLivestock_AnimalItemStock.new