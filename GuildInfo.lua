local GUILD_BUTTON_HEIGHT = 84;
local GUILD_COMMENT_HEIGHT = 50;
local GUILD_COMMENT_BORDER = 10;

local INTEREST_TYPES = {"QUEST", "DUNGEON", "RAID", "PVP", "RP"};

function ClassicGuildInfoFrame_OnLoad(self)
	ClassicGuildFrame_RegisterPanel(self);
	PanelTemplates_SetNumTabs(self, 3);

	self:RegisterEvent("GUILD_MOTD");
	self:RegisterEvent("GUILD_ROSTER_UPDATE");
	self:RegisterEvent("GUILD_RANKS_UPDATE");
	self:RegisterEvent("PLAYER_GUILD_UPDATE");
	self:RegisterEvent("LF_GUILD_POST_UPDATED");
	self:RegisterEvent("LF_GUILD_RECRUITS_UPDATED");
	self:RegisterEvent("LF_GUILD_RECRUIT_LIST_CHANGED");
	self:RegisterEvent("GUILD_CHALLENGE_UPDATED");

	RequestGuildRecruitmentSettings();
	RequestGuildChallengeInfo();
end

function ClassicGuildInfoFrame_OnEvent(self, event, arg1)
	if ( event == "GUILD_MOTD" ) then
		ClassicGuildInfoMOTD:SetText(arg1, true);	--Ignores markup.
	elseif ( event == "GUILD_ROSTER_UPDATE" ) then
		ClassicGuildInfoFrame_UpdatePermissions();
		ClassicGuildInfoFrame_UpdateText();
	elseif ( event == "GUILD_RANKS_UPDATE" ) then
		ClassicGuildInfoFrame_UpdatePermissions();
	elseif ( event == "PLAYER_GUILD_UPDATE" ) then
		ClassicGuildInfoFrame_UpdatePermissions();
	elseif ( event == "LF_GUILD_POST_UPDATED" ) then
		local bQuest, bDungeon, bRaid, bPvP, bRP, bWeekdays, bWeekends, bTank, bHealer, bDamage, bAnyLevel, bMaxLevel, bListed = GetGuildRecruitmentSettings();
		-- interest
		ClassicGuildRecruitmentQuestButton:SetChecked(bQuest);
		ClassicGuildRecruitmentDungeonButton:SetChecked(bDungeon);
		ClassicGuildRecruitmentRaidButton:SetChecked(bRaid);
		ClassicGuildRecruitmentPvPButton:SetChecked(bPvP);
		ClassicGuildRecruitmentRPButton:SetChecked(bRP);
		-- availability
		ClassicGuildRecruitmentWeekdaysButton:SetChecked(bWeekdays);
		ClassicGuildRecruitmentWeekendsButton:SetChecked(bWeekends);
		-- roles
		ClassicGuildRecruitmentTankButton.checkButton:SetChecked(bTank);
		ClassicGuildRecruitmentHealerButton.checkButton:SetChecked(bHealer);
		ClassicGuildRecruitmentDamagerButton.checkButton:SetChecked(bDamage);
		-- level
		if ( bMaxLevel ) then
			ClassicGuildRecruitmentLevelButton_OnClick(2);
		else
			ClassicGuildRecruitmentLevelButton_OnClick(1);
		end
		-- comment
		ClassicGuildRecruitmentCommentEditBox:SetText(GetGuildRecruitmentComment());
		ClassicGuildRecruitmentListGuildButton_Update();
	elseif ( event == "LF_GUILD_RECRUITS_UPDATED" ) then
		ClassicGuildInfoFrameApplicants_Update();
	elseif ( event == "LF_GUILD_RECRUIT_LIST_CHANGED" ) then
		RequestGuildApplicantsList();
	elseif ( event == "GUILD_CHALLENGE_UPDATED" ) then
		ClassicGuildInfoFrame_UpdateChallenges();
	end
