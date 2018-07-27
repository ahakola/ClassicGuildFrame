local NEWS_MOTD = -1;				-- pseudo category
local NEWS_GUILD_ACHIEVEMENT = 0;
local NEWS_PLAYER_ACHIEVEMENT = 1;
local NEWS_DUNGEON_ENCOUNTER = 2;
local NEWS_ITEM_LOOTED = 3;
local NEWS_ITEM_CRAFTED = 4;
local NEWS_ITEM_PURCHASED = 5;
local NEWS_GUILD_LEVEL = 6;
local NEWS_GUILD_CREATE = 7;
local NEWS_LEGENDARY_LOOTED = 8;
local NEWS_GUILD_EVENT = 9;

local GUILD_EVENT_TEXTURES = {
	--[CALENDAR_EVENTTYPE_RAID]		= "Interface\\LFGFrame\\LFGIcon-",
	--[CALENDAR_EVENTTYPE_DUNGEON]	= "Interface\\LFGFrame\\LFGIcon-",
	[CALENDAR_EVENTTYPE_PVP]		= "Interface\\Calendar\\UI-Calendar-Event-PVP",
	[CALENDAR_EVENTTYPE_MEETING]	= "Interface\\Calendar\\MeetingIcon",
	[CALENDAR_EVENTTYPE_OTHER]		= "Interface\\Calendar\\UI-Calendar-Event-Other",
};

function ClassicGuildNewsFrame_OnLoad(self)
	ClassicGuildFrame_RegisterPanel(self);
	self:RegisterEvent("GUILD_NEWS_UPDATE");
	self:RegisterEvent("GUILD_MOTD");
	self:RegisterEvent("GUILD_ROSTER_UPDATE");
	local fontString = ClassicGuildNewsSetFiltersButton:GetFontString();
	ClassicGuildNewsSetFiltersButton:SetHeight(fontString:GetHeight() + 4);
	ClassicGuildNewsSetFiltersButton:SetWidth(fontString:GetWidth() + 4);
	ClassicGuildNewsContainer.update = ClassicGuildNews_Update;
	HybridScrollFrame_CreateButtons(ClassicGuildNewsContainer, "ClassicGuildNewsButtonTemplate", 0, 0);

	if ( GetGuildFactionGroup() == 0 ) then  -- horde
		GUILD_EVENT_TEXTURES[CALENDAR_EVENTTYPE_PVP] = "Interface\\Calendar\\UI-Calendar-Event-PVP01";
	else  -- alliance
		GUILD_EVENT_TEXTURES[CALENDAR_EVENTTYPE_PVP] = "Interface\\Calendar\\UI-Calendar-Event-PVP02";
	end
end

function ClassicGuildNewsFrame_OnShow(self)
	GuildNewsSort(0);	-- normal sort, taking into account filters and stickies
end

function ClassicGuildNewsFrame_OnHide(self)
	if ( ClassicGuildNewsDropDown.newsIndex ) then
		L_CloseDropDownMenus();
	end
end

function ClassicGuildNewsFrame_OnEvent(self, event)
	if ( self:IsShown() ) then
		ClassicGuildNews_Update();
	end
end

