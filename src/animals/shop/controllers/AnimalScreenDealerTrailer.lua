RL_AnimalScreenDealerTrailer = {}

function RL_AnimalScreenDealerTrailer:initTargetItems(_)

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

AnimalScreenDealerTrailer.initTargetItems = Utils.overwrittenFunction(AnimalScreenDealerTrailer.initTargetItems, RL_AnimalScreenDealerTrailer.initTargetItems)


function RL_AnimalScreenDealerTrailer:initSourceItems(_)

    local animalTypeIndex = self.trailer:getCurrentAnimalType()
    local animals = g_currentMission.animalSystem:getSaleAnimalsByTypeIndex(animalTypeIndex)
    
    self.sourceItems = { [animalTypeIndex] = {} }

    for _, animal in pairs(animals) do
        local item = AnimalItemNew.new(animal)
        table.insert(self.sourceItems[animalTypeIndex], item)
    end

    table.sort(self.sourceItems[animalTypeIndex], RL_AnimalScreenBase.sortSaleAnimals)

end

AnimalScreenDealerTrailer.initSourceItems = Utils.overwrittenFunction(AnimalScreenDealerTrailer.initSourceItems, RL_AnimalScreenDealerTrailer.initSourceItems)


function RL_AnimalScreenDealerTrailer:getSourceMaxNumAnimals(_, _)

    return 1

end

AnimalScreenDealerTrailer.getSourceMaxNumAnimals = Utils.overwrittenFunction(AnimalScreenDealerTrailer.getSourceMaxNumAnimals, RL_AnimalScreenDealerTrailer.getSourceMaxNumAnimals)


function RL_AnimalScreenDealerTrailer:applySource(_, animalTypeIndex, animalIndex)

    local item = self.sourceItems[animalTypeIndex][animalIndex]
    local trailer = self.trailer
    local ownerFarmId = husbandry:getOwnerFarmId()

    local price = -item:getPrice()
	local transportationFee = -item:getTranportationFee(1)

    local errorCode = AnimalBuyEvent.validate(trailer, item:getSubTypeIndex(), item:getAge(), 1, price, transportationFee, ownerFarmId)

    if errorCode ~= nil then
		local error = AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[errorCode]
		self.errorCallback(g_i18n:getText(error.text))
		return false
	end
    
	--self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.BUYING))

    local animal = item.animal
    trailer:getClusterSystem():addCluster(animal)
    g_currentMission:addMoney(price + transportationFee, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)
    
    g_currentMission.animalSystem:removeSaleAnimal(animalTypeIndex, animal.birthday.country, animal.farmId, animal.uniqueId)
    table.remove(self.sourceItems[animalTypeIndex], animalIndex)

    self.sourceActionFinished(nil, "Animal bought successfully")

    return true

end

AnimalScreenDealerTrailer.applySource = Utils.overwrittenFunction(AnimalScreenDealerTrailer.applySource, RL_AnimalScreenDealerTrailer.applySource)