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

	-- Options
	L.enableTabs = "Enable Tabs:"
	L.cWarningText = "You have to leave at least one tab enabled!"
	L.defaultTab = "Default Tab for the first opening:"
	L.dWarningText = "You have to select tab that is enabled!"
	L.miniModeDefault = "Open Chat in Minimized-mode"
	L.miniModeDefaultHelp = "Pressing the Maximize/Minimize-button on the Chat-frame will change this."
	L.highlightStyle = "Chat-tab Highlight"
	L.highlightStyleHelp = "If you have selected highlight style, you get pulsing glow in the Chat-tab to notify you when there are unread messages in the Chat-frame. Select style from the dropdown menu on the left and see the preview on the right."
	--L.alwaysDefault = "Always open to Default Tab:"
	--L.alwaysDefaultHelp = "If disabled, addon will open to the last open tab after first opening."

	-- Style names , "None" is same as _G.NONE
	L.styleBlueHighlight = "Blue Highlight"
	L.styleYellowHighlight = "Yellow Highlight"
	L.styleBlueBorder = "Blue Border"
	L.styleGreenSphere = "Green Sphere"
	L.styleGoldSphere = "Golden Sphere"
	L.styleWhiteLine = "White Line"

	if LOCALE == "deDE" then

	elseif LOCALE == "esES" then

	elseif LOCALE == "esMX" then

	elseif LOCALE == "frFR" then

	elseif LOCALE == "itIT" then

	elseif LOCALE == "ptBR" then

	elseif LOCALE == "ruRU" then
		-- By Hubbotu
		--L["alwaysDefault"] = "Всегда открывайте вкладку по умолчанию:"
		--L["alwaysDefaultHelp"] = "Если отключено, аддон откроется до последней открытой вкладки после первого открытия."
		L["cWarningText"] = "Вы должны оставить хотя бы одну вкладку включенной!"
		L["defaultTab"] = "Вкладка По умолчанию для первого открытия:"
		L["dWarningText"] = "Вы должны выбрать вкладку, которая включена!"
		L["enableTabs"] = "Включить вкладки:"
		L["highlightStyle"] = "Выделите вкладку чата"
		L["highlightStyleHelp"] = "Если вы выбрали стиль выделения, вы получите пульсирующий свет на вкладке Чата, чтобы уведомить вас, когда в чате есть непрочитанные сообщения. Выберите стиль в выпадающем меню слева и посмотрите предварительный просмотр справа."
		L["miniModeDefault"] = "Открыть чат в мини-режиме"
		L["miniModeDefaultHelp"] = "Нажмите кнопку максимизировать / максимизировать на чате изменит его."
		L["styleBlueBorder"] = "Голубая граница"
		L["styleBlueHighlight"] = "Голубая подсветка"
		L["styleGoldSphere"] = "Золотая сфера"
		L["styleGreenSphere"] = "Зеленая сфера"
		L["styleWhiteLine"] = "Белая линия"
		L["styleYellowHighlight"] = "Желтая подсветка"

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

