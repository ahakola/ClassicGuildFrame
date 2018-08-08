--[[----------------------------------------------------------------------------
	Classic Guild Frame

	Restoring the old GuildUI for BfA

	(c) 2018 -
	Sanex @ EU-Arathor / ahak @ Curseforge

	/run GuildFrame_Toggle()
	/run ToggleCommunitiesFrame()
	/run ToggleGuildFinder()
----------------------------------------------------------------------------]]--
local ADDON_NAME, _ = ...

local L = {}
do -- Translations
	local LOCALE = GetLocale()

	L.enableTabs = "Enable Tabs:"
	L.cWarningText = "You have to leave at least one tab enabled!"
	L.defaultTab = "Default Tab for the first opening:"
	L.dWarningText = "You have to select tab that is enabled!"
	L.miniModeDefault = "Open Chat in Minimized-mode"
	L.miniModeDefaultHelp = "Pressing the Maximize/Minimize-button on the Chat-frame will change this."
	--L.alwaysDefault = "Always open to Default Tab:"
	--L.alwaysDefaultHelp = "If disabled, addon will open to the last open tab after first opening."

	if LOCALE == "deDE" then

	elseif LOCALE == "esES" then

	elseif LOCALE == "esMX" then

	elseif LOCALE == "frFR" then

	elseif LOCALE == "itIT" then

	elseif LOCALE == "ptBR" then

	elseif LOCALE == "ruRU" then
		-- By Hubbotu
		L["enableTabs"] = "Включить вкладки:"
		L["cWarningText"] = "Вы должны оставить хотя бы одну вкладку включенной!"
		L["defaultTab"] = "Вкладка По умолчанию для первого открытия:"
		L["dWarningText"] = "Вы должны выбрать вкладку, которая включена!"
		L["alwaysDefault"] = "Всегда открывайте вкладку по умолчанию:"
		L["alwaysDefaultHelp"] = "Если отключено, аддон откроется до последней открытой вкладки после первого открытия."
	elseif LOCALE == "koKR" then

	elseif LOCALE == "zhCN" then

	elseif LOCALE == "zhTW" then

	end
end

local communitiesTabs = { -- Parent-keys of CommunitiesUI sidetabs
	"ChatTab",
	"RosterTab",
	"GuildBenefitsTab",
	"GuildInfoTab"
}

local tabNames = { -- Names of the tabs
	COMMUNITIES_CHAT_TAB_TOOLTIP,
	GUILD_TAB_NEWS,
	GUILD_TAB_ROSTER,
	GUILD_TAB_PERKS,
	GUILD_TAB_REWARDS,
	GUILD_TAB_INFO
}

local defaults = { -- This table defines the addon's default settings:
	show = {
		true, -- Chat
		true, -- News
		true, -- Roster
		true, -- Perks
		true, -- Rewards
		true -- Info
	},
	miniMode = false,
	defaultTab = 1,
	openAlwaysToDefault = false
}

local cfg
local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, event, ...)
end)
f:RegisterEvent("ADDON_LOADED")

local classicTabFrame = CreateFrame("Frame", ADDON_NAME.."Tabs", UIParent)
classicTabFrame:SetSize(10, 10)

local function initDB(db, defaults) -- This function copies values from one table into another:
	if type(db) ~= "table" then db = {} end
	if type(defaults) ~= "table" then return db end
	for k, v in pairs(defaults) do
		if type(v) == "table" then
			db[k] = initDB(db[k], v)
		elseif type(v) ~= type(db[k]) then
			db[k] = v
		end
	end
	return db
end

local function _TabShow(self, ...) -- Resize tabs on show
	PanelTemplates_TabResize(self, 0)
end

local function _TabClick(self, ...) -- Handle Tab clicks
	local tabIndex = self:GetID();
	PanelTemplates_SetTab(classicTabFrame, tabIndex)
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)

	if tabIndex == 1 then -- Chat
		HideUIPanel(_G.GuildFrame)
		HideUIPanel(_G.LookingForGuildFrame)
		ShowUIPanel(_G.CommunitiesFrame)
	elseif tabIndex > 1 then -- GuildUI
		if IsInGuild() then
			GuildFrame_LoadUI()
			if GuildFrame_Toggle then
				ShowUIPanel(_G.GuildFrame)
			end
		else
			LookingForGuildFrame_LoadUI()
			if LookingForGuildFrame_Toggle then
				ShowUIPanel(_G.LookingForGuildFrame)
			end
		end
		HideUIPanel(_G.CommunitiesFrame)

		if ( tabIndex == 2 ) then -- News
			GuildFrame_TabClicked(_G["GuildFrameTab1"])
		elseif ( tabIndex == 3 ) then -- Roster
			GuildFrame_TabClicked(_G["GuildFrameTab2"])
		elseif ( tabIndex == 4 ) then -- Perks
			GuildFrame_TabClicked(_G["GuildFrameTab3"])
		elseif ( tabIndex == 5 ) then -- Rewards
			GuildFrame_TabClicked(_G["GuildFrameTab4"])
		elseif ( tabIndex == 6 ) then -- Info
			GuildFrame_TabClicked(_G["GuildFrameTab5"])
		end
	end
