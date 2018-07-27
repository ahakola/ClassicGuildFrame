local GUILD_DETAIL_NORM_HEIGHT = 175;
local GUILD_DETAIL_OFFICER_HEIGHT = 228;
local GUILD_ROSTER_MAX_COLUMNS = 5;
local GUILD_ROSTER_MAX_STRINGS = 4;
local GUILD_ROSTER_BAR_MAX = 239;
local GUILD_ROSTER_BUTTON_OFFSET = 2;
local GUILD_ROSTER_BUTTON_HEIGHT = 20;
local GUILD_ROSTER_STRING_OFFSET = 6;
local GUILD_ROSTER_STRING_WIDTH_ADJ = 14;
local currentGuildView;

local GUILD_ROSTER_COLUMNS = {
	playerStatus = { "level", "class", "wideName", "zone" },
	guildStatus = { "name", "rank", "note", "online" },
	--[[
	weeklyxp = { "level", "class", "wideName", "weeklyxp" },
	totalxp = { "level", "class", "wideName", "totalxp" },
	--]]
	pvp = { "level", "class", "name", "bgrating", "arenarating" },
	achievement = { "level", "class", "wideName", "achievement" },
	tradeskill = { "wideName", "zone", "skill" },
	reputation = { "level", "class", "wideName", "reputation" },
};

-- global for localization changes
local GUILD_ROSTER_COLUMN_DATA = {
	level = { width = 40, text = LEVEL_ABBR, stringJustify="CENTER" },
	class = { width = 32, text = CLASS_ABBR, hasIcon = true },
	name = { width = 81, text = NAME, stringJustify="LEFT" },
	wideName = { width = 101, text = NAME, sortType = "name", stringJustify="LEFT" },
	rank = { width = 76, text = RANK, stringJustify="LEFT" },
	note = { width = 76, text = LABEL_NOTE, stringJustify="LEFT" },
	online = { width = 76, text = LASTONLINE, stringJustify="LEFT" },
	zone = { width = 136, text = ZONE, stringJustify="LEFT" },
	bgrating = { width = 83, text = BG_RATING_ABBR, stringJustify="RIGHT" },
	arenarating = { width = 83, text = ARENA_RATING, stringJustify="RIGHT" },
	weeklyxp = { width = 136, text = GUILD_XP_WEEKLY, stringJustify="RIGHT", hasBar = true },
	totalxp = { width = 136, text = GUILD_XP_TOTAL, stringJustify="RIGHT", hasBar = true },
	achievement = { width = 136, text = ACHIEVEMENT_POINTS, stringJustify="RIGHT", sortType="achievementpoints", hasBar = true },
	skill = { width = 63, text = SKILL_POINTS_ABBR, stringJustify="LEFT" },
	reputation = { width = 136, text = REPUTATION, stringJustify="LEFT" },
};

local MOBILE_BUSY_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-BusyMobile:14:14:0:0:16:16:0:16:0:16|t";
local MOBILE_AWAY_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-AwayMobile:14:14:0:0:16:16:0:16:0:16|t";

function ClassicGuildRosterFrame_OnLoad(self)
	ClassicGuildFrame_RegisterPanel(self);
	ClassicGuildRosterContainer.update = ClassicGuildRoster_Update;
	HybridScrollFrame_CreateButtons(ClassicGuildRosterContainer, "ClassicGuildRosterButtonTemplate", 0, 0, "TOPLEFT", "TOPLEFT", 0, -GUILD_ROSTER_BUTTON_OFFSET, "TOP", "BOTTOM");
	ClassicGuildRosterContainerScrollBar.doNotHide = true;
	ClassicGuildRosterShowOfflineButton:SetChecked(GetGuildRosterShowOffline());
	self:RegisterEvent("GUILD_TRADESKILL_UPDATE");
	self:RegisterEvent("GUILD_ROSTER_UPDATE");
	self:RegisterEvent("GUILD_RECIPE_KNOWN_BY_MEMBERS");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	ClassicGuildRoster_SetView(GetCVar("guildRosterView"));
	SetGuildRosterSelection(0);
	L_UIDropDownMenu_SetSelectedValue(ClassicGuildRosterViewDropdown, currentGuildView);
	-- right-click dropdown
	ClassicGuildMemberDropDown.displayMode = "MENU";

	self.doRecipeQuery = true;