end

function ClassicGuildInfoFrame_OnShow(self)
	RequestGuildApplicantsList();
	RequestGuildChallengeInfo();
end

function ClassicGuildInfoFrame_Update()
	local selectedTab = PanelTemplates_GetSelectedTab(ClassicGuildInfoFrame);
	if ( selectedTab == 1 ) then
		ClassicGuildInfoFrameInfo:Show();
		ClassicGuildInfoFrameRecruitment:Hide();
		ClassicGuildInfoFrameApplicants:Hide();
	elseif ( selectedTab == 2 ) then
		ClassicGuildInfoFrameInfo:Hide();
		ClassicGuildInfoFrameRecruitment:Show();
		ClassicGuildInfoFrameApplicants:Hide();
	else
		ClassicGuildInfoFrameInfo:Hide();
		ClassicGuildInfoFrameRecruitment:Hide();
		ClassicGuildInfoFrameApplicants:Show();
	end
end

--*******************************************************************************
--   Info Tab
--*******************************************************************************

function ClassicGuildInfoFrameInfo_OnLoad(self)
	local fontString = ClassicGuildInfoEditMOTDButton:GetFontString();
	ClassicGuildInfoEditMOTDButton:SetHeight(fontString:GetHeight() + 4);
	ClassicGuildInfoEditMOTDButton:SetWidth(fontString:GetWidth() + 4);
	fontString = ClassicGuildInfoEditDetailsButton:GetFontString();
	ClassicGuildInfoEditDetailsButton:SetHeight(fontString:GetHeight() + 4);
	ClassicGuildInfoEditDetailsButton:SetWidth(fontString:GetWidth() + 4);
end

function ClassicGuildInfoFrameInfo_OnShow(self)
	ClassicGuildInfoFrame_UpdatePermissions();
	ClassicGuildInfoFrame_UpdateText();
end

function ClassicGuildInfoFrame_UpdatePermissions()
	if ( CanEditMOTD() ) then
		ClassicGuildInfoEditMOTDButton:Show();
	else
		ClassicGuildInfoEditMOTDButton:Hide();
	end
	if ( CanEditGuildInfo() ) then
		ClassicGuildInfoEditDetailsButton:Show();
	else
		ClassicGuildInfoEditDetailsButton:Hide();
	end
	local guildInfoFrame = ClassicGuildInfoFrame;
	if ( IsGuildLeader() ) then
		ClassicGuildControlButton:Enable();
		ClassicGuildInfoFrameTab2:Show();
		ClassicGuildInfoFrameTab3:SetPoint("LEFT", ClassicGuildInfoFrameTab2, "RIGHT");
	else
		ClassicGuildControlButton:Disable();
		ClassicGuildInfoFrameTab2:Hide();
		ClassicGuildInfoFrameTab3:SetPoint("LEFT", ClassicGuildInfoFrameTab1, "RIGHT");
	end
	if ( CanGuildInvite() ) then
		ClassicGuildAddMemberButton:Enable();
		-- show the recruitment tabs
		if ( not guildInfoFrame.tabsShowing ) then
			guildInfoFrame.tabsShowing = true;
			ClassicGuildInfoFrameTab1:Show();
			ClassicGuildInfoFrameTab3:Show();
			ClassicGuildInfoFrameTab3:SetText(GUILDINFOTAB_APPLICANTS_NONE);
			PanelTemplates_SetTab(guildInfoFrame, 1);
			PanelTemplates_UpdateTabs(guildInfoFrame);
			RequestGuildApplicantsList();
		end
	else
		ClassicGuildAddMemberButton:Disable();
		-- hide the recruitment tabs
		if ( guildInfoFrame.tabsShowing ) then
			guildInfoFrame.tabsShowing = nil;
			ClassicGuildInfoFrameTab1:Hide();
			ClassicGuildInfoFrameTab3:Hide();
			if ( PanelTemplates_GetSelectedTab(guildInfoFrame) ~= 1 ) then
				PanelTemplates_SetTab(guildInfoFrame, 1);
				ClassicGuildInfoFrame_Update();
			end
		end
	end