end

local function _createClassicTabs() -- Create new tabs for Classic Guild Frame
	classicTabFrame.Tabs = classicTabFrame.Tabs or {}
	for i = 1, 6 do
		local tab = CreateFrame("Button", "ClassicTab"..i, classicTabFrame, "CharacterFrameTabButtonTemplate", i)
		if i == 1 then
			tab:SetPoint("BOTTOMLEFT", 0, -20)
		else
			tab:SetPoint("LEFT", classicTabFrame.Tabs[i-1], "RIGHT", -15, 0)
		end
		tab:SetText(tabNames[i])
		tab:SetScript("OnShow", _TabShow)
		tab:SetScript("OnClick", _TabClick)

		classicTabFrame.Tabs[i] = tab
	end
	PanelTemplates_SetNumTabs(classicTabFrame, 6)
	classicTabFrame:Hide()
end

local function _HandleTabs() -- Handle hiding and anchoring Classic Guild Frame tabs
	local firstTab = false
	local previousTab = 0
	for i, show in ipairs(cfg.show) do
		if show then
			classicTabFrame.Tabs[i]:Show()
			classicTabFrame.Tabs[i]:ClearAllPoints()
			if not firstTab then
				firstTab = true
				classicTabFrame.Tabs[i]:SetPoint("BOTTOMLEFT", 0, -20)
			else
				classicTabFrame.Tabs[i]:SetPoint("LEFT", classicTabFrame.Tabs[previousTab], "RIGHT", -15, 0)
			end
			previousTab = i
		else
			classicTabFrame.Tabs[i]:Hide()
		end
	end

	if not PanelTemplates_GetSelectedTab(classicTabFrame) then
		_TabClick(classicTabFrame.Tabs[cfg.defaultTab])
	end
end

local function _hideBlizzardTabs(self) -- Hide Blizzard's own tabs
	if self:GetName() == "CommunitiesFrame" then -- Blizzard_Communities
		for _, key in ipairs(communitiesTabs) do
			_G.CommunitiesFrame[key]:Hide()
		end
	else -- Blizzard_GuildUI
		for i = 1, 5 do
			_G["GuildFrameTab"..i]:Hide()
		end
	end
	if not _G["ClassicTab1"] then
		_createClassicTabs()
	end
	classicTabFrame:SetParent(self)
	classicTabFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	classicTabFrame:Show()
	_HandleTabs()
end

local function _MinimizeHook()
	cfg.miniMode = true
end

local function _MaximizeHook()
	cfg.miniMode = false
end

function f:ADDON_LOADED(event, addon)
	if addon == ADDON_NAME then
		ClassicGuildFrameConfig = initDB(ClassicGuildFrameConfig, defaults)
		cfg = ClassicGuildFrameConfig

		if IsAddOnLoaded("Blizzard_Communities") and _G.CommunitiesFrame then
			_G.CommunitiesFrame:HookScript("OnShow", _hideBlizzardTabs)
			hooksecurefunc(_G.CommunitiesFrame.MaximizeMinimizeFrame, "Minimize", _MinimizeHook)
			hooksecurefunc(_G.CommunitiesFrame.MaximizeMinimizeFrame, "Maximize", _MaximizeHook)
		end
		if IsAddOnLoaded("Blizzard_GuildUI") and _G.GuildFrame then
			_G.GuildFrame:HookScript("OnShow", _hideBlizzardTabs)
		end
	elseif addon == "Blizzard_Communities" then
		if IsAddOnLoaded(ADDON_NAME) then
			_G.CommunitiesFrame:HookScript("OnShow", _hideBlizzardTabs)
			hooksecurefunc(_G.CommunitiesFrame.MaximizeMinimizeFrame, "Minimize", _MinimizeHook)
			hooksecurefunc(_G.CommunitiesFrame.MaximizeMinimizeFrame, "Maximize", _MaximizeHook)
		end
		if IsAddOnLoaded("Blizzard_GuildUI") and _G.GuildFrame then
			_G.GuildFrame:HookScript("OnShow", _hideBlizzardTabs)
		end
	elseif addon == "Blizzard_GuildUI" then
		if IsAddOnLoaded(ADDON_NAME) then
			_G.GuildFrame:HookScript("OnShow", _hideBlizzardTabs)
		end
		if IsAddOnLoaded("Blizzard_Communities") and _G.CommunitiesFrame then
			_G.CommunitiesFrame:HookScript("OnShow", _hideBlizzardTabs)
			hooksecurefunc(_G.CommunitiesFrame.MaximizeMinimizeFrame, "Minimize", _MinimizeHook)
			hooksecurefunc(_G.CommunitiesFrame.MaximizeMinimizeFrame, "Maximize", _MaximizeHook)
		end
	else return end
