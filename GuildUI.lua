UIPanelWindows["ClassicGuildFrame"] = { area = "left", pushable = 1, whileDead = 1 };
local GUILDFRAME_PANELS = { };
local GUILDFRAME_POPUPS = { };
local BUTTON_WIDTH_WITH_SCROLLBAR = 298;
local BUTTON_WIDTH_NO_SCROLLBAR = 320;

function ClassicGuildFrame_OnLoad(self)
	self:RegisterEvent("GUILD_ROSTER_UPDATE");
	self:RegisterEvent("PLAYER_GUILD_UPDATE");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("UPDATE_FACTION");
	self:RegisterEvent("GUILD_RENAME_REQUIRED");
	self:RegisterEvent("REQUIRED_GUILD_RENAME_RESULT");
	ClassicGuildFrame.hasForcedNameChange = GetGuildRenameRequired();
	PanelTemplates_SetNumTabs(self, 6);
	RequestGuildRewards();
--	QueryGuildXP();
	QueryGuildNews();
	C_Calendar.OpenCalendar();		-- to get event data
	ClassicGuildFrame_UpdateTabard();
	ClassicGuildFrame_UpdateFaction();
	local guildName, _, _, realm = GetGuildInfo("player");
	local fullName;
	if (realm) then
		fullName = string.format(FULL_PLAYER_NAME, guildName, realm);
	else
		fullName = guildName
	end
	ClassicGuildFrameTitleText:SetText(fullName);
	local totalMembers, onlineMembers, onlineAndMobileMembers = GetNumGuildMembers();
	ClassicGuildFrameMembersCount:SetText(onlineAndMobileMembers.." / "..totalMembers);
end

function ClassicGuildFrame_OnShow(self)
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
	ClassicGuildFrameTab1:Show();
	ClassicGuildFrameTab3:Show();
	ClassicGuildFrameTab4:Show();
	ClassicGuildFrameTab2:SetPoint("LEFT", ClassicGuildFrameTab1, "RIGHT", -15, 0);
	ClassicGuildFrameTab5:SetPoint("LEFT", ClassicGuildFrameTab4, "RIGHT", -15, 0);
	ClassicGuildFrameTab6:Show();
	if ( not PanelTemplates_GetSelectedTab(self) ) then
		ClassicGuildFrame_TabClicked(ClassicGuildFrameTab1);
	end
	GuildRoster();
	UpdateMicroButtons();
	ClassicGuildNameChangeAlertFrame.topAnchored = true;
	ClassicGuildFrame.hasForcedNameChange = GetGuildRenameRequired();
	ClassicGuildFrame_CheckName();

	if (ClassicGuildFrameTitleText:IsTruncated()) then
		ClassicGuildFrame.TitleMouseover.tooltip = ClassicGuildFrameTitleText:GetText();
	else
		ClassicGuildFrame.TitleMouseover.tooltip = nil;
	end

	-- keep points frame centered
	local pointFrame = ClassicGuildPointFrame;
	pointFrame.SumText:SetText(BreakUpLargeNumbers(GetTotalAchievementPoints(true)));
	local width = pointFrame.SumText:GetStringWidth() + pointFrame.LeftCap:GetWidth() + pointFrame.RightCap:GetWidth() + pointFrame.Icon:GetWidth();
	pointFrame:SetWidth(width);
end

function ClassicGuildFrame_OnHide(self)
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
	UpdateMicroButtons();
	ClassicCloseGuildMenus();
end

function ClassicGuildFrame_Toggle()
	if ( ClassicGuildFrame:IsShown() ) then
		HideUIPanel(ClassicGuildFrame);
	else
		ShowUIPanel(ClassicGuildFrame);
	end
end