end

function ClassicGuildInfoFrame_UpdateText(infoText)
	ClassicGuildInfoMOTD:SetText(GetGuildRosterMOTD(), true); --Extra argument ignores markup.
	ClassicGuildInfoDetails:SetText(infoText or GetGuildInfoText());
	ClassicGuildInfoDetailsFrame:SetVerticalScroll(0);
	ClassicGuildInfoDetailsFrameScrollBarScrollUpButton:Disable();
end

function ClassicGuildInfoFrame_UpdateChallenges()
	local numChallenges = GetNumGuildChallenges();
	for i = 1, numChallenges do
		local index, current, max = GetGuildChallengeInfo(i);
		local frame = _G["ClassicGuildInfoFrameInfoChallenge"..index];
		if ( frame ) then
			frame.dataIndex = i;
			if ( current == max ) then
				frame.count:Hide();
				frame.check:Show();
				frame.label:SetTextColor(0.1, 1, 0.1);
			else
				frame.count:Show();
				frame.count:SetFormattedText(GUILD_CHALLENGE_PROGRESS_FORMAT, current, max);
				frame.check:Hide();
				frame.label:SetTextColor(1, 1, 1);
			end
		end
	end
end

--*******************************************************************************
--   Recruitment Tab
--*******************************************************************************

function ClassicGuildInfoFrameRecruitment_OnLoad(self)
	ClassicGuildRecruitmentInterestFrameText:SetText(GUILD_INTEREST);
	ClassicGuildRecruitmentInterestFrame:SetHeight(63);
	ClassicGuildRecruitmentAvailabilityFrameText:SetText(GUILD_AVAILABILITY);
	ClassicGuildRecruitmentAvailabilityFrame:SetHeight(43);
	ClassicGuildRecruitmentRolesFrameText:SetText(CLASS_ROLES);
	ClassicGuildRecruitmentRolesFrame:SetHeight(80);
	ClassicGuildRecruitmentLevelFrameText:SetText(GUILD_RECRUITMENT_LEVEL);
	ClassicGuildRecruitmentLevelFrame:SetHeight(43);
	ClassicGuildRecruitmentCommentFrame:SetHeight(72);

	-- defaults until data is retrieved
	ClassicGuildRecruitmentLevelAnyButton:SetChecked(true);
	ClassicGuildRecruitmentListGuildButton:Disable();
end

function ClassicGuildRecruitmentLevelButton_OnClick(index, userClick)
	local param;
	if ( index == 1 ) then
		ClassicGuildRecruitmentLevelAnyButton:SetChecked(true);
		ClassicGuildRecruitmentLevelMaxButton:SetChecked(false);
		param = LFGUILD_PARAM_ANY_LEVEL;
	elseif ( index == 2 ) then
		ClassicGuildRecruitmentLevelAnyButton:SetChecked(false);
		ClassicGuildRecruitmentLevelMaxButton:SetChecked(true);
		param = LFGUILD_PARAM_MAX_LEVEL;
	end
	if ( userClick ) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		SetGuildRecruitmentSettings(param, true);
	end
end

function ClassicGuildRecruitmentRoleButton_OnClick(self)
	local checked = self:GetChecked();
	if ( self:GetChecked() ) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
	end
	SetGuildRecruitmentSettings(self:GetParent().param, checked);
	ClassicGuildRecruitmentListGuildButton_Update();
end

