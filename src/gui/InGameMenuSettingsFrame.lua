RL_InGameMenuSettingsFrame = {}


function RL_InGameMenuSettingsFrame:onFrameOpen(_)

	for name, setting in pairs(RLSettings.SETTINGS) do

		if setting.dependancy then
			local dependancy = RLSettings.SETTINGS[setting.dependancy.name]
			if dependancy ~= nil and setting.element ~= nil then setting.element:setDisabled(dependancy.state ~= setting.dependancy.state) end
		end

	end

end

InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, RL_InGameMenuSettingsFrame.onFrameOpen)