--[[----------------------------------------------------------------------------
	Classic Guild Frame

	Restoring the old GuildUI for BfA

	(c) 2018 -
	Sanex @ EU-Arathor / ahak @ Curseforge

	/run GuildFrame_Toggle()
	/run ClassicGuildFrame_Toggle()
----------------------------------------------------------------------------]]--

local originalShowUIPanel = ShowUIPanel
function ShowUIPanel(frame, force)
	--print("Hook:", frame:GetName()) -- Debug
	if frame:GetName() == "CommunitiesFrame" then -- Replace CommunitiesFrame with ClassicGuildUI
		return ClassicGuildFrame_Toggle()
	else -- Let rest go through as usual
		return originalShowUIPanel(frame, force)
	end
end
