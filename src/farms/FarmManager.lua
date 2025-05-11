RL_FarmManager = {}


function RL_FarmManager:loadFromXMLFile(superFunc, path)

	local returnValue = superFunc(self, path)

    local animalSystem = g_currentMission.animalSystem
    animalSystem:initialiseCountries()

    if g_currentMission:getIsServer() then
        animalSystem:loadFromXMLFile()
        animalSystem:validateFarms()
    end

    return returnValue

end

FarmManager.loadFromXMLFile = Utils.overwrittenFunction(FarmManager.loadFromXMLFile, RL_FarmManager.loadFromXMLFile)