function ClassicGuildNews_Update()
	-- check to display impeach frame
	if ( CanReplaceGuildMaster() ) then
		ClassicGuildGMImpeachButton:Show();
		ClassicGuildNewsContainer:SetPoint("TOPLEFT", ClassicGuildGMImpeachButton, "BOTTOMLEFT", 0, 0);
		ClassicGuildNewsContainer:SetHeight(277);
	else
		ClassicGuildGMImpeachButton:Hide();
		ClassicGuildNewsContainer:SetPoint("TOPLEFT", ClassicGuildNewsFrameHeader, "BOTTOMLEFT", 0, 0);
		ClassicGuildNewsContainer:SetHeight(287);
	end

	local motd = GetGuildRosterMOTD();
	local scrollFrame = ClassicGuildNewsContainer;
	local haveMOTD = motd ~= "" and 1 or 0;
	local buttons = scrollFrame.buttons;
	local button, index;

	local numEvents = math.min(7, C_Calendar.GetNumGuildEvents());
	local numNews = GetNumGuildNews();
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local numButtons = #buttons;
	for i = 1, numButtons do
		button = buttons[i];
		button.icon:Hide();
		button.dash:Hide();
		button.header:Hide();
		button:Show();
		button:Enable();
		index = offset + i;
		if( index == haveMOTD ) then
			ClassicGuildNewsButton_SetMOTD(button, motd);
		elseif( index <= numEvents + haveMOTD ) then
			ClassicGuildNewsButton_SetEvent(button, index - haveMOTD);
		elseif( index <= numEvents + haveMOTD + numNews  ) then
			ClassicGuildNewsButton_SetNews( button, index - haveMOTD - numEvents  );
		else
			button:Hide();
		end
	end

	-- update tooltip
	if ( ClassicGuildNewsFrame.activeButton ) then
		ClassicGuildNewsButton_OnEnter(ClassicGuildNewsFrame.activeButton);
	end

	-- hide dropdown menu
	if ( ClassicGuildNewsDropDown.newsIndex ) then
		L_CloseDropDownMenus();
	end

	if ( numNews == 0 and haveMOTD == 0 and numEvents == 0 ) then
		ClassicGuildNewsFrameNoNews:Show();
	else
		ClassicGuildNewsFrameNoNews:Hide();
	end
	local totalHeight = (numNews + haveMOTD + numEvents) * scrollFrame.buttonHeight;
	local displayedHeight = numButtons * scrollFrame.buttonHeight;
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
	ClassicGuildFrame_UpdateScrollFrameWidth(scrollFrame);
end

function ClassicGuildNewsButton_SetText( button, text_color, text, ...)
	button.text:SetFormattedText(text, ...);
	button.text:SetTextColor(text_color.r, text_color.g, text_color.b);
end

local icon_table = {
	motd = { width = 16, height = 11, texture = "Interface\\GuildFrame\\GuildExtra", texcoords={0.56640625, 0.59765625, 0.86718750, 0.95312500}},
	[CALENDAR_EVENTTYPE_PVP] = { width = 14, height = 14, texture = "Interface\\Calendar\\UI-Calendar-Event-PVP", texcoords={0, 1, 0, 1}},
	[CALENDAR_EVENTTYPE_MEETING] = { width = 14, height = 14, texture = "Interface\\Calendar\\MeetingIcon", texcoords={0, 1, 0, 1}},
	[CALENDAR_EVENTTYPE_OTHER] = { width = 14, height = 14, texture = "Interface\\Calendar\\UI-Calendar-Event-Other", texcoords={0, 1, 0, 1}},
	event = { width = 14, height = 14, texcoords={0, 1, 0, 1}},
	news = { width = 13, height = 11, texture = "Interface\\GuildFrame\\GuildFrame", texcoords={0.41406250, 0.42675781, 0.96875000, 0.99023438}},
}
function ClassicGuildNewsButton_SetIcon( button, icon_type, override_texture )
	if ( button.icon.type ~= icon_type ) then
		button.icon.type = icon_type;
		local icon = icon_table[icon_type]
		if ( icon ) then
			button.icon:SetSize(icon.width, icon.height);
			button.icon:SetTexture( icon.texture or override_texture );
			button.icon:SetTexCoord(icon.texcoords[1], icon.texcoords[2], icon.texcoords[3], icon.texcoords[4]);
		end
	end
	button.icon:Show();
end

function ClassicGuildNewsButton_SetMOTD( button, text )
	button.text:SetPoint("LEFT", 24, 0);
	ClassicGuildNewsButton_SetIcon(button,"motd");
	ClassicGuildNewsButton_SetText(button, HIGHLIGHT_FONT_COLOR, GUILD_NEWS_MOTD, text);
	button.index = nil;
	button.newsType = NEWS_MOTD;
end