end

local originalShowUIPanel = ShowUIPanel
function ShowUIPanel(frame, force)
	local function _checkChatFrameSize() -- Set Chat-frame Maximized/Minimized based on setting
		if cfg.miniMode then
			_G.CommunitiesFrame.MaximizeMinimizeFrame:Minimize()
		else
			_G.CommunitiesFrame.MaximizeMinimizeFrame:Maximize()
		end
	end

	--print("ShowUIPanel Hook:", frame:GetName()) -- Debug
	if frame and frame:GetName() == "CommunitiesFrame" then -- Replace CommunitiesFrame with ClassicGuildUI
		if not _G.GuildFrame then
			GuildFrame_LoadUI()
		end
		if _G.GuildFrame:IsShown() then -- GuildUI is open, close it to mimic Toggle-action
			HideUIPanel(_G.GuildFrame)
			return
		else
			if not PanelTemplates_GetSelectedTab(classicTabFrame) then
				if cfg.defaultTab == 1 then
					_checkChatFrameSize()
					return originalShowUIPanel(frame, force)
				else
					return originalShowUIPanel(_G.GuildFrame, force)
				end
			else
				if PanelTemplates_GetSelectedTab(classicTabFrame) == 1 then
					_checkChatFrameSize()
					return originalShowUIPanel(frame, force)
				else
					return originalShowUIPanel(_G.GuildFrame, force)
				end
			end
		end
	else -- Let rest go through as usual
		return originalShowUIPanel(frame, force)
	end
end