end

function ClassicGuildRosterFrame_OnEvent(self, event, ...)
	if ( not self:IsShown() ) then
		return;
	end
	if ( event == "GUILD_TRADESKILL_UPDATE" ) then
		if ( currentGuildView == "tradeskill" ) then
			ClassicGuildRoster_Update();
		end
	elseif ( event == "GUILD_ROSTER_UPDATE" ) then
		if ( currentGuildView ~= "tradeskill" ) then
			local canRequestRosterUpdate = ...;
			if ( canRequestRosterUpdate ) then
				GuildRoster();
			end
			ClassicGuildRoster_Update();
		end
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		self.doRecipeQuery = true;
	end
end

function ClassicGuildRosterFrame_OnShow(self)
	ClassicGuildRoster_RecipeQueryCheck();
	ClassicGuildRoster_Update();
end

function ClassicGuildRoster_RecipeQueryCheck()
	if ( ClassicGuildRosterFrame.doRecipeQuery ) then
		QueryGuildRecipes();
		ClassicGuildRosterFrame.doRecipeQuery = nil;
	end
end

function ClassicGuildRoster_GetLastOnline(guildIndex)
	return RecentTimeDate( GetGuildRosterLastOnline(guildIndex) );
end

function ClassicGuildRoster_SortByColumn(column)
	if ( column.sortType ) then
		if ( currentGuildView == "tradeskill" ) then
			SortGuildTradeSkill(column.sortType);
		else
			SortGuildRoster(column.sortType);
		end
	end
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

--****** Guild members **********************************************************

function ClassicGuildRosterButton_SetStringText(buttonString, text, isOnline, class)
	buttonString:SetText(text);
	if ( isOnline ) then
		if ( class ) then
			local classColor = RAID_CLASS_COLORS[class];
			buttonString:SetTextColor(classColor.r, classColor.g, classColor.b);
		else
			buttonString:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		end
	else
		buttonString:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
	end
end