function ClassicGuildRecruitmentListGuildButton_Update()
	local bQuest, bDungeon, bRaid, bPvP, bRP, bWeekdays, bWeekends, bTank, bHealer, bDamage, bAnyLevel, bMaxLevel, bListed = GetGuildRecruitmentSettings();
	-- need to have at least 1 interest, 1 time, and 1 role checked to be able to list
	if ( bQuest or bDungeon or bRaid or bPvP or bRP ) and ( bWeekdays or bWeekends ) and ( bTank or bHealer or bDamage ) then
		ClassicGuildRecruitmentListGuildButton:Enable();
	else
		ClassicGuildRecruitmentListGuildButton:Disable();
		-- delist if already listed
		if ( bListed ) then
			bListed = false;
			SetGuildRecruitmentSettings(LFGUILD_PARAM_LOOKING, false);
		end
	end
	ClassicGuildRecruitmentListGuildButton_UpdateText(bListed);
end

function ClassicGuildRecruitmentListGuildButton_OnClick(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	local bQuest, bDungeon, bRaid, bPvP, bRP, bWeekdays, bWeekends, bTank, bHealer, bDamage, bAnyLevel, bMaxLevel, bListed = GetGuildRecruitmentSettings();
	bListed = not bListed;
	if ( bListed and ClassicGuildRecruitmentCommentEditBox:HasFocus() ) then
		ClassicGuildRecruitmentComment_SaveText();
	end
	SetGuildRecruitmentSettings(LFGUILD_PARAM_LOOKING, bListed);
	ClassicGuildRecruitmentListGuildButton_UpdateText(bListed);
end

function ClassicGuildRecruitmentListGuildButton_UpdateText(listed)
	if ( listed ) then
		ClassicGuildRecruitmentListGuildButton:SetText(GUILD_CLOSE_RECRUITMENT);
	else
		ClassicGuildRecruitmentListGuildButton:SetText(GUILD_OPEN_RECRUITMENT);
	end
end

function ClassicGuildRecruitmentComment_SaveText(self)
	self = self or ClassicGuildRecruitmentCommentEditBox;
	SetGuildRecruitmentComment(self:GetText():gsub("\n",""));
	self:ClearFocus();
end

function ClassicGuildRecruitmentCheckButton_OnEnter(self)
	local interestType = INTEREST_TYPES[self:GetID()];
	if ( interestType ) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(_G["GUILD_INTEREST_"..interestType]);
		GameTooltip:AddLine(_G["GUILD_INTEREST_"..interestType.."_TOOLTIP"], 1, 1, 1, true);
		GameTooltip:Show();
	end
end

--*******************************************************************************
--   Applicants Tab
--*******************************************************************************

function ClassicGuildInfoFrameApplicants_OnLoad(self)
	ClassicGuildInfoFrameApplicantsContainer.update = ClassicGuildInfoFrameApplicants_Update;
	HybridScrollFrame_CreateButtons(ClassicGuildInfoFrameApplicantsContainer, "ClassicGuildRecruitmentApplicantTemplate", 0, 0);

	ClassicGuildInfoFrameApplicantsContainerScrollBar.Show =
		function (self)
			ClassicGuildInfoFrameApplicantsContainer:SetWidth(304);
			for _, button in next, ClassicGuildInfoFrameApplicantsContainer.buttons do
				button:SetWidth(301);
				button.fullComment:SetWidth(223);
			end
			getmetatable(self).__index.Show(self);
		end
	ClassicGuildInfoFrameApplicantsContainerScrollBar.Hide =
		function (self)
			ClassicGuildInfoFrameApplicantsContainer:SetWidth(320);
			for _, button in next, ClassicGuildInfoFrameApplicantsContainer.buttons do
				button:SetWidth(320);
				button.fullComment:SetWidth(242);
			end
			getmetatable(self).__index.Hide(self);
		end
end

function ClassicGuildInfoFrameApplicants_OnShow(self)
	ClassicGuildInfoFrameApplicants_Update();
end

function ClassicGuildInfoFrameApplicants_Update()
	local scrollFrame = ClassicGuildInfoFrameApplicantsContainer;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local button, index;
	local numApplicants = GetNumGuildApplicants();
	local selection = GetGuildApplicantSelection();

	if ( numApplicants == 0 ) then
		ClassicGuildInfoFrameTab3:SetText(GUILDINFOTAB_APPLICANTS_NONE);
	else
		ClassicGuildInfoFrameTab3:SetFormattedText(GUILDINFOTAB_APPLICANTS, numApplicants);
	end
	PanelTemplates_TabResize(ClassicGuildInfoFrameTab3, 0);

	for i = 1, numButtons do
		button = buttons[i];
		index = offset + i;
		local name, level, class, _, _, _, _, _, _, _, isTank, isHealer, isDamage, comment, timeSince, timeLeft = GetGuildApplicantInfo(index);
		if ( name ) then
			button.name:SetText(name);
			button.level:SetText(level);
			button.comment:SetText(comment);
			button.fullComment:SetText(comment);
			button.class:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]));
			-- time left
			local daysLeft = floor(timeLeft / 86400); -- seconds in a day
			if ( daysLeft < 1 ) then
				button.timeLeft:SetText(GUILD_FINDER_LAST_DAY_LEFT);
			else
				button.timeLeft:SetFormattedText(GUILD_FINDER_DAYS_LEFT, daysLeft);
			end
			-- roles
			if ( isTank ) then
				button.tankTex:SetAlpha(1);
			else
				button.tankTex:SetAlpha(0.2);
			end
			if ( isHealer ) then
				button.healerTex:SetAlpha(1);
			else
				button.healerTex:SetAlpha(0.2);
			end
			if ( isDamage ) then
				button.damageTex:SetAlpha(1);
			else
				button.damageTex:SetAlpha(0.2);
			end
			-- selection
			local buttonHeight = GUILD_BUTTON_HEIGHT;
			if ( index == selection ) then
				button.selectedTex:Show();
				local commentHeight = button.fullComment:GetHeight();
				if ( commentHeight > GUILD_COMMENT_HEIGHT ) then
					buttonHeight = GUILD_BUTTON_HEIGHT + commentHeight - GUILD_COMMENT_HEIGHT + GUILD_COMMENT_BORDER;
				end
			else
				button.selectedTex:Hide();
			end

			button:SetHeight(buttonHeight);
			button:Show();
			button.index = index;
		else
			button:Hide();
		end
	end

	if ( not selection ) then
		HybridScrollFrame_CollapseButton(scrollFrame);
	end

	local totalHeight = numApplicants * GUILD_BUTTON_HEIGHT;
	if ( scrollFrame.largeButtonHeight ) then
		totalHeight = totalHeight + (scrollFrame.largeButtonHeight - GUILD_BUTTON_HEIGHT);
	end
	local displayedHeight = numApplicants * GUILD_BUTTON_HEIGHT;
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);

	if ( selection and selection > 0 ) then
		ClassicGuildRecruitmentInviteButton:Enable();
		ClassicGuildRecruitmentDeclineButton:Enable();
		ClassicGuildRecruitmentMessageButton:Enable();
	else
		ClassicGuildRecruitmentInviteButton:Disable();
		ClassicGuildRecruitmentDeclineButton:Disable();
		ClassicGuildRecruitmentMessageButton:Disable();
	end