local SIX_DAYS = 6 * 24 * 60 * 60		-- time in seconds
function ClassicGuildNewsButton_SetEvent( button, event_id )
	local today = date("*t");
	local info = C_Calendar.GetGuildEventInfo(event_id);
	local month = info.month;
	local day = info.monthDay;
	local weekday = info.weekday;
	local hour = info.hour;
	local minute = info.minute;
	local eventType = info.eventType;
	local title = info.title;
	local calendarType = info.calendarType;
	local texture = info.texture;
	local displayTime = GameTime_GetFormattedTime(hour, minute, true);
	local displayDay;

	if ( today["day"] == day and today["month"] == month ) then
		displayDay = NORMAL_FONT_COLOR_CODE..GUILD_EVENT_TODAY..FONT_COLOR_CODE_CLOSE;
	else
		local year = today["year"];
		-- if in December and looking at an event in January
		if ( month < today["month"] ) then
			year = year + 1;
		end
		-- display the day or the date
		local eventTime = time{year = year, month = month, day = day};
		if ( eventTime - time() < SIX_DAYS ) then
			displayDay = CALENDAR_WEEKDAY_NAMES[weekday];
		else
			displayDay = string.format(GUILD_NEWS_DATE, CALENDAR_WEEKDAY_NAMES[weekday], day, month);
		end
	end
	ClassicGuildNewsButton_SetText(button, HIGHLIGHT_FONT_COLOR, GUILD_EVENT_FORMAT, displayDay, displayTime, title);

	button.text:SetPoint("LEFT", 24, 0);
	ClassicGuildNewsButton_SetIcon( button, texture);
	button.index = event_id;
	button.newsType = NEWS_GUILD_EVENT;

	button.isEvent = true;
end

function ClassicGuildNewsButton_SetNews( button, news_id )
	local isSticky, isHeader, newsType, text1, text2, id, data, data2, weekday, day, month, year = GetGuildNewsInfo(news_id);
	if ( isHeader ) then
		button.text:SetPoint("LEFT", 14, 0);
		ClassicGuildNewsButton_SetText( button, NORMAL_FONT_COLOR, GUILD_NEWS_DATE, CALENDAR_WEEKDAY_NAMES[weekday + 1], day + 1, month + 1);
		button.header:Show();
		button:Disable();
	else
		button.text:SetPoint("LEFT", 24, 0);
		if ( isSticky ) then
			ClassicGuildNewsButton_SetIcon(button, "news");
		else
			button.dash:Show();
		end
		text1 = text1 or UNKNOWN;
		button.index = news_id;
		button.newsType = newsType;
		button.id = id;
		-- Bug 356148: For NEWS_ITEM types, data2 has the item upgrade ID
		button.data2 = data2;
		if ( text2 and text2 ~= UNKNOWN ) then
			if ( newsType == NEWS_ITEM_LOOTED or newsType == NEWS_ITEM_CRAFTED or newsType == NEWS_ITEM_PURCHASED ) then
				-- item link is already filled out from GetGuildNewsInfo
			elseif ( newsType == NEWS_PLAYER_ACHIEVEMENT ) then
				text2 = ACHIEVEMENT_COLOR_CODE.."["..text2.."]|r";
			elseif ( newsType == NEWS_GUILD_ACHIEVEMENT ) then
				text1 = ACHIEVEMENT_COLOR_CODE.."["..text2.."]|r";	-- only using achievement name
			elseif ( newsType == NEWS_DUNGEON_ENCOUNTER ) then
				text2 = "|cffd10000["..text2.."]|r";
			end
		elseif ( newsType ~= NEWS_GUILD_CREATE ) then
			-- no right-click menu or tooltip for unresolved news items
			button.index = nil;
			button.newsType = nil;
			text2 = UNKNOWN;
			if ( newsType == NEWS_GUILD_ACHIEVEMENT ) then
				text1 = text2;	-- only using achievement name
			end
		end

		if ( newsType ) then
			ClassicGuildNewsButton_SetText( button, HIGHLIGHT_FONT_COLOR, _G["GUILD_NEWS_FORMAT"..newsType], text1, text2);
		end
	end
	button.isEvent = nil;