local highlightStyles = { -- Styles for Chat-tab Highlight
	{ name = NONE, tex = "", l = 0, r = 1, t = 0, b = 1 }, -- None
	{ name = L.styleBlueHighlight, tex = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight", l = 0, r = 1, t = 0, b = 1 }, -- Highlight
	{ name = L.styleYellowHighlight, tex = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight-yellow", l = 0, r = 1, t = 0, b = 1 }, -- Highlight - Yellow
	{ name = L.styleBlueBorder, tex = "Interface\\GMChatFrame\\UI-GMStatusFrame-Pulse", l = 0, r = 1, t = 0, b = 1 }, -- GMStatusFrame - Pulse
	{ name = L.styleGreenSphere, tex = "Interface\\LevelUp\\LevelUpTex", l = 287/512, r = 510/512, t = 364/512, b = 249/512 }, -- LevelUp - Green
	{ name = L.styleGoldSphere, tex = "Interface\\LevelUp\\LevelUpTex", l = 287/512, r = 510/512, t = 239/512, b = 124/512 }, -- LevelUp - Gold
	{ name = L.styleWhiteLine, tex = "Interface\\CHATFRAME\\ChatFrameTab-NewMessage", l = 0, r = 1, t = 1, b = 0 }, -- Chat - NewMessage
}

local defaultStyle = 5
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
	openAlwaysToDefault = false,
	highlightStyle = defaultStyle,
	highlightHold = .5
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

local function _stopFlashing() -- If flashing, stop flashing
	local glow = classicTabFrame.Tabs[1].Glow
	if UIFrameIsFlashing(glow) then
		UIFrameFlashStop(glow)
	end
end

local function _checkUnreadMessages(calledFrom) -- UIFrameFlash the Glow-texture (other option was SetButtonPulse() on the tab)
	if not cfg.show[1] then return end -- Chat tab is hidden
	local unreadMessages = CommunitiesUtil.DoesAnyCommunityHaveUnreadMessages()
	local glow = classicTabFrame.Tabs[1].Glow

	if cfg.highlightStyle > #highlightStyles then
		cfg.highlightStyle = defaultStyle
	end

	--print("_checkUnreadMessages", tostring(unreadMessages), calledFrom)
	if cfg.highlightStyle > 1 and unreadMessages and _G.CommunitiesFrame and not _G.CommunitiesFrame:IsShown() then -- Unread messages
		local tex = highlightStyles[cfg.highlightStyle].tex
		local l, r, t, b = highlightStyles[cfg.highlightStyle].l, highlightStyles[cfg.highlightStyle].r, highlightStyles[cfg.highlightStyle].t, highlightStyles[cfg.highlightStyle].b
		glow:SetTexture(tex)
		glow:SetTexCoord(l, r, t, b)
		if not UIFrameIsFlashing(glow) then -- Not flashing, start flashing
			glow:Show()
			UIFrameFlash(glow, 1, 1, -1, false, cfg.highlightHold, cfg.highlightHold, ADDON_NAME)
		end
	else -- No unread messages
		_stopFlashing()
	end
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

		_stopFlashing() -- Stop flashing if flashing
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
		_checkUnreadMessages("_TabClick")

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
	if #classicTabFrame.Tabs >= 6 then return end -- Buttons already crated
	for i = 1, 6 do
		local tab = CreateFrame("Button", "ClassicTab"..i, classicTabFrame, "CharacterFrameTabButtonTemplate", i)
		if i == 1 then
			tab:SetPoint("BOTTOMLEFT", 0, -20)

			local t = tab:CreateTexture("$parentHighlightGlow", "ARTWORK")
			t:SetPoint("TOPLEFT", 12, -2)
			t:SetPoint("BOTTOMRIGHT", -12, 7)
			t:SetBlendMode("ADD")
			t:Hide()
			tab.Glow = t
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
	if not classicTabFrame.Tabs then -- No tabs yet, create them
		_createClassicTabs()
	end
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

	_checkUnreadMessages("_HandleTabs")

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
	if not classicTabFrame.Tabs then
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

		self:RegisterEvent("STREAM_VIEW_MARKER_UPDATED") -- Chat updated

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

function f:STREAM_VIEW_MARKER_UPDATED(event, clubId, streamId, lastUnreadTime)
	_checkUnreadMessages("STREAM_VIEW_MARKER_UPDATED")
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
		if not classicTabFrame.Tabs then -- Create Tabs if they aren't created yet.
			_createClassicTabs()
		end
		local cfg = ClassicGuildFrameConfig
		local Title, EnableTabsText, CWarningText, DefaultDropDownText, DWarningText, DefaultDropDown
		local MiniModeDefaultText, MiniModeDefaultCheckBox, MiniModeDefaultHelpText
		local HighlightDropDownText, HighlightDropDown, HighlightTestTab, HighlightDropDownHelpText
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
		local function DefaultDropDownOnClick(button)
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
				info.func = DefaultDropDownOnClick
				L_UIDropDownMenu_AddButton(info)
			end
		end
		local function _TestTabUpdate()
			if cfg.highlightStyle > #highlightStyles then
				cfg.highlightStyle = defaultStyle
			end

			local glow = HighlightTestTab.Glow
			if UIFrameIsFlashing(glow) then
				UIFrameFlashStop(glow)
			end
			if glow and cfg.highlightStyle > 1 then
				local tex = highlightStyles[cfg.highlightStyle].tex
				local l, r, t, b = highlightStyles[cfg.highlightStyle].l, highlightStyles[cfg.highlightStyle].r, highlightStyles[cfg.highlightStyle].t, highlightStyles[cfg.highlightStyle].b
				glow:SetTexture(tex)
				glow:SetTexCoord(l, r, t, b)
				if not UIFrameIsFlashing(glow) then
					glow:Show()
					UIFrameFlash(glow, 1, 1, -1, false, cfg.highlightHold, cfg.highlightHold, ADDON_NAME)
				end
			end
		end
		local function HighlightDropDownOnClick(button)
			cfg.highlightStyle = button.value
			L_UIDropDownMenu_SetSelectedValue(_G[ADDON_NAME.."OptionsHighlightDropDown"], cfg.highlightStyle)
			_TestTabUpdate()
		end
		local function HighlightDropDown_Initialize()
			local info = L_UIDropDownMenu_CreateInfo()

			for i, data in ipairs(highlightStyles) do
				info.text = highlightStyles[i].name
				info.value = i
				info.checked = i == cfg.highlightStyle
				info.func = HighlightDropDownOnClick
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

		DefaultDropDownText = self:CreateFontString("$parentDefaultDropDownText", "ARTWORK", "GameFontHighlight")
		DefaultDropDownText:SetPoint("TOPLEFT", CWarningText, "BOTTOMLEFT", -10, -8)
		DefaultDropDownText:SetJustifyH("LEFT")
		DefaultDropDownText:SetText(L.defaultTab)

		DefaultDropDown = CreateFrame("Button", "$parentDefaultDropDown", self, "L_UIDropDownMenuTemplate")
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
		MiniModeDefaultHelpText:SetWidth(571)
		MiniModeDefaultHelpText:SetJustifyH("LEFT")
		MiniModeDefaultHelpText:SetText(L.miniModeDefaultHelp)

		HighlightDropDownText = self:CreateFontString("$parentHighlightDropDownText", "ARTWORK", "GameFontHighlight")
		HighlightDropDownText:SetPoint("TOPLEFT", MiniModeDefaultHelpText, "BOTTOMLEFT", -10, -(8 * 2 + CWarningText:GetHeight())) -- Add extra pixels to make the space appear as big as others
		HighlightDropDownText:SetJustifyH("LEFT")
		HighlightDropDownText:SetText(L.highlightStyle)

		HighlightDropDown = CreateFrame("Button", "$parentHighlightDropDown", self, "L_UIDropDownMenuTemplate")
		L_UIDropDownMenu_Initialize(HighlightDropDown, HighlightDropDown_Initialize)
		L_UIDropDownMenu_SetSelectedValue(HighlightDropDown, cfg.highlightStyle)
		L_UIDropDownMenu_JustifyText(HighlightDropDown, "CENTER")
		HighlightDropDown:SetPoint("TOPLEFT", HighlightDropDownText, "BOTTOMLEFT", 10, -12)

		HighlightTestTab = CreateFrame("Button", "$parentHighlightTestTab", self, "CharacterFrameTabButtonTemplate")
		HighlightTestTab:SetPoint("TOP", HighlightDropDown)
		HighlightTestTab:SetText(tabNames[1])
		PanelTemplates_DeselectTab(HighlightTestTab)
		PanelTemplates_TabResize(HighlightTestTab, 0)
		HighlightTestTab:SetPoint("LEFT", floor(self:GetWidth()/2 - HighlightTestTab:GetWidth()/2), 0)

		local t = HighlightTestTab:CreateTexture("$parentHighlightGlow", "ARTWORK")
		t:SetPoint("TOPLEFT", 12, -2)
		t:SetPoint("BOTTOMRIGHT", -12, 7)
		t:SetBlendMode("ADD")
		HighlightTestTab.Glow = t
		_TestTabUpdate()

		HighlightDropDownHelpText = self:CreateFontString("$parentHighlightDropDownHelpText", "ARTWORK", "GameFontNormalSmall")
		HighlightDropDownHelpText:SetPoint("TOPLEFT", HighlightDropDown, "BOTTOMLEFT", 0, -8)
		HighlightDropDownHelpText:SetWidth(571)
		HighlightDropDownHelpText:SetJustifyH("LEFT")
		HighlightDropDownHelpText:SetText(L.highlightStyleHelp)

		self:SetScript("OnShow", nil)
	end)
end