function ClassicGuildRoster_Update()
	local scrollFrame = ClassicGuildRosterContainer;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local button, index, class;
	local totalMembers, onlineMembers, onlineAndMobileMembers = GetNumGuildMembers();
	local selectedGuildMember = GetGuildRosterSelection();

	if ( currentGuildView == "tradeskill" ) then
		ClassicGuildRoster_UpdateTradeSkills();
		return;
	end

	local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
	local maxRankIndex = GuildControlGetNumRanks() - 1;
	-- Get selected guild member info
	local fullName, rank, rankIndex, level, class, zone, note, officernote, online, isAway, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(selectedGuildMember);
	ClassicGuildFrame.selectedName = fullName;
	-- If there's a selected guildmember
	if ( selectedGuildMember > 0 ) then
		-- Update the guild member details frame
		if ( isMobile ) then
			if (isAway == 2) then
				ClassicGuildMemberDetailName:SetText(MOBILE_BUSY_ICON..GuildFrame.selectedName);
			elseif (isAway == 1) then
				ClassicGuildMemberDetailName:SetText(MOBILE_AWAY_ICON..GuildFrame.selectedName);
			else
				ClassicGuildMemberDetailName:SetText(ChatFrame_GetMobileEmbeddedTexture(73/255, 177/255, 73/255)..GuildFrame.selectedName);
			end
		else
			ClassicGuildMemberDetailName:SetText(ClassicGuildFrame.selectedName);
		end
		if ( level and class) then
			ClassicGuildMemberDetailLevel:SetFormattedText(FRIENDS_LEVEL_TEMPLATE, level, class);
		else
			ClassicGuildMemberDetailLevel:SetText("");
		end
		local zoneText = zone;
		if(isMobile and not online) then zoneText = REMOTE_CHAT; end;
		ClassicGuildMemberDetailZoneText:SetText(zoneText);
		ClassicGuildMemberDetailRankText:SetText(rank);
		if ( online ) then
			ClassicGuildMemberDetailOnlineText:SetText(GUILD_ONLINE_LABEL);
		else
			ClassicGuildMemberDetailOnlineText:SetText(ClassicGuildRoster_GetLastOnline(selectedGuildMember));
		end
		-- Update public note
		if ( CanEditPublicNote() ) then
			ClassicPersonalNoteText:SetTextColor(1.0, 1.0, 1.0);
			if ( (not note) or (note == "") ) then
				note = GUILD_NOTE_EDITLABEL;
			end
		else
			ClassicPersonalNoteText:SetTextColor(0.65, 0.65, 0.65);
		end
		ClassicGuildMemberNoteBackground:EnableMouse(CanEditPublicNote());
		ClassicPersonalNoteText:SetText(note);

		-- Manage guild member related buttons
		-- check if you can promote and the member is at least 2 ranks below you, or if you can demote and the member is not in the last rank, as well as below your rank
		if ( ( CanGuildPromote() and rankIndex > guildRankIndex + 1 ) or ( CanGuildDemote() and rankIndex < maxRankIndex and rankIndex > guildRankIndex ) ) then
			ClassicGuildMemberDetailRankLabel:SetHeight(20);
			ClassicGuildMemberRankDropdown:Show();
			L_UIDropDownMenu_SetText(ClassicGuildMemberRankDropdown, rank);
		else
			ClassicGuildMemberDetailRankLabel:SetHeight(0);
			ClassicGuildMemberRankDropdown:Hide();
		end

		-- Update officer note
		if ( CanViewOfficerNote() ) then
			if ( CanEditOfficerNote() ) then
				if ( (not officernote) or (officernote == "") ) then
					officernote = GUILD_OFFICERNOTE_EDITLABEL;
				end
				ClassicOfficerNoteText:SetTextColor(1.0, 1.0, 1.0);
			else
				ClassicOfficerNoteText:SetTextColor(0.65, 0.65, 0.65);
			end
			ClassicGuildMemberOfficerNoteBackground:EnableMouse(CanEditOfficerNote());
			ClassicOfficerNoteText:SetText(officernote);

			-- Resize detail frame
			ClassicGuildMemberDetailOfficerNoteLabel:Show();
			ClassicGuildMemberOfficerNoteBackground:Show();
			ClassicGuildMemberDetailFrame:SetHeight(GUILD_DETAIL_OFFICER_HEIGHT + ClassicGuildMemberDetailName:GetHeight() + ClassicGuildMemberDetailRankLabel:GetHeight());
		else
			ClassicGuildMemberDetailOfficerNoteLabel:Hide();
			ClassicGuildMemberOfficerNoteBackground:Hide();
			ClassicGuildMemberDetailFrame:SetHeight(GUILD_DETAIL_NORM_HEIGHT + ClassicGuildMemberDetailName:GetHeight() + ClassicGuildMemberDetailRankLabel:GetHeight());
		end

		if ( CanGuildRemove() and ( rankIndex >= 1 ) and ( rankIndex > guildRankIndex ) ) then
			ClassicGuildMemberRemoveButton:Enable();
		else
			ClassicGuildMemberRemoveButton:Disable();
		end
		if ( (UnitFullName("player") == fullName) or (not online) or isMobile ) then
			ClassicGuildMemberGroupInviteButton:Disable();
		else
			ClassicGuildMemberGroupInviteButton:Enable();
		end

		ClassicGuildFrame.selectedName = GetGuildRosterInfo(GetGuildRosterSelection());
	else
		ClassicGuildMemberDetailFrame:Hide();
	end

