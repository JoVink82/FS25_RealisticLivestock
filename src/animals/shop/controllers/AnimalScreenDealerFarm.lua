RL_AnimalScreenDealerFarm = {}

function RL_AnimalScreenDealerFarm:initTargetItems(_)

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

AnimalScreenDealerFarm.initTargetItems = Utils.overwrittenFunction(AnimalScreenDealerFarm.initTargetItems, RL_AnimalScreenDealerFarm.initTargetItems)


function RL_AnimalScreenDealerFarm:initSourceItems(_)

    local animalTypeIndex = self.husbandry:getAnimalTypeIndex()
    local animals = g_currentMission.animalSystem:getSaleAnimalsByTypeIndex(animalTypeIndex)
    
    self.sourceItems = { [animalTypeIndex] = {} }

    for _, animal in pairs(animals) do
        local item = AnimalItemNew.new(animal)
        table.insert(self.sourceItems[animalTypeIndex], item)
    end

    table.sort(self.sourceItems[animalTypeIndex], RL_AnimalScreenBase.sortSaleAnimals)

end

AnimalScreenDealerFarm.initSourceItems = Utils.overwrittenFunction(AnimalScreenDealerFarm.initSourceItems, RL_AnimalScreenDealerFarm.initSourceItems)


function RL_AnimalScreenDealerFarm:getSourceMaxNumAnimals(_, _)

    return 1

end

AnimalScreenDealerFarm.getSourceMaxNumAnimals = Utils.overwrittenFunction(AnimalScreenDealerFarm.getSourceMaxNumAnimals, RL_AnimalScreenDealerFarm.getSourceMaxNumAnimals)


function RL_AnimalScreenDealerFarm:applySource(_, animalTypeIndex, animalIndex)

    local item = self.sourceItems[animalTypeIndex][animalIndex]
    local husbandry = self.husbandry
    local ownerFarmId = husbandry:getOwnerFarmId()

    local price = -item:getPrice()
	local transportationFee = -item:getTranportationFee(1)

    local errorCode = AnimalBuyEvent.validate(husbandry, item:getSubTypeIndex(), item:getAge(), 1, price, transportationFee, ownerFarmId)

    if errorCode ~= nil then
		local error = AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[errorCode]
		self.errorCallback(g_i18n:getText(error.text))
		return false
	end
    
	--self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING))

    local animal = item.animal
    husbandry:getClusterSystem():addCluster(animal)
    g_currentMission:addMoney(price + transportationFee, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)
    
    g_currentMission.animalSystem:removeSaleAnimal(animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)
    table.remove(self.sourceItems[animalTypeIndex], animalIndex)

    self.sourceActionFinished(nil, "Animal bought successfully")

    return true

end

AnimalScreenDealerFarm.applySource = Utils.overwrittenFunction(AnimalScreenDealerFarm.applySource, RL_AnimalScreenDealerFarm.applySource)


function RL_AnimalScreenDealerFarm:getSourcePrice(_, animalTypeIndex, animalIndex, _)

    if self.sourceItems[animalTypeIndex] ~= nil then

        local item = self.sourceItems[animalTypeIndex][animalIndex]

        if item ~= nil then

	        local price = item:getPrice()
	        local transportationFee = item:getTranportationFee(1)
	        return true, price, transportationFee, price + transportationFee

        end

    end

    return false, 0, 0, 0

end

AnimalScreenDealerFarm.getSourcePrice = Utils.overwrittenFunction(AnimalScreenDealerFarm.getSourcePrice, RL_AnimalScreenDealerFarm.getSourcePrice)