end

function ClassicGuildNewsButton_OnEnter(self)
	ClassicGuildNewsFrame.activeButton = self;
	ClassicGuildNewsBossModel:Hide();
	GameTooltip:Hide();
	local newsType = self.newsType;
	self.UpdateTooltip = nil;
	if ( newsType == NEWS_ITEM_LOOTED or newsType == NEWS_ITEM_CRAFTED or newsType == NEWS_ITEM_PURCHASED or newsType == NEWS_LEGENDARY_LOOTED ) then
		ClassicGuildNewsButton_AnchorTooltip(self);
		local _, _, _, _, text2, _, _, _ = GetGuildNewsInfo(self.index);
		GameTooltip:SetHyperlink(text2);
		self.UpdateTooltip = ClassicGuildNewsButton_OnEnter;
	elseif ( newsType == NEWS_PLAYER_ACHIEVEMENT or newsType == NEWS_GUILD_ACHIEVEMENT ) then
		local achievementId = self.id;
		local _, name, _, _, _, _, _, description = GetAchievementInfo(achievementId);
		ClassicGuildNewsButton_AnchorTooltip(self);
		GameTooltip:SetText(ACHIEVEMENT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE);
		GameTooltip:AddLine(description, 1, 1, 1, true);
		local firstCriteria = true;
		local leftCriteria;
		for i = 1, GetAchievementNumCriteria(achievementId) do
			local criteriaString, _, _, _, _, _, flags = GetAchievementCriteriaInfo(achievementId, i);
			-- skip progress bars
			if ( bit.band(flags, EVALUATION_TREE_FLAG_PROGRESS_BAR) ~= EVALUATION_TREE_FLAG_PROGRESS_BAR ) then
				if ( leftCriteria ) then
					if ( firstCriteria ) then
						GameTooltip:AddLine(" ");
						firstCriteria = false;
					end
					GameTooltip:AddDoubleLine(leftCriteria, criteriaString, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8);
					leftCriteria = nil;
				else
					leftCriteria = criteriaString;
				end
			end
		end
		-- check for leftover criteria
		if ( leftCriteria ) then
			if ( firstCriteria ) then
				GameTooltip:AddLine(" ");
			end
			GameTooltip:AddLine(leftCriteria, 0.8, 0.8, 0.8);
		end
		GameTooltip:Show();
	elseif ( newsType == NEWS_DUNGEON_ENCOUNTER ) then
		local isSticky, isHeader, newsType, text1, text2, id, data1, data2 = GetGuildNewsInfo(self.index);
		local zone = GetRealZoneText(data1);
		if ( data2 and data2 > 0 ) then
			ClassicGuildNewsBossModel:Show();
			ClassicGuildNewsBossModel:SetDisplayInfo(data2);
			ClassicGuildNewsBossNameText:SetText(text2);
			ClassicGuildNewsBossLocationText:SetText(zone);
		else
			ClassicGuildNewsButton_AnchorTooltip(self);
			GameTooltip:SetText(text2);
			GameTooltip:AddLine(zone, 1, 1, 1);
			GameTooltip:Show();
		end
	elseif ( newsType == NEWS_MOTD ) then
		if ( self.text:IsTruncated() ) then
			ClassicGuildNewsButton_AnchorTooltip(self);
			GameTooltip:SetText(GUILD_MOTD_LABEL);
			GameTooltip:AddLine(GetGuildRosterMOTD(), 1, 1, 1, true);
			GameTooltip:Show();
		end
	end
end

function ClassicGuildNewsButton_AnchorTooltip(self)
	if ( ClassicGuildNewsContainer.wideButtons ) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 8, 0);
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 30, 0);
	end
end

function ClassicGuildNewsButton_OnClick(self, button)
	if ( button == "RightButton" ) then
		local dropDown = ClassicGuildNewsDropDown;
		if ( dropDown.newsIndex ~= self.index ) then
			L_CloseDropDownMenus();
		end
		dropDown.newsIndex = self.index;
		dropDown.onHide = ClassicGuildNewsDropDown_OnHide;
		L_ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3);
	end