--	local maxWeeklyXP, maxTotalXP = GetGuildRosterLargestContribution();
	local maxAchievementsPoints = GetGuildRosterLargestAchievementPoints();
	-- numVisible
	local visibleMembers = onlineAndMobileMembers;
	if ( GetGuildRosterShowOffline() ) then
		visibleMembers = totalMembers;
	end
	for i = 1, numButtons do
		button = buttons[i];
		index = offset + i;
		local fullName, rank, rankIndex, level, class, zone, note, officernote, online, isAway, classFileName, achievementPoints, achievementRank, isMobile, canSoR, repStanding = GetGuildRosterInfo(index);

		local onlineOrMobile = online or isMobile;

		if ( fullName and index <= visibleMembers ) then
			button.guildIndex = index;
			local displayedName = Ambiguate(fullName, "guild");
			if ( isMobile and not online ) then
				if (isAway == 2) then
					displayedName = MOBILE_BUSY_ICON..displayedName;
				elseif (isAway == 1) then
					displayedName = MOBILE_AWAY_ICON..displayedName;
				else
					displayedName = ChatFrame_GetMobileEmbeddedTexture(73/255, 177/255, 73/255)..displayedName;
				end
			end
			button.online = onlineOrMobile;
			if ( currentGuildView == "playerStatus" ) then
				ClassicGuildRosterButton_SetStringText(button.string1, level, onlineOrMobile)
				button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]));
				ClassicGuildRosterButton_SetStringText(button.string2, displayedName, onlineOrMobile, classFileName)
				local zoneText = zone;
				if(isMobile and not online) then zoneText = REMOTE_CHAT; end;
				ClassicGuildRosterButton_SetStringText(button.string3, zoneText, onlineOrMobile)

			elseif ( currentGuildView == "guildStatus" ) then
				ClassicGuildRosterButton_SetStringText(button.string1, displayedName, onlineOrMobile, classFileName)
				ClassicGuildRosterButton_SetStringText(button.string2, rank, onlineOrMobile)
				ClassicGuildRosterButton_SetStringText(button.string3, note, onlineOrMobile)

				if ( onlineOrMobile ) then
					ClassicGuildRosterButton_SetStringText(button.string4, GUILD_ONLINE_LABEL, onlineOrMobile);
				else
					ClassicGuildRosterButton_SetStringText(button.string4, ClassicGuildRoster_GetLastOnline(index), onlineOrMobile);
				end
--[[
			elseif ( currentGuildView == "weeklyxp" ) then
				local weeklyXP, totalXP, weeklyRank, totalRank = GetGuildRosterContribution(index);
				ClassicGuildRosterButton_SetStringText(button.string1, level, onlineOrMobile)
				button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]));
				ClassicGuildRosterButton_SetStringText(button.string2, displayedName, onlineOrMobile, classFileName)
				ClassicGuildRosterButton_SetStringText(button.string3, weeklyXP, onlineOrMobile)
				if ( weeklyXP == 0 ) then
					button.barTexture:Hide();
				else
					button.barTexture:SetWidth(weeklyXP / maxWeeklyXP * GUILD_ROSTER_BAR_MAX);
					button.barTexture:Show();
				end
				ClassicGuildRosterButton_SetStringText(button.barLabel, "#"..weeklyRank, onlineOrMobile);
			elseif ( currentGuildView == "totalxp" ) then
				local weeklyXP, totalXP, weeklyRank, totalRank = GetGuildRosterContribution(index);
				ClassicGuildRosterButton_SetStringText(button.string1, level, onlineOrMobile);
				button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]));
				ClassicGuildRosterButton_SetStringText(button.string2, displayedName, onlineOrMobile, classFileName);
				ClassicGuildRosterButton_SetStringText(button.string3, totalXP, onlineOrMobile);
				if ( totalXP == 0 ) then
					button.barTexture:Hide();
				else
					button.barTexture:SetWidth(totalXP / maxTotalXP * GUILD_ROSTER_BAR_MAX);
					button.barTexture:Show();
				end
				ClassicGuildRosterButton_SetStringText(button.barLabel, "#"..totalRank, onlineOrMobile);
--]]
			elseif ( currentGuildView == "pve" ) then
				ClassicGuildRosterButton_SetStringText(button.string1, level, onlineOrMobile);
				button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]));
				ClassicGuildRosterButton_SetStringText(button.string2, displayedName, onlineOrMobile, classFileName);
				ClassicGuildRosterButton_SetStringText(button.string3, nil, onlineOrMobile);
				ClassicGuildRosterButton_SetStringText(button.string4, nil, onlineOrMobile);
			elseif ( currentGuildView == "achievement" ) then
				ClassicGuildRosterButton_SetStringText(button.string1, level, onlineOrMobile);
				button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]));
				ClassicGuildRosterButton_SetStringText(button.string2, displayedName, onlineOrMobile, classFileName);
				if ( achievementPoints >= 0 ) then
					ClassicGuildRosterButton_SetStringText(button.string3, achievementPoints, onlineOrMobile);
					if ( achievementPoints == 0 ) then
						button.barTexture:Hide();
					else
						button.barTexture:SetWidth(achievementPoints / maxAchievementsPoints * GUILD_ROSTER_BAR_MAX);
						button.barTexture:Show();
					end
				else
					ClassicGuildRosterButton_SetStringText(button.string3, NO_ROSTER_ACHIEVEMENT_POINTS, onlineOrMobile);
					button.barTexture:Hide();
				end
				ClassicGuildRosterButton_SetStringText(button.barLabel, "#"..achievementRank, onlineOrMobile);
			elseif ( currentGuildView == "reputation" ) then
				ClassicGuildRosterButton_SetStringText(button.string1, level, onlineOrMobile)
				button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]));
				ClassicGuildRosterButton_SetStringText(button.string2, displayedName, onlineOrMobile, classFileName);
				ClassicGuildRosterButton_SetStringText(button.string3, GetText("FACTION_STANDING_LABEL"..repStanding), onlineOrMobile);
			end
			button:Show();
			if ( mod(index, 2) == 0 ) then
				button.stripe:SetTexCoord(0.36230469, 0.38183594, 0.95898438, 0.99804688);
			else
				button.stripe:SetTexCoord(0.51660156, 0.53613281, 0.88281250, 0.92187500);
			end
			if ( selectedGuildMember == index ) then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end
		else
			button:Hide();
		end
	end
	local totalHeight = visibleMembers * (GUILD_ROSTER_BUTTON_HEIGHT + GUILD_ROSTER_BUTTON_OFFSET);
	local displayedHeight = numButtons * (GUILD_ROSTER_BUTTON_HEIGHT + GUILD_ROSTER_BUTTON_OFFSET);
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
end