function ClassicGuildFrame_OnEvent(self, event, ...)
	if ( event == "GUILD_ROSTER_UPDATE" ) then
		local totalMembers, onlineMembers, onlineAndMobileMembers = GetNumGuildMembers();
		ClassicGuildFrameMembersCount:SetText(onlineAndMobileMembers.." / "..totalMembers);
	elseif ( event == "UPDATE_FACTION" ) then
		ClassicGuildFrame_UpdateFaction();
	elseif ( event == "PLAYER_GUILD_UPDATE" ) then
		if ( IsInGuild() ) then
			local guildName = GetGuildInfo("player");
			ClassicGuildFrameTitleText:SetText(guildName);
			ClassicGuildFrame_UpdateTabard();
		else
			if ( self:IsShown() ) then
				HideUIPanel(self);
			end
		end
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
--		QueryGuildXP();
		QueryGuildNews();
	elseif ( event == "GUILD_RENAME_REQUIRED" ) then
		ClassicGuildFrame.hasForcedNameChange = ...;
		ClassicGuildFrame_CheckName();
	elseif ( event == "REQUIRED_GUILD_RENAME_RESULT" ) then
		local success = ...
		if ( success ) then
			ClassicGuildFrame.hasForcedNameChange = GetGuildRenameRequired();
			ClassicGuildFrame_CheckName();
		else
			UIErrorsFrame:AddMessage(ERR_GUILD_NAME_INVALID, 1.0, 0.1, 0.1, 1.0);
		end
	end
end

function ClassicGuildFrame_UpdateFaction()
	local factionBar = ClassicGuildFactionFrame;
	local gender = UnitSex("player");
	local name, description, standingID, barMin, barMax, barValue, _, _, _, _, _, _, _ = GetGuildFactionInfo();
	local factionStandingtext = GetText("FACTION_STANDING_LABEL"..standingID, gender);
	--Normalize Values
	barMax = barMax - barMin;
	barValue = barValue - barMin;
	ClassicGuildFactionBarLabel:SetText(barValue.." / "..barMax);
	ClassicGuildFactionFrameStanding:SetText(factionStandingtext);
	ClassicGuildBar_SetProgress(ClassicGuildFactionBar, barValue, barMax);
end

function ClassicGuildFrame_UpdateTabard()
	SetLargeGuildTabardTextures("player", ClassicGuildFrameTabardEmblem, ClassicGuildFrameTabardBackground, ClassicGuildFrameTabardBorder);
end

function ClassicGuildFrame_CheckPermissions()
	if ( IsGuildLeader() ) then
		ClassicGuildControlButton:Enable();
	else
		ClassicGuildControlButton:Disable();
	end
	if ( CanGuildInvite() ) then
		ClassicGuildAddMemberButton:Enable();
	else
		ClassicGuildAddMemberButton:Disable();
	end
end

function ClassicGuildFrame_CheckName()
	if ( ClassicGuildFrame.hasForcedNameChange ) then
		local clickableHelp = false
		ClassicGuildNameChangeAlertFrame:Show();

		if ( IsGuildLeader() ) then
			ClassicGuildNameChangeFrame.gmText:Show();
			ClassicGuildNameChangeFrame.memberText:Hide();
			ClassicGuildNameChangeFrame.button:SetText(ACCEPT);
			ClassicGuildNameChangeFrame.button:SetPoint("TOP", ClassicGuildNameChangeFrame.editBox, "BOTTOM", 0, -10);
			ClassicGuildNameChangeFrame.renameText:Show();
			ClassicGuildNameChangeFrame.editBox:Show();
		else
			clickableHelp = ClassicGuildNameChangeAlertFrame.topAnchored;
			ClassicGuildNameChangeFrame.gmText:Hide();
			ClassicGuildNameChangeFrame.memberText:Show();
			ClassicGuildNameChangeFrame.button:SetText(OKAY);
			ClassicGuildNameChangeFrame.button:SetPoint("TOP", ClassicGuildNameChangeFrame.memberText, "BOTTOM", 0, -30);
			ClassicGuildNameChangeFrame.renameText:Hide();
			ClassicGuildNameChangeFrame.editBox:Hide();
		end


		if ( clickableHelp ) then
			ClassicGuildNameChangeAlertFrame.alert:SetFontObject(GameFontHighlight);
			ClassicGuildNameChangeAlertFrame.alert:ClearAllPoints();
			ClassicGuildNameChangeAlertFrame.alert:SetPoint("BOTTOM", ClassicGuildNameChangeAlertFrame, "CENTER", 0, 0);
			ClassicGuildNameChangeAlertFrame.alert:SetWidth(190);
			ClassicGuildNameChangeAlertFrame:SetPoint("TOP", 15, -4);
			ClassicGuildNameChangeAlertFrame:SetSize(256, 60);
			ClassicGuildNameChangeAlertFrame:Enable();
			ClassicGuildNameChangeAlertFrame.clickText:Show();
			ClassicGuildNameChangeFrame:Hide();
		else
			ClassicGuildNameChangeAlertFrame.alert:SetFontObject(GameFontHighlightMedium);
			ClassicGuildNameChangeAlertFrame.alert:ClearAllPoints();
			ClassicGuildNameChangeAlertFrame.alert:SetPoint("CENTER", ClassicGuildNameChangeAlertFrame, "CENTER", 0, 0);
			ClassicGuildNameChangeAlertFrame.alert:SetWidth(220);
			ClassicGuildNameChangeAlertFrame:SetPoint("TOP", 0, -82);
			ClassicGuildNameChangeAlertFrame:SetSize(300, 40);
			ClassicGuildNameChangeAlertFrame:Disable();
			ClassicGuildNameChangeAlertFrame.clickText:Hide();
			ClassicGuildNameChangeFrame:Show();
		end
	else
		ClassicGuildNameChangeAlertFrame:Hide();
		ClassicGuildNameChangeFrame:Hide();
	end
