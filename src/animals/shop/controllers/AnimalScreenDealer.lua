RL_AnimalScreenDealer = {}

function RL_AnimalScreenDealer:initTargetItems(_)

    self.targetItems = {}
    if self.husbandry == nil then return end
    local animals = self.husbandry:getClusters()

    if animals ~= nil then
        for _, animal in pairs(animals) do
            local item = AnimalItemStock.new(animal)
            table.insert(self.targetItems, item)
        end
    end

    table.sort(self.targetItems, RL_AnimalScreenBase.sortAnimals)

end

AnimalScreenDealer.initTargetItems = Utils.overwrittenFunction(AnimalScreenDealer.initTargetItems, RL_AnimalScreenDealer.initTargetItems)




-- ################

-- NOTES:

-- All the methods below are required to be overwritten in order to avoid an error that i dont have the time to figure out otherwise :)
-- would theoretically cause mod conflicts as they're overwritten, but the chance of another mod editing anything even remotely to do with this class is extremely slim

-- ################




function RL_AnimalScreenDealer:initSourceItems(_)

    self.sourceItems = {}
	self.sourceAnimalTypes = g_currentMission.animalSystem:getTypes()

	local animalTypes = {}

	if g_localPlayer == nil then return end
	local farm = g_localPlayer.farmId

	for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do

		if placeable.ownerFarmId == farm and placeable.spec_husbandryAnimals then
		
			local animalType = placeable.spec_husbandryAnimals:getAnimalTypeIndex()
		    animalTypes[animalType] = true

		end

	end


	for i = #self.sourceAnimalTypes, 1, -1 do

		local animalType = self.sourceAnimalTypes[i]

		if not animalTypes[animalType.typeIndex] then table.remove(self.sourceAnimalTypes, i) end

	end

	for index, animalType in ipairs(self.sourceAnimalTypes) do

		for _, subTypeIndex in ipairs(animalType.subTypes) do

			local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)

			for _, visual in ipairs(subType.visuals) do
				
				if not visual.store.canBeBought then continue end
					
				local item = AnimalItemNew.new(subType.subTypeIndex, visual.minAge)

				if self.sourceItems[index] == nil then self.sourceItems[index] = {} end

				table.insert(self.sourceItems[index], item)

			end

		end
	end

end

AnimalScreenDealer.initSourceItems = Utils.overwrittenFunction(AnimalScreenDealer.initSourceItems, RL_AnimalScreenDealer.initSourceItems)


function RL_AnimalScreenDealer:applySource(_, animalTypeIndex, index, numAnimals)

	local animal
	
	for i, animalType in pairs(self.sourceAnimalTypes) do

		if animalType.typeIndex == animalTypeIndex then
			animal = self.sourceItems[i][index]
			break
		end

	end


	local subTypeIndex = animal:getSubTypeIndex()
	local age = animal:getAge()
	local transportationFee = -animal:getTranportationFee(numAnimals)
	local price = -animal:getPrice() * numAnimals

	local errorCode = AnimalBuyEvent.validate(self.husbandry, subTypeIndex, age, numAnimals, price, transportationFee, self.husbandry:getOwnerFarmId())


	if errorCode ~= nil then
		local error = AnimalScreenDealer.BUY_ERROR_CODE_MAPPING[errorCode]
		self.errorCallback(g_i18n:getText(error.text))
		return false
	end

	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.BUYING))
	g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)

	g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(self.husbandry, subTypeIndex, age, numAnimals, price, transportationFee))


	return true

end

AnimalScreenDealer.applySource = Utils.overwrittenFunction(AnimalScreenDealer.applySource, RL_AnimalScreenDealer.applySource)


-- for some reason RealisticLivestock_PlaceableHusbandryAnimals.addAnimals is not overwriting the base method?