function ClassicGuildRosterButton_OnClick(self, button)
	if ( currentGuildView == "tradeskill" ) then
		local skillID, isCollapsed, iconTexture, headerName, numOnline, numVisible, numPlayers,
			playerDisplayName, playerFullName, class, online, zone, skill, classFileName, isMobile = GetGuildTradeSkillInfo(self.guildIndex);
		if ( button == "LeftButton" ) then
			if ( CanViewGuildRecipes(skillID) ) then
				GetGuildMemberRecipes(playerFullName, skillID);
			end
		else
			ClassicGuildRoster_ShowMemberDropDown(playerFullName, online, isMobile);
		end
	else
		if ( button == "LeftButton" ) then
			if ( ClassicGuildMemberDetailFrame:IsShown() and self.guildIndex == ClassicGuildFrame.selectedGuildMember ) then
				SetGuildRosterSelection(0);
				ClassicGuildFrame.selectedGuildMember = 0;
				PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
				ClassicGuildMemberDetailFrame:Hide();
			else
				SetGuildRosterSelection(self.guildIndex);
				ClassicGuildFrame.selectedGuildMember = self.guildIndex;
				PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
				ClassicGuildFramePopup_Show(ClassicGuildMemberDetailFrame);
				L_CloseDropDownMenus();
			end
			ClassicGuildRoster_Update();
		else
			local fullName, rank, rankIndex, level, class, zone, note, officernote, online, isAway, classFileName, achievementPoints, achievementRank, isMobile, sorEligible, rep, guid = GetGuildRosterInfo(self.guildIndex);
			ClassicGuildRoster_ShowMemberDropDown(fullName, online, isMobile, guid);
		end
	end
end

function ClassicGuildRoster_ShowMemberDropDown(name, online, isMobile, guid)
	local initFunc = ClassicGuildMemberDropDown_Initialize;
	if ( not online and not isMobile ) then
		initFunc = ClassicGuildMemberOfflineDropDown_Initialize;
	end

	ClassicGuildMemberDropDown.name = name;
	ClassicGuildMemberDropDown.isMobile = isMobile;
	ClassicGuildMemberDropDown.initialize = initFunc;
	ClassicGuildMemberDropDown.guid = guid; --Not included on tradeskill pane
	L_ToggleDropDownMenu(1, nil, ClassicGuildMemberDropDown, "cursor");
end

function ClassicGuildMemberDropDown_Initialize()
	UnitPopup_ShowMenu(UIDROPDOWNMENU_OPEN_MENU, "GUILD", nil, ClassicGuildMemberDropDown.name, { guid = ClassicGuildMemberDropDown.guid });
end

function ClassicGuildMemberOfflineDropDown_Initialize()
	UnitPopup_ShowMenu(UIDROPDOWNMENU_OPEN_MENU, "GUILD_OFFLINE", nil, ClassicGuildMemberDropDown.name);
end