end

function ClassicGuildRecruitmentApplicant_OnClick(self, button)
	if ( button == "LeftButton" ) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		SetGuildApplicantSelection(self.index);
		local commentHeight = self.fullComment:GetHeight();
		if ( commentHeight > GUILD_COMMENT_HEIGHT ) then
			local buttonHeight = GUILD_BUTTON_HEIGHT + commentHeight - GUILD_COMMENT_HEIGHT + GUILD_COMMENT_BORDER;
			self:SetHeight(buttonHeight);
			HybridScrollFrame_ExpandButton(ClassicGuildInfoFrameApplicantsContainer, ((self.index - 1) * GUILD_BUTTON_HEIGHT), buttonHeight);
		else
			HybridScrollFrame_CollapseButton(ClassicGuildInfoFrameApplicantsContainer);
		end
		ClassicGuildInfoFrameApplicants_Update();
	elseif ( button == "RightButton" ) then
		local dropDown = ClassicGuildRecruitmentDropDown;
		if ( dropDown.index ~= self.index ) then
			L_CloseDropDownMenus();
		end
		dropDown.index = self.index;
		L_ToggleDropDownMenu(1, nil, dropDown, "cursor", 1, -1);
	end
end

function ClassicGuildRecruitmentApplicant_ShowTooltip(self)
	local name, level, class, bQuest, bDungeon, bRaid, bPvP, bRP, bWeekdays, bWeekends, bTank, bHealer, bDamage, comment, timeSince, timeLeft = GetGuildApplicantInfo(self.index);
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(name);
	local buf = "";
	-- interests
	if ( bQuest ) then buf = buf.."\n"..QUEST_DASH..GUILD_INTEREST_QUEST; end
	if ( bDungeon ) then buf = buf.."\n"..QUEST_DASH..GUILD_INTEREST_DUNGEON; end
	if ( bRaid ) then buf = buf.."\n"..QUEST_DASH..GUILD_INTEREST_RAID; end
	if ( bPvP ) then buf = buf.."\n"..QUEST_DASH..GUILD_INTEREST_PVP; end
	if ( bRP ) then buf = buf.."\n"..QUEST_DASH..GUILD_INTEREST_RP; end
	GameTooltip:AddLine(GUILD_INTEREST..HIGHLIGHT_FONT_COLOR_CODE..buf..FONT_COLOR_CODE_CLOSE);
	-- availability
	buf = "";
	if ( bWeekdays ) then buf = buf.."\n"..QUEST_DASH..GUILD_AVAILABILITY_WEEKDAYS; end
	if ( bWeekends ) then buf = buf.."\n"..QUEST_DASH..GUILD_AVAILABILITY_WEEKENDS; end
	GameTooltip:AddLine(GUILD_AVAILABILITY..HIGHLIGHT_FONT_COLOR_CODE..buf..FONT_COLOR_CODE_CLOSE);

	GameTooltip:Show();