end

function ClassicGuildPointFrame_OnEnter(self)
	self.Highlight:Show();
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(GUILD_POINTS_TT, 1, 1, 1);
	GameTooltip:Show();
end

function ClassicGuildPointFrame_OnLeave(self)
	self.Highlight:Hide();
	GameTooltip:Hide();
end

function ClassicGuildPointFrame_OnMouseUp(self)
	if ( IsInGuild() and CanShowAchievementUI() ) then
		AchievementFrame_LoadUI();
		AchievementFrame_ToggleAchievementFrame(false, true);
	end
end

--****** Common Functions *******************************************************

function ClassicGuildFrame_OpenAchievement(button, achievementID)
	if ( not AchievementFrame ) then
		AchievementFrame_LoadUI();
	end
	if ( not AchievementFrame:IsShown() ) then
		AchievementFrame_ToggleAchievementFrame();
	end
	AchievementFrame_SelectAchievement(achievementID);
end

function ClassicGuildFrame_LinkItem(button, itemID, itemLink)
	local _;
	if ( not itemLink ) then
		_, itemLink = GetItemInfo(itemID);
	end
	if ( itemLink ) then
		if ( ChatEdit_GetActiveWindow() ) then
			ChatEdit_InsertLink(itemLink);
		else
			ChatFrame_OpenChat(itemLink);
		end
	end
end

function ClassicGuildFrame_UpdateScrollFrameWidth(scrollFrame)
	local newButtonWidth;
	local buttons = scrollFrame.buttons;

	if ( scrollFrame.scrollBar:IsShown() ) then
		if ( scrollFrame.wideButtons ) then
			newButtonWidth = BUTTON_WIDTH_WITH_SCROLLBAR;
		end
	else
		if ( not scrollFrame.wideButtons ) then
			newButtonWidth = BUTTON_WIDTH_NO_SCROLLBAR;
		end
	end
	if ( newButtonWidth ) then
		for i = 1, #buttons do
			buttons[i]:SetWidth(newButtonWidth);
		end
		scrollFrame.wideButtons = not scrollFrame.wideButtons;
		scrollFrame:SetWidth(newButtonWidth);
		scrollFrame.scrollChild:SetWidth(newButtonWidth);
	end
end

--****** Panels/Popups **********************************************************

function ClassicGuildFrame_RegisterPanel(frame)
	tinsert(GUILDFRAME_PANELS, frame:GetName());
end

function ClassicGuildFrame_ShowPanel(frameName)
	local frame;
	for index, value in pairs(GUILDFRAME_PANELS) do
		if ( value == frameName ) then
			frame = _G[value];
		else
			_G[value]:Hide();
		end
	end
	if ( frame ) then
		frame:Show();
	end
end

function ClassicGuildFrame_RegisterPopup(frame)
	tinsert(GUILDFRAME_POPUPS, frame:GetName());
end

function ClassicGuildFramePopup_Show(frame)
	local name = frame:GetName();
	for index, value in ipairs(GUILDFRAME_POPUPS) do
		if ( name ~= value ) then
			_G[value]:Hide();
		end
	end
	frame:Show();
end