function ClassicGuildRoster_UpdateTradeSkills()
	local scrollFrame = ClassicGuildRosterContainer;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local button, index, class;
	local numTradeSkill = GetNumGuildTradeSkill();

	for i = 1, numButtons do
		button = buttons[i];
		index = offset + i;
		if ( index <= numTradeSkill ) then
			button.guildIndex = index;
			local skillID, isCollapsed, iconTexture, headerName, numOnline, numVisible, numPlayers, playerDisplayName, playerFullName, class, online, zone, skill, classFileName, isMobile, isAway = GetGuildTradeSkillInfo(index);
			button.online = online;
			if ( headerName ) then
				ClassicGuildRosterButton_SetStringText(button.string1, headerName, 1);
				ClassicGuildRosterButton_SetStringText(button.string2, "", 1);
				ClassicGuildRosterButton_SetStringText(button.string3, numOnline, 1);
				button.header:Show();
				button:UnlockHighlight();
				button.header.icon:SetTexture(iconTexture);
				button.header.name:SetText(headerName);
				button.header.collapsed = isCollapsed;
				if ( numVisible == 0 ) then
					button.header:Disable();
					button.header.icon:SetDesaturated(true);
					button.header.collapsedIcon:Hide();
					button.header.expandedIcon:Hide();
					if ( numPlayers > 0 and CanViewGuildRecipes(skillID) ) then
						button.header.allRecipes:Show();
					else
						button.header.allRecipes:Hide();
					end
					button.header.name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
					button.header.leftEdge:SetVertexColor(0.75, 0.75, 0.75);
					button.header.rightEdge:SetVertexColor(0.75, 0.75, 0.75);
					button.header.middle:SetVertexColor(0.75, 0.75, 0.75);
				else
					button.header:Enable();
					button.header.icon:SetDesaturated(false);
					if ( CanViewGuildRecipes(skillID) ) then
						button.header.allRecipes:Show();
					else
						button.header.allRecipes:Hide();
					end
					button.header.name:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
					button.header.leftEdge:SetVertexColor(1, 1, 1);
					button.header.rightEdge:SetVertexColor(1, 1, 1);
					button.header.middle:SetVertexColor(1, 1, 1);
					if ( isCollapsed ) then
						button.header.collapsedIcon:Show();
						button.header.expandedIcon:Hide();
					else
						button.header.expandedIcon:Show();
						button.header.collapsedIcon:Hide();
					end
				end
				button.header.skillID = skillID;
				button:Show();
			elseif ( playerDisplayName ) then
				if ( isMobile ) then
					if (isAway == 2) then
						playerDisplayName = MOBILE_BUSY_ICON..playerDisplayName;
					elseif (isAway == 1) then
						playerDisplayName = MOBILE_AWAY_ICON..playerDisplayName;
					else
						playerDisplayName = ChatFrame_GetMobileEmbeddedTexture(73/255, 177/255, 73/255)..playerDisplayName;
					end
				end
				local zoneText = zone;
				if(isMobile and not online) then zoneText = REMOTE_CHAT; end;
				ClassicGuildRosterButton_SetStringText(button.string1, playerDisplayName, online, classFileName);
				ClassicGuildRosterButton_SetStringText(button.string2, zoneText, online);
				ClassicGuildRosterButton_SetStringText(button.string3, "["..skill.."]", online);
				button.header:Hide();
				button:Show();
			else
				button:Hide();
			end
			if ( mod(index, 2) == 0 ) then
				button.stripe:SetTexCoord(0.36230469, 0.38183594, 0.95898438, 0.99804688);
			else
				button.stripe:SetTexCoord(0.51660156, 0.53613281, 0.88281250, 0.92187500);
			end
		else
			button:Hide();
		end
	end

	local totalHeight = numTradeSkill * (GUILD_ROSTER_BUTTON_HEIGHT + GUILD_ROSTER_BUTTON_OFFSET);
	local displayedHeight = numButtons * (GUILD_ROSTER_BUTTON_HEIGHT + GUILD_ROSTER_BUTTON_OFFSET);
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
end