end

function ClassicGuildRecruitmentDropDown_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, ClassicGuildRecruitmentDropDown_Initialize, "MENU");
end

function ClassicGuildRecruitmentDropDown_Initialize(self)
	local info = L_UIDropDownMenu_CreateInfo();
	local name = GetGuildApplicantInfo(ClassicGuildRecruitmentDropDown.index) or UNKNOWN;
	info.text = name;
	info.isTitle = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);

	info = L_UIDropDownMenu_CreateInfo();
	info.notCheckable = 1;
	info.func = ClassicGuildRecruitmentDropDown_OnClick;

	info.text = INVITE;
	info.arg1 = "invite";
	L_UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);

	info.text = WHISPER;
	info.arg1 = "whisper";
	L_UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);

	info.text = ADD_FRIEND;
	info.arg1 = "addfriend";
	if ( GetFriendInfo(name) ) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);

	info.text = DECLINE;
	info.arg1 = "decline";
	info.disabled = nil;
	L_UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
end

function ClassicGuildRecruitmentDropDown_OnClick(button, action)
	local name = GetGuildApplicantInfo(ClassicGuildRecruitmentDropDown.index);
	if ( not name ) then
		return;
	end
	if ( action == "invite" ) then
		GuildInvite(name);
	elseif ( action == "whisper" ) then
		ChatFrame_SendTell(name);
	elseif ( action == "addfriend" ) then
		AddOrRemoveFriend(name);
	elseif ( action == "decline" ) then
		DeclineGuildApplicant(ClassicGuildRecruitmentDropDown.index);
	end
end

--*******************************************************************************
--   Popups
--*******************************************************************************