function ClassicGuildFramePopup_Toggle(frame)
	if ( frame:IsShown() ) then
		frame:Hide();
	else
		ClassicGuildFramePopup_Show(frame);
	end
end

function ClassicCloseGuildMenus()
	for index, value in ipairs(GUILDFRAME_POPUPS) do
		local frame = _G[value];
		if ( frame:IsShown() ) then
			frame:Hide();
			return true;
		end
	end
end

--****** Tabs *******************************************************************

function ClassicGuildFrame_TabClicked(self)
	local updateRosterCount = false;
	local tabIndex = self:GetID();
	ClassicCloseGuildMenus();
	PanelTemplates_SetTab(self:GetParent(), tabIndex);

	--[[if tabIndex > 1 then
		ClassicGuildFrame:SetSize(338, 424)
	else
		ClassicGuildFrame:SetSize(814, 426)
	end]]

	if ( tabIndex == 1 ) then -- Chat
		ButtonFrameTemplate_ShowButtonBar(ClassicGuildFrame);
		ClassicGuildFrame_ShowPanel("ClassicFrame");
		ClassicGuildFrameInset:SetPoint("TOPLEFT", 4, -65);
		ClassicGuildFrameInset:SetPoint("BOTTOMRIGHT", -7, 26);
		ClassicGuildFrameBottomInset:Hide();
		ClassicGuildPointFrame:Hide();
		ClassicGuildFactionFrame:Hide();
		ClassicGuildFrameMembersCountLabel:Hide();

		--ClassicFrame:SetDisplayMode(COMMUNITIES_FRAME_DISPLAY_MODES.MINIMIZED);
		--ClassicFrame:SetSize(322, 406);
		ClassicFrame.Chat:SetPoint("TOPLEFT", ClassicGuildFrame, "TOPLEFT", 13, -67);
		ClassicFrame.Chat:SetPoint("BOTTOMRIGHT", ClassicGuildFrame, "BOTTOMRIGHT", -35, 36);
		ClassicFrame.Chat.MessageFrame.ScrollBar:SetPoint("TOPLEFT", ClassicFrame.Chat.MessageFrame, "TOPRIGHT", 8, -10);
		ClassicFrame.Chat.MessageFrame.ScrollBar:SetPoint("BOTTOMLEFT", ClassicFrame.Chat.MessageFrame, "BOTTOMRIGHT", 8, 7);
		ClassicFrame.Chat.InsetFrame:Hide();
		ClassicFrame.ChatEditBox:ClearAllPoints();
		ClassicFrame.ChatEditBox:SetPoint("BOTTOMLEFT", ClassicGuildFrame, "BOTTOMLEFT", 10, 0);
		ClassicFrame.ChatEditBox:SetPoint("BOTTOMRIGHT", ClassicGuildFrame, "BOTTOMRIGHT", -12, 0);
		ClassicFrame.ClassicListDropDownMenu:ClearAllPoints()
		ClassicFrame.ClassicListDropDownMenu:SetPoint("TOPLEFT", ClassicGuildFrame, -10, -28)
		ClassicFrame.StreamDropDownMenu:ClearAllPoints();
		ClassicFrame.StreamDropDownMenu:SetPoint("LEFT", ClassicFrame.ClassicListDropDownMenu, "RIGHT", -25, 0);
		UIDropDownMenu_SetWidth(ClassicFrame.StreamDropDownMenu, 115);
		--ClassicFrame.portrait:Hide();
		--ClassicFrame.TopLeftCorner:Show();
		--ClassicFrame.TopBorder:SetPoint("TOPLEFT", ClassicFrame.TopLeftCorner, "TOPRIGHT",  0, 0);
		--ClassicFrame.LeftBorder:SetPoint("TOPLEFT", ClassicFrame.TopLeftCorner, "BOTTOMLEFT",  0, 0);
		--ClassicFrame.PortraitOverlay:Hide();
		ClassicFrame.VoiceChatHeadset:SetPoint("TOPRIGHT", ClassicGuildFrame, -10, -26);
		UpdateUIPanelPositions();
	elseif ( tabIndex == 2 ) then -- News
		ButtonFrameTemplate_HideButtonBar(ClassicGuildFrame);
		ClassicGuildFrame_ShowPanel("ClassicGuildNewsFrame");
		ClassicGuildFrameInset:SetPoint("TOPLEFT", 4, -65);
		ClassicGuildFrameInset:SetPoint("BOTTOMRIGHT", -7, 44);
		ClassicGuildFrameBottomInset:Hide();
		ClassicGuildPointFrame:Show();
		ClassicGuildFactionFrame:Show();
		updateRosterCount = true;
		ClassicGuildFrameMembersCountLabel:Hide();
	elseif ( tabIndex == 3 ) then -- Roster
		ButtonFrameTemplate_HideButtonBar(ClassicGuildFrame);
		ClassicGuildFrame_ShowPanel("ClassicGuildRosterFrame");
		ClassicGuildFrameInset:SetPoint("TOPLEFT", 4, -90);
		ClassicGuildFrameInset:SetPoint("BOTTOMRIGHT", -7, 26);
		ClassicGuildFrameBottomInset:Hide();
		ClassicGuildPointFrame:Hide();
		ClassicGuildFactionFrame:Hide();
		updateRosterCount = true;
		ClassicGuildFrameMembersCountLabel:Show();
	elseif ( tabIndex == 4 ) then -- Perks
		ButtonFrameTemplate_HideButtonBar(ClassicGuildFrame);
		ClassicGuildFrame_ShowPanel("ClassicGuildPerksFrame");
		ClassicGuildFrameInset:SetPoint("TOPLEFT", 4, -65);
		ClassicGuildFrameInset:SetPoint("BOTTOMRIGHT", -7, 26);
		ClassicGuildPointFrame:Show();
		ClassicGuildFactionFrame:Hide();
		updateRosterCount = true;
		ClassicGuildFrameMembersCountLabel:Show();
		ClassicGuildPerksFrameMembersCountLabel:Hide();
		ClassicGuildFrameBottomInset:Hide();
	elseif ( tabIndex == 5 ) then -- Rewards
		ButtonFrameTemplate_HideButtonBar(ClassicGuildFrame);
		ClassicGuildFrame_ShowPanel("ClassicGuildRewardsFrame");
		ClassicGuildFrameInset:SetPoint("TOPLEFT", 4, -65);
		ClassicGuildFrameInset:SetPoint("BOTTOMRIGHT", -7, 44);
		ClassicGuildFrameBottomInset:Hide();
		ClassicGuildPointFrame:Hide();
		ClassicGuildFactionFrame:Show();
		updateRosterCount = true;
		ClassicGuildFrameMembersCountLabel:Hide();
	elseif ( tabIndex == 6 ) then -- Info
		ButtonFrameTemplate_ShowButtonBar(ClassicGuildFrame);
		ClassicGuildFrame_ShowPanel("ClassicGuildInfoFrame");
		ClassicGuildFrameInset:SetPoint("TOPLEFT", 4, -65);
		ClassicGuildFrameInset:SetPoint("BOTTOMRIGHT", -7, 26);
		ClassicGuildFrameBottomInset:Hide();
		ClassicGuildPointFrame:Hide();
		ClassicGuildFactionFrame:Hide();
		ClassicGuildFrameMembersCountLabel:Hide();
	end
	if ( updateRosterCount ) then
		GuildRoster();
		ClassicGuildFrameMembersCount:Show();
	else
		ClassicGuildFrameMembersCount:Hide();
	end