function ClassicGuildRosterTradeSkillHeader_OnClick(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	if ( self.collapsed ) then
		ExpandGuildTradeSkillHeader(self.skillID);
	else
		CollapseGuildTradeSkillHeader(self.skillID);
	end
end

--****** Dropdown ***************************************************************

function ClassicGuildRoster_SetView(view)
	if ( not view or not GUILD_ROSTER_COLUMNS[view] ) then
		view = "playerStatus";
	end

	local numColumns = #GUILD_ROSTER_COLUMNS[view];
	local stringsInfo = { };
	local stringOffset = 0;
	local haveIcon, haveBar;

	-- set up columns
	for columnIndex = 1, GUILD_ROSTER_MAX_COLUMNS do
		local columnButton = _G["ClassicGuildRosterColumnButton"..columnIndex];
		local columnType = GUILD_ROSTER_COLUMNS[view][columnIndex];
		if ( columnType ) then
			local columnData = GUILD_ROSTER_COLUMN_DATA[columnType];
			columnButton:SetText(columnData.text);
			WhoFrameColumn_SetWidth(columnButton, columnData.width);
			columnButton:Show();
			-- by default the sort type should be the same as the column type
			if ( columnData.sortType ) then
				columnButton.sortType = columnData.sortType;
			else
				columnButton.sortType = columnType;
			end
			if ( columnData.hasIcon ) then
				haveIcon = true;
			else
				-- store string data for processing
				columnData["stringOffset"] = stringOffset;
				table.insert(stringsInfo, columnData);
			end
			stringOffset = stringOffset + columnData.width - 2;
			haveBar = haveBar or columnData.hasBar;
		else
			columnButton:Hide();
		end
	end

	-- process the button strings
	local buttons = ClassicGuildRosterContainer.buttons;
	local button, fontString;
	for buttonIndex = 1, #buttons do
		button = buttons[buttonIndex];
		for stringIndex = 1, GUILD_ROSTER_MAX_STRINGS do
			fontString = button["string"..stringIndex];
			local stringData = stringsInfo[stringIndex];
			if ( stringData ) then
				-- want strings a little inside the columns, 6 pixels from the left and 8 from the right
				fontString:SetPoint("LEFT", stringData.stringOffset + GUILD_ROSTER_STRING_OFFSET, 0);
				fontString:SetWidth(stringData.width - GUILD_ROSTER_STRING_WIDTH_ADJ);
				fontString:SetJustifyH(stringData.stringJustify);
				fontString:Show();
			else
				fontString:Hide();
			end
		end

		if ( haveIcon ) then
			button.icon:Show();
		else
			button.icon:Hide();
		end
		if ( haveBar ) then
			button.barLabel:Show();
			-- button.barTexture:Show(); -- shown status determined in GuildRoster_Update
		else
			button.barLabel:Hide();
			button.barTexture:Hide();
		end
		button.header:Hide();
	end

	if ( view == "tradeskill" ) then
		ClassicGuildRoster_RecipeQueryCheck();
	end
	currentGuildView = view;
end

function ClassicGuildRosterViewDropdown_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, ClassicGuildRosterViewDropdown_Initialize);
	L_UIDropDownMenu_SetWidth(ClassicGuildRosterViewDropdown, 150);
end

function ClassicGuildRosterViewDropdown_Initialize()
	local info = L_UIDropDownMenu_CreateInfo();
	info.func = ClassicGuildRosterViewDropdown_OnClick;

	info.text = PLAYER_STATUS;
	info.value = "playerStatus";
	L_UIDropDownMenu_AddButton(info);
	info.text = GUILD_STATUS;
	info.value = "guildStatus";
	L_UIDropDownMenu_AddButton(info);
	info.text = ACHIEVEMENT_POINTS;
	info.value = "achievement";
	L_UIDropDownMenu_AddButton(info);
	info.text = TRADE_SKILLS;
	info.value = "tradeskill";
	L_UIDropDownMenu_AddButton(info);
	info.text = GUILD_REPUTATION;
	info.value = "reputation";
	L_UIDropDownMenu_AddButton(info);

	L_UIDropDownMenu_SetSelectedValue(ClassicGuildRosterViewDropdown, currentGuildView);
end

function ClassicGuildRosterViewDropdown_OnClick(self)
	ClassicGuildRoster_SetView(self.value);
	GuildRoster();
	ClassicGuildRoster_Update();
	SetCVar("guildRosterView", currentGuildView);
	L_UIDropDownMenu_SetSelectedValue(ClassicGuildRosterViewDropdown, currentGuildView);
end

--****** Promote/Demote *********************************************************