function RL_AnimalScreenDealer:run(_, connection)

	if connection:getIsServer() then
		g_messageCenter:publish(AnimalBuyEvent, self.errorCode)
		return
	elseif g_currentMission:getHasPlayerPermission("tradeAnimals", connection) then

		local userId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
		local farm = g_farmManager:getFarmForUniqueUserId(userId)
		local errorCode = AnimalBuyEvent.validate(self.object, self.subTypeIndex, self.age, self.numAnimals, self.buyPrice, self.feePrice, farm.farmId)

		if errorCode == nil then
			
			if self.object.spec_livestockTrailer ~= nil then
				RealisticLivestock_LivestockTrailer.addAnimals(self.object, _, self.subTypeIndex, self.numAnimals, self.age)
				g_currentMission:addMoney(self.buyPrice + self.feePrice, farm.farmId, MoneyType.NEW_ANIMALS_COST, true, true)
				connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_SUCCESS))
			elseif self.object.spec_husbandryAnimals ~= nil then
				RealisticLivestock_PlaceableHusbandryAnimals.addAnimals(self.object, _, self.subTypeIndex, self.numAnimals, self.age)
				g_currentMission:addMoney(self.buyPrice + self.feePrice, farm.farmId, MoneyType.NEW_ANIMALS_COST, true, true)
				connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_SUCCESS))
			end

		else
			connection:sendEvent(AnimalBuyEvent.newServerToClient(errorCode))
		end

	else
		connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_ERROR_NO_PERMISSION))
		return
	end
end

AnimalBuyEvent.run = Utils.overwrittenFunction(AnimalBuyEvent.run, RL_AnimalScreenDealer.run)



function RL_AnimalScreenDealer:getSourcePrice(_, animalTypeIndex, index, numAnimals)

	--local animal = self.sourceItems[animalTypeIndex][index]
	local animal

	for i, animalType in pairs(self.sourceAnimalTypes) do

		if animalType.typeIndex == animalTypeIndex then
			animal = self.sourceItems[i][index]
			break
		end

	end

	local transportationFee = animal:getTranportationFee(numAnimals)
	local price = animal:getPrice() * numAnimals
	return true, price, transportationFee, price + transportationFee
end

AnimalScreenDealer.getSourcePrice = Utils.overwrittenFunction(AnimalScreenDealer.getSourcePrice, RL_AnimalScreenDealer.getSourcePrice)


function RL_AnimalScreenDealer:getApplySourceConfirmationText(_, animalTypeIndex, index, numAnimals)

	local _, _, _, totalPrice = self:getSourcePrice(animalTypeIndex, index, numAnimals)
	local confirmText = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.CONFIRM_BUY)

	if numAnimals == 1 then confirmText = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.CONFIRM_BUY_SINGULAR) end

	--local animal = self.sourceItems[animalTypeIndex][index]
	local animal

	for i, animalType in pairs(self.sourceAnimalTypes) do

		if animalType.typeIndex == animalTypeIndex then
			animal = self.sourceItems[i][index]
			break
		end

	end


	return string.namedFormat(confirmText, "numAnimals", numAnimals, "animalType", animal:getTitle() .. ", " .. animal:getName(), "price", g_i18n:formatMoney(math.abs(totalPrice), 0, true, true))
end

AnimalScreenDealer.getApplySourceConfirmationText = Utils.overwrittenFunction(AnimalScreenDealer.getApplySourceConfirmationText, RL_AnimalScreenDealer.getApplySourceConfirmationText)


function RL_AnimalScreenDealer:getSourceItems(animalTypeIndex)

	for index, animalType in pairs(self.sourceAnimalTypes) do

		if animalType.typeIndex == animalTypeIndex then return self.sourceItems[index] end

	end

	return {}

end

AnimalScreenDealer.getSourceItems = RL_AnimalScreenDealer.getSourceItems


function RL_AnimalScreenDealer:getSourceData(_, index)

	local animalType = self.sourceAnimalTypes[index]

	if animalType == nil then return {}, g_i18n:getText("ui_animalTransport") end

	return self.husbandries[animalType.typeIndex] or {}, g_i18n:getText("ui_animalTransport")

	--return self.husbandries[index] or {}, g_i18n:getText("ui_animalTransport")

end

AnimalScreenDealer.getSourceData = Utils.overwrittenFunction(AnimalScreenDealer.getSourceData, RL_AnimalScreenDealer.getSourceData)