function ClassicGuildTextEditFrame_OnLoad(self)
	ClassicGuildFrame_RegisterPopup(self);
	ClassicGuildTextEditBox:SetTextInsets(4, 0, 4, 4);
	ClassicGuildTextEditBox:SetSpacing(2);
end

function ClassicGuildTextEditFrame_Show(editType)
	if ( editType == "motd" ) then
		ClassicGuildTextEditFrame:SetHeight(162);
		ClassicGuildTextEditBox:SetMaxLetters(128);
		ClassicGuildTextEditBox:SetText(GetGuildRosterMOTD());
		ClassicGuildTextEditFrameTitle:SetText(GUILD_MOTD_EDITLABEL);
		ClassicGuildTextEditBox:SetScript("OnEnterPressed", ClassicGuildTextEditFrame_OnAccept);
	elseif ( editType == "info" ) then
		ClassicGuildTextEditFrame:SetHeight(295);
		ClassicGuildTextEditBox:SetMaxLetters(500);
		ClassicGuildTextEditBox:SetText(GetGuildInfoText());
		ClassicGuildTextEditFrameTitle:SetText(GUILD_INFO_EDITLABEL);
		ClassicGuildTextEditBox:SetScript("OnEnterPressed", nil);
	end
	ClassicGuildTextEditFrame.type = editType;
	ClassicGuildFramePopup_Show(ClassicGuildTextEditFrame);
	ClassicGuildTextEditBox:SetCursorPosition(0);
	ClassicGuildTextEditBox:SetFocus();
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function ClassicGuildTextEditFrame_OnAccept()
	if ( ClassicGuildTextEditFrame.type == "motd" ) then
		GuildSetMOTD(ClassicGuildTextEditBox:GetText());
	elseif ( ClassicGuildTextEditFrame.type == "info" ) then
		local infoText = ClassicGuildTextEditBox:GetText();
		SetGuildInfoText(infoText);
		ClassicGuildInfoFrame_UpdateText(infoText);
	end
	ClassicGuildTextEditFrame:Hide();
end

function ClassicGuildLogFrame_OnLoad(self)
	ClassicGuildFrame_RegisterPopup(self);
	ClassicGuildLogHTMLFrame:SetSpacing(2);
	ScrollBar_AdjustAnchors(ClassicGuildLogScrollFrameScrollBar, 0, -2);
	self:RegisterEvent("GUILD_EVENT_LOG_UPDATE");
end

function ClassicGuildLogFrame_Update()
	local numEvents = GetNumGuildEvents();
	local type, player1, player2, rank, year, month, day, hour;
	local msg;
	local buffer = "";
	for i = numEvents, 1, -1 do
		type, player1, player2, rank, year, month, day, hour = GetGuildEventInfo(i);
		if ( not player1 ) then
			player1 = UNKNOWN;
		end
		if ( not player2 ) then
			player2 = UNKNOWN;
		end
		if ( type == "invite" ) then
			msg = format(GUILDEVENT_TYPE_INVITE, player1, player2);
		elseif ( type == "join" ) then
			msg = format(GUILDEVENT_TYPE_JOIN, player1);
		elseif ( type == "promote" ) then
			msg = format(GUILDEVENT_TYPE_PROMOTE, player1, player2, rank);
		elseif ( type == "demote" ) then
			msg = format(GUILDEVENT_TYPE_DEMOTE, player1, player2, rank);
		elseif ( type == "remove" ) then
			msg = format(GUILDEVENT_TYPE_REMOVE, player1, player2);
		elseif ( type == "quit" ) then
			msg = format(GUILDEVENT_TYPE_QUIT, player1);
		end
		if ( msg ) then
			buffer = buffer..msg.."|cff009999   "..format(GUILD_BANK_LOG_TIME, RecentTimeDate(year, month, day, hour)).."|r|n";
		end
	end
	ClassicGuildLogHTMLFrame:SetText(buffer);
end