do -- Blizzard Options
	local Options = CreateFrame("Frame", ADDON_NAME.."Options", InterfaceOptionsFramePanelContainer)
	Options.name = ADDON_NAME
	InterfaceOptions_AddCategory(Options)

	Options:Hide()
	Options:SetScript("OnShow", function(self)
		local cfg = ClassicGuildFrameConfig
		local Title, EnableTabsText, CWarningText, DefaultDropDownText, DWarningText, DefaultDropDown, MiniModeDefaultText, MiniModeDefaultCheckBox, MiniModeDefaultHelpText
		local function CheckBoxOnClick(button)
			local checked = not not button:GetChecked()

			PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)

			-- Make sure at least one tab is enabled
			local count = 0
			for _, show in ipairs(cfg.show) do
				if show then
					count = count + 1
				end
			end
			if count > 1 or (count == 1 and checked) then
				cfg.show[button:GetID()] = checked
				CWarningText:Hide()
			else
				button:SetChecked(true)
				UIFrameFadeOut(CWarningText, 5, 1, 0)
			end

			if not checked and cfg.defaultTab == button:GetID() then -- Default tab was hidden, select new one
				for i, show in ipairs(cfg.show) do
					if show then
						cfg.defaultTab = i
						L_UIDropDownMenu_SetSelectedValue(_G[ADDON_NAME.."OptionsDefaultDropDown"], cfg.defaultTab)
						_TabClick(classicTabFrame.Tabs[i])
						break
					end
				end
			end
			if not cfg.show[PanelTemplates_GetSelectedTab(classicTabFrame)] then
				_TabClick(classicTabFrame.Tabs[cfg.defaultTab])
			end
			_HandleTabs()
		end
		local function DropDownOnClick(button)
			if cfg.show[button.value] then
				cfg.defaultTab = button.value
				L_UIDropDownMenu_SetSelectedValue(_G[ADDON_NAME.."OptionsDefaultDropDown"], cfg.defaultTab)
				DWarningText:Hide()
				_TabClick(classicTabFrame.Tabs[button.value])
			else
				UIFrameFadeOut(DWarningText, 5, 1, 0)
			end
		end
		local function DefaultDropDown_Initialize()
			local info = L_UIDropDownMenu_CreateInfo()

			for i, name in ipairs(tabNames) do
				info.text = tabNames[i]
				info.value = i
				info.checked = i == cfg.defaultTab
				info.func = DropDownOnClick
				L_UIDropDownMenu_AddButton(info)
			end
		end

		Title = self:CreateFontString("$parentTitle", "ARTWORK", "GameFontNormalLarge")
		Title:SetPoint("TOPLEFT", 16, -16)
		Title:SetText(ADDON_NAME)

		EnableTabsText = self:CreateFontString("$parentEnableTabs", "ARTWORK", "GameFontHighlight")
		EnableTabsText:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -8)
		EnableTabsText:SetJustifyH("LEFT")
		EnableTabsText:SetText(L.enableTabs)

		for i = 1, #tabNames do
			local checkbox = CreateFrame("CheckButton", "$parentCheckButton"..i, self, "InterfaceOptionsCheckButtonTemplate", i)
			if i == 1 then
				checkbox:SetPoint("TOPLEFT", EnableTabsText, "BOTTOMLEFT", 10, -8)
			else
				checkbox:SetPoint("TOPLEFT", "$parentCheckButton"..i-1, "BOTTOMLEFT", 0, -8)
			end
			checkbox.Text:SetText(tabNames[i])
			checkbox:SetScript("OnClick", CheckBoxOnClick)
			checkbox:SetChecked(cfg.show[i])
		end

		CWarningText = self:CreateFontString("$parentCWarningText", "ARTWORK", "GameFontNormalSmall")
		CWarningText:SetPoint("TOPLEFT", "$parentCheckButton"..#tabNames, "BOTTOMLEFT", 0, -8)
		CWarningText:SetJustifyH("LEFT")
		CWarningText:SetText(L.cWarningText)
		CWarningText:Hide()

		local DefaultDropDownText = self:CreateFontString("$parentDefaultDropDown", "ARTWORK", "GameFontHighlight")
		DefaultDropDownText:SetPoint("TOPLEFT", CWarningText, "BOTTOMLEFT", -10, -8)
		DefaultDropDownText:SetJustifyH("LEFT")
		DefaultDropDownText:SetText(L.defaultTab)

		local DefaultDropDown = CreateFrame("Button", "$parentDefaultDropDown", self, "L_UIDropDownMenuTemplate")
		L_UIDropDownMenu_Initialize(DefaultDropDown, DefaultDropDown_Initialize)
		L_UIDropDownMenu_SetSelectedValue(DefaultDropDown, cfg.defaultTab)
		L_UIDropDownMenu_JustifyText(DefaultDropDown, "CENTER")
		DefaultDropDown:SetPoint("TOPLEFT", DefaultDropDownText, "BOTTOMLEFT", 10, -12)

		DWarningText = self:CreateFontString("$parentCWarningText", "ARTWORK", "GameFontNormalSmall")
		DWarningText:SetPoint("TOPLEFT", DefaultDropDown, "BOTTOMLEFT", 0, -8)
		DWarningText:SetJustifyH("LEFT")
		DWarningText:SetText(L.dWarningText)
		DWarningText:Hide()


		MiniModeDefaultText = self:CreateFontString("$parentMiniModeDefault", "ARTWORK", "GameFontHighlight")
		MiniModeDefaultText:SetPoint("TOPLEFT", DWarningText, "BOTTOMLEFT", -10, -8)
		MiniModeDefaultText:SetJustifyH("LEFT")
		MiniModeDefaultText:SetText(L.miniModeDefault)

		MiniModeDefaultCheckBox = CreateFrame("CheckButton", "$parentMiniModeDefaultCheckButton", self, "InterfaceOptionsCheckButtonTemplate")
		MiniModeDefaultCheckBox:SetPoint("TOPLEFT", MiniModeDefaultText, "BOTTOMLEFT", 10, -8)
		MiniModeDefaultCheckBox.Text:SetText(MINIMIZE)
		MiniModeDefaultCheckBox:SetScript("OnClick", function(button)
			local checked = not not button:GetChecked()

			PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)

			cfg.miniMode = checked
		end)
		MiniModeDefaultCheckBox:SetScript("OnShow", function(self)
			-- This can be changed outside of Options so we need it to be reactive
			self:SetChecked(cfg.miniMode)
		end)

		MiniModeDefaultHelpText = self:CreateFontString("$parentMiniModeDefaultHelp", "ARTWORK", "GameFontNormalSmall")
		MiniModeDefaultHelpText:SetPoint("TOPLEFT", MiniModeDefaultCheckBox, "BOTTOMLEFT", 0, -8)
		MiniModeDefaultHelpText:SetJustifyH("LEFT")
		MiniModeDefaultHelpText:SetText(L.miniModeDefaultHelp)

		self:SetScript("OnShow", nil)
	end)
end