function ClassicGuildFrameDemoteButton_OnClick(self)
	local memberIndex = GetGuildRosterSelection();
	local fullName, rank, rankIndex = GetGuildRosterInfo(memberIndex);
	local targetRank = rankIndex + 1;	-- demoting increases rank index
	local validRank = GetDemotionRank(memberIndex);
	if ( validRank > targetRank ) then
		local badRankName = GuildControlGetRankName(targetRank + 1);		-- GuildControlGetRankName uses 1-based index
		local goodRankName = GuildControlGetRankName(validRank + 1);		-- GuildControlGetRankName uses 1-based index
		local dialog = StaticPopup_Show("GUILD_DEMOTE_CONFIRM", string.format(AUTHENTICATOR_CONFIRM_GUILD_DEMOTE, Ambiguate(fullName, "guild"), badRankName, goodRankName));
		dialog.data = fullName;
	else
		GuildDemote(ClassicGuildFrame.selectedName);
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
		ClassicGuildFrameDemoteButton:Disable();
	end
end

function ClassicGuildFramePromoteButton_OnClick(self)
	local memberIndex = GetGuildRosterSelection();
	local fullName, rank, rankIndex = GetGuildRosterInfo(memberIndex);
	local targetRank = rankIndex - 1;	-- promoting decreases rank index
	local validRank = GetPromotionRank(memberIndex);
	if ( validRank < targetRank ) then
		local badRankName = GuildControlGetRankName(targetRank + 1);		-- GuildControlGetRankName uses 1-based index
		local goodRankName = GuildControlGetRankName(validRank + 1);		-- GuildControlGetRankName uses 1-based index
		local dialog = StaticPopup_Show("GUILD_PROMOTE_CONFIRM", string.format(AUTHENTICATOR_CONFIRM_GUILD_PROMOTE, Ambiguate(fullName, "guild"), badRankName, goodRankName));
		dialog.data = fullName;
	else
		GuildPromote(ClassicGuildFrame.selectedName);
		PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
		ClassicGuildFramePromoteButton:Disable();
	end
end

function ClassicGuildMemberRankDropdown_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, ClassicGuildMemberRankDropdown_Initialize);
	L_UIDropDownMenu_SetWidth(ClassicGuildMemberRankDropdown, 159 - ClassicGuildMemberDetailRankLabel:GetWidth());
	L_UIDropDownMenu_JustifyText(ClassicGuildMemberRankDropdown, "LEFT");
end

function ClassicGuildMemberRankDropdown_Initialize(self)
	local numRanks = GuildControlGetNumRanks();
	local memberIndex = GetGuildRosterSelection();
	local _, _, memberRankIndex = GetGuildRosterInfo(GetGuildRosterSelection());
	memberRankIndex = memberRankIndex + 1;  -- adjust to 1-based
	local _, _, userRankIndex = GetGuildInfo("player");
	userRankIndex = userRankIndex + 1;	-- adjust to 1-based

	local highestRank = userRankIndex + 1;
	if not ( CanGuildPromote() ) then
		highestRank = memberRankIndex;
	end
	local lowestRank = numRanks;
	if not ( CanGuildDemote() ) then
		lowestRank = memberRankIndex;
	end

	for listRank = highestRank, lowestRank do
		local info = L_UIDropDownMenu_CreateInfo();
		info.text = GuildControlGetRankName(listRank);
		info.func = ClassicGuildMemberRankDropdown_OnClick;
		info.checked = listRank == memberRankIndex;
		info.value = listRank;
		info.arg1 = listRank;
		-- check
		if ( not info.checked ) then
			local allowed, reason = IsGuildRankAssignmentAllowed(memberIndex, listRank);
			if ( not allowed and reason == "authenticator" ) then
				info.disabled = true;
				info.tooltipWhileDisabled = 1;
				info.tooltipTitle = GUILD_RANK_UNAVAILABLE;
				info.tooltipText = GUILD_RANK_UNAVAILABLE_AUTHENTICATOR;
				info.tooltipOnButton = 1;
			end
		end
		L_UIDropDownMenu_AddButton(info);
	end
end

function ClassicGuildMemberRankDropdown_OnClick(self, newRankIndex)
	local fullName, rank, rankIndex = GetGuildRosterInfo(GetGuildRosterSelection());
	rankIndex = rankIndex + 1;
	if ( rankIndex ~= newRankIndex ) then
		SetGuildMemberRank(GetGuildRosterSelection(), newRankIndex);
	end
end
