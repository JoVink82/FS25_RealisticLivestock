RealisticLivestock_PlayerInputComponent = {}

function RealisticLivestock_PlayerInputComponent:update(_)

    if self.player.isOwner then

        if g_inputBinding:getContextName() == PlayerInputComponent.INPUT_CONTEXT_NAME then

            local currentMission = g_currentMission
            local accessHandler = currentMission.accessHandler
            local vehicleInRange = currentMission.interactiveVehicleInRange
            local canAccess

            if vehicleInRange == nil then
                canAccess = false
            else
                canAccess = accessHandler:canPlayerAccess(vehicleInRange, self.player)
            end

            local closestNode = self.player.targeter:getClosestTargetedNodeFromType(PlayerInputComponent)
            self.player.hudUpdater:setCurrentRaycastTarget(closestNode)

            if not canAccess and closestNode ~= nil then

                local husbandryId, animalId = getAnimalFromCollisionNode(closestNode)

                if husbandryId ~= nil and husbandryId ~= 0 then

                    local clusterHusbandry = currentMission.husbandrySystem:getClusterHusbandryById(husbandryId)
                    if clusterHusbandry ~= nil then
                        local placeable = clusterHusbandry:getPlaceable()
                        local animal = clusterHusbandry:getClusterByAnimalId(animalId, husbandryId)

                        if animal ~= nil and (accessHandler:canFarmAccess(self.player.farmId, placeable) and animal:getRidableFilename() ~= nil) then
                            self.rideablePlaceable = placeable
                            self.rideableCluster = animal

                            local name = animal.getName == nil and "" or animal:getName()
                            local text = string.format(g_i18n:getText("action_rideAnimal"), name)

                            g_inputBinding:setActionEventText(self.enterActionId, text)
                            g_inputBinding:setActionEventActive(self.enterActionId, true)
                        end

                    end

                end

            end

        end

    end

end

PlayerInputComponent.update = Utils.appendedFunction(PlayerInputComponent.update, RealisticLivestock_PlayerInputComponent.update)


function RealisticLivestock_PlayerInputComponent:registerGlobalPlayerActionEvents()

    VisualAnimalsDialog.register()

    g_inputBinding:registerActionEvent(InputAction.VisualAnimalsDialog, VisualAnimalsDialog, VisualAnimalsDialog.show, false, true, false, true, nil, true)

end


PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(PlayerInputComponent.registerGlobalPlayerActionEvents, RealisticLivestock_PlayerInputComponent.registerGlobalPlayerActionEvents)


function RealisticLivestock_PlayerInputComponent.onFinishedRideBlending(superFunc, _, args)
    local placeable = args[1]
    placeable:startRiding(args[2].farmId .. " " .. args[2].uniqueId, args[3])
end

PlayerInputComponent.onFinishedRideBlending = Utils.overwrittenFunction(PlayerInputComponent.onFinishedRideBlending, RealisticLivestock_PlayerInputComponent.onFinishedRideBlending)