end

function ClassicGuildNewsButton_OnLeave(self)
	ClassicGuildNewsFrame.activeButton = nil;
	GameTooltip:Hide();
	ClassicGuildNewsBossModel:Hide();
end

--****** Dropdown **************************************************************

function ClassicGuildNewsDropDown_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, ClassicGuildNewsDropDown_Initialize, "MENU");
end

function ClassicGuildNewsDropDown_Initialize(self)
	if ( not self.newsIndex ) then
		return;
	end

	local isSticky, isHeader, newsType, text1, text2, id, data, data2, weekday, day, month, year = GetGuildNewsInfo(self.newsIndex);
	-- we don't have any options for these combinations
	if ( ( newsType == NEWS_DUNGEON_ENCOUNTER or newsType == NEWS_GUILD_LEVEL or newsType == NEWS_GUILD_CREATE ) and not CanEditMOTD() ) then
		return;
	end

	local info = L_UIDropDownMenu_CreateInfo();
	info.notCheckable = 1;
	info.isTitle = 1;
	if ( newsType == NEWS_GUILD_CREATE ) then
		info.text = GUILD_CREATION;
	else
		info.text = text2;
	end
	L_UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
	info = L_UIDropDownMenu_CreateInfo();
	info.notCheckable = 1;

	if ( newsType == NEWS_PLAYER_ACHIEVEMENT or newsType == NEWS_GUILD_ACHIEVEMENT ) then
		info.func = ClassicGuildFrame_OpenAchievement;
		info.text = GUILD_NEWS_VIEW_ACHIEVEMENT;
		info.arg1 = id;
		L_UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
	elseif ( newsType == NEWS_ITEM_LOOTED or newsType == NEWS_ITEM_CRAFTED or newsType == NEWS_ITEM_PURCHASED ) then
		info.func = ClassicGuildFrame_LinkItem;
		info.text = GUILD_NEWS_LINK_ITEM;
		info.arg1 = id;
		info.arg2 = text2;	-- text2 has the hyperlink text
		L_UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
	end
	if ( CanEditMOTD() ) then
		info.arg1 = self.newsIndex;
		if ( isSticky ) then
			info.text = GUILD_NEWS_REMOVE_STICKY;
			info.arg2 = 0;
		else
			info.text = GUILD_NEWS_MAKE_STICKY;
			info.arg2 = 1;
		end
		info.func = ClassicGuildNewsDropDown_SetSticky;
		L_UIDropDownMenu_AddButton(info, UIDROPDOWN_MENU_LEVEL);
	end
end

function ClassicGuildNewsDropDown_OnHide(self)
	ClassicGuildNewsDropDown.newsIndex = nil;
end

function ClassicGuildNewsDropDown_SetSticky(button, newsIndex, value)
	ClassicGuildNewsSetSticky(newsIndex, value);
end

--****** Popup *****************************************************************

function ClassicGuildNewsFiltersFrame_OnLoad(self)
	ClassicGuildFrame_RegisterPopup(self);
	for _, filterButton in ipairs(self.ClassicGuildNewsFilterButtons) do
		filterButton.Text:SetText(_G["GUILD_NEWS_FILTER"..filterButton:GetID()]);
	end
end

function ClassicGuildNewsFiltersFrame_OnShow(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	local filters = { GetGuildNewsFilters() };
	for i = 1, #filters do
		-- skip 8th flag - guild creation
		local checkbox = self.ClassicGuildNewsFilterButtons[i];
		if ( checkbox ) then
			if ( filters[i] ) then
				checkbox:SetChecked(true);
			else
				checkbox:SetChecked(false);
			end
		end
	end
end

function ClassicGuildNewsFilter_OnClick(self)
	local setting;
	if ( self:GetChecked() ) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		setting = 1;
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
		setting = 0;
	end
	SetGuildNewsFilter(self:GetID(), setting);
end
