--[[----------------------------------------------------------------------------
	Classic Guild Frame

	Restoring the old GuildUI for BfA

	(c) 2018 -
	Sanex @ EU-Arathor / ahak @ Curseforge

	/run GuildFrame_Toggle()
	/run ClassicGuildFrame_Toggle()
----------------------------------------------------------------------------]]--
local ADDON_NAME, _ = ...

local originalShowUIPanel = ShowUIPanel
function ShowUIPanel(frame, force)
	--print("Hook:", frame:GetName()) -- Debug
	if frame:GetName() == "CommunitiesFrame" then -- Replace CommunitiesFrame with ClassicGuildUI
		return ClassicGuildFrame_Toggle()
	else -- Let rest go through as usual
		return originalShowUIPanel(frame, force)
	end
end

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

local L = {}
do -- Translations
	local LOCALE = GetLocale()

	L.enableTabs = "Enable Tabs:"
	L.cWarningText = "You have to leave at least one tab enabled!"
	L.defaultTab = "Default Tab for the first opening:"
	L.dWarningText = "You have to select tab that is enabled!"
	L.alwaysDefault = "Always open to Default Tab:"
	L.alwaysDefaultHelp = "If disabled, addon will open to the last open tab after first opening."

	if LOCALE == "deDE" then

	elseif LOCALE == "esES" then

	elseif LOCALE == "esMX" then

	elseif LOCALE == "frFR" then

	elseif LOCALE == "itIT" then

	elseif LOCALE == "ptBR" then

	elseif LOCALE == "ruRU" then

	elseif LOCALE == "koKR" then

	elseif LOCALE == "zhCN" then

	elseif LOCALE == "zhTW" then

	end
end

local tabNames = {
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
	defaultTab = 1,
	openAlwaysToDefault = false
}

local cfg
local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, event, ...)
end)
f:RegisterEvent("ADDON_LOADED")

function f:ADDON_LOADED(event, addon)
	if addon ~= ADDON_NAME then return end
	self:UnregisterEvent(event)

	ClassicGuildFrameConfig = initDB(ClassicGuildFrameConfig, defaults)
	cfg = ClassicGuildFrameConfig

	self.ADDON_LOADED = nil
end

do -- Blizzard Options
	local Options = CreateFrame("Frame", ADDON_NAME.."Options", InterfaceOptionsFramePanelContainer)
	Options.name = ADDON_NAME
	InterfaceOptions_AddCategory(Options)

	Options:Hide()

	Options:SetScript("OnShow", function(self)
		local cfg = ClassicGuildFrameConfig
		local Title, EnableTabsText, CWarningText, DefaultDropDownText, DWarningText, DefaultDropDown, AlwaysDefaultText, AlwaysDefaultCheckBox
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
						break
					end
				end
			end
		end
		local function DefaultDropDown_Initialize()
			local info = L_UIDropDownMenu_CreateInfo()

			for i, name in ipairs(tabNames) do
				info.text = tabNames[i]
				info.value = i
				info.checked = i == cfg.defaultTab
				info.func = function(button)
					if cfg.show[button.value] then
						cfg.defaultTab = button.value
						L_UIDropDownMenu_SetSelectedValue(_G[ADDON_NAME.."OptionsDefaultDropDown"], cfg.defaultTab)
						DWarningText:Hide()
					else
						UIFrameFadeOut(DWarningText, 5, 1, 0)
					end
				end
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

		CWarningText = self:CreateFontString("$parentCWarningText", "ARTWORK", "GameFontNormalSmall") --"GameFontHighlightSmall")
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

		DWarningText = self:CreateFontString("$parentCWarningText", "ARTWORK", "GameFontNormalSmall") --"GameFontHighlightSmall")
		DWarningText:SetPoint("TOPLEFT", DefaultDropDown, "BOTTOMLEFT", 0, -8)
		DWarningText:SetJustifyH("LEFT")
		DWarningText:SetText(L.dWarningText)
		DWarningText:Hide()

		AlwaysDefaultText = self:CreateFontString("$parentAlwaysDefault", "ARTWORK", "GameFontHighlight")
		AlwaysDefaultText:SetPoint("TOPLEFT", DWarningText, "BOTTOMLEFT", -10, -8)
		AlwaysDefaultText:SetJustifyH("LEFT")
		AlwaysDefaultText:SetText(L.alwaysDefault)

		AlwaysDefaultCheckBox = CreateFrame("CheckButton", "$parentAlwaysDefaultCheckButton", self, "InterfaceOptionsCheckButtonTemplate")
		AlwaysDefaultCheckBox:SetPoint("TOPLEFT", AlwaysDefaultText, "BOTTOMLEFT", 10, -8)
		AlwaysDefaultCheckBox.Text:SetText(ENABLE)
		AlwaysDefaultCheckBox:SetScript("OnClick", function(button)
			local checked = not not button:GetChecked()

			PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)

			cfg.openAlwaysToDefault = checked
		end)
		AlwaysDefaultCheckBox:SetChecked(cfg.openAlwaysToDefault)

		AlwaysDefaultHelpText = self:CreateFontString("$parentAlwaysDefault", "ARTWORK", "GameFontNormalSmall")
		AlwaysDefaultHelpText:SetPoint("TOPLEFT", AlwaysDefaultCheckBox, "BOTTOMLEFT", 0, -8)
		AlwaysDefaultHelpText:SetJustifyH("LEFT")
		AlwaysDefaultHelpText:SetText(L.alwaysDefaultHelp)

		self:SetScript("OnShow", nil)
	end)
end