end

function ClassicGuildFactionBar_OnEnter(self)
	local name, description, standingID, barMin, barMax, barValue, _, _, _, _, _, _, _ = GetGuildFactionInfo();
	local factionStandingtext = GetText("FACTION_STANDING_LABEL"..standingID);
	--Normalize Values
	barMax = barMax - barMin;
	barValue = barValue - barMin;

	if (barMax == 0) then
		barMax = 1;
	end

	ClassicGuildFactionBarLabel:Show();
	local name, description = GetGuildFactionInfo();
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(GUILD_REPUTATION);
	GameTooltip:AddLine(description, 1, 1, 1, true);
	local percentTotal = tostring(math.ceil((barValue / barMax) * 100));
	GameTooltip:AddLine(string.format(GUILD_EXPERIENCE_CURRENT, BreakUpLargeNumbers(barValue), BreakUpLargeNumbers(barMax), percentTotal));
	GameTooltip:Show();
end

function ClassicGuildBar_SetProgress(bar, currentValue, maxValue)
	if (maxValue == 0) then
		maxValue = 1;
	end

	local MAX_BAR = bar:GetWidth() - 4;
	local progress = min(MAX_BAR * currentValue / maxValue, MAX_BAR);
	bar.progress:SetWidth(progress + 1);
	bar.cap:Hide();
	bar.capMarker:Hide();
	-- hide shadow on progress bar near the right edge
	if ( progress > MAX_BAR - 4 ) then
		bar.shadow:Hide();
	else
		bar.shadow:Show();
	end
	currentValue = BreakUpLargeNumbers(currentValue);
	maxValue = BreakUpLargeNumbers(maxValue);
end

--*******************************************************************************
--   Guild Panel
--*******************************************************************************

function ClassicGuildPerksFrame_OnLoad(self)
	ClassicGuildFrame_RegisterPanel(self);
	ClassicGuildPerksContainer.update = ClassicGuildPerks_Update;
	HybridScrollFrame_CreateButtons(ClassicGuildPerksContainer, "ClassicGuildPerksButtonTemplate", 8, 0, "TOPLEFT", "TOPLEFT", 0, 0, "TOP", "BOTTOM");
	self:RegisterEvent("GUILD_ROSTER_UPDATE");
	-- create buttons table for news update
	local buttons = { };
	for i = 1, 9 do
		tinsert(buttons, _G["ClassicGuildUpdatesButton"..i]);
	end
	ClassicGuildPerksFrame.buttons = buttons;
end

function ClassicGuildPerksFrame_OnShow(self)
	ClassicGuildPerks_Update();
end

function ClassicGuildPerksFrame_OnEvent(self, event, ...)
	if ( not self:IsShown() ) then
		return;
	end
	if ( event == "GUILD_ROSTER_UPDATE" ) then
		local canRequestRosterUpdate = ...;
		if ( canRequestRosterUpdate ) then
			GuildRoster();
		end
	end
end

--****** News/Events ************************************************************
function ClassicGuildEventButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		if ( CalendarFrame ) then
			CalendarFrame_OpenToGuildEventIndex(self.index);
		else
			ToggleCalendar();
			CalendarFrame_OpenToGuildEventIndex(self.index);
		end
	end
end

--****** Perks ******************************************************************

function ClassicGuildPerksButton_OnEnter(self)
	ClassicGuildPerksContainer.activeButton = self;
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 36, 0);
	GameTooltip:SetHyperlink(GetSpellLink(self.spellID));
end

function ClassicGuildPerks_Update()
	local scrollFrame = ClassicGuildPerksContainer;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local button, index;
	local numPerks = GetNumGuildPerks();
--	local guildLevel = GetGuildLevel();

	local totalHeight = numPerks * scrollFrame.buttonHeight;
	local displayedHeight = numButtons * scrollFrame.buttonHeight;
	local buttonWidth = scrollFrame.buttonWidth;
	if( totalHeight > displayedHeight )then
		scrollFrame:SetPoint("TOPLEFT", ClassicGuildAllPerksFrame, "TOPLEFT", 0, scrollFrame.yOffset);
		scrollFrame:SetWidth( scrollFrame.width );
		scrollFrame:SetHeight( scrollFrame.height );
	else
		buttonWidth = scrollFrame.buttonWidthNoScroll;
		scrollFrame:SetPoint("TOPLEFT", ClassicGuildAllPerksFrame, "TOPLEFT", 0, scrollFrame.yOffsetNoScroll);
		scrollFrame:SetWidth( scrollFrame.widthNoScroll );
		scrollFrame:SetHeight( scrollFrame.heightNoScroll );
	end
	for i = 1, numButtons do
		button = buttons[i];
		index = offset + i;
		if ( index <= numPerks ) then
			local name, spellID, iconTexture = GetGuildPerkInfo(index);
			button.name:SetText(name);
			button.icon:SetTexture(iconTexture);
			button.spellID = spellID;
			button:Show();
			button:SetWidth(buttonWidth);
		else
			button:Hide();
		end
	end
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);

	-- update tooltip
	if ( scrollFrame.activeButton ) then
		ClassicGuildPerksButton_OnEnter(scrollFrame.activeButton);
	end
end