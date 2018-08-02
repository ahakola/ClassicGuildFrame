
ClassicFrameMixin = CreateFromMixins(CallbackRegistryBaseMixin);

ClassicFrameMixin:GenerateCallbackEvents(
{
    "InviteAccepted",
    "InviteDeclined",
	"TicketAccepted",
	"DisplayModeChanged",
	"ClubSelected",
	"StreamSelected",
});

local COMMUNITIES_FRAME_EVENTS = {
	"CLUB_STREAMS_LOADED",
	"CLUB_STREAM_ADDED",
	"CLUB_STREAM_REMOVED",
	"CLUB_ADDED",
	"CLUB_REMOVED",
	"CLUB_SELF_MEMBER_ROLE_UPDATED",
	"STREAM_VIEW_MARKER_UPDATED",
	"BN_DISCONNECTED",
	"PLAYER_GUILD_UPDATE",
	"CHANNEL_UI_UPDATE",
	"UPDATE_CHAT_COLOR",
};

local COMMUNITIES_STATIC_POPUPS = {
	"INVITE_COMMUNITY_MEMBER",
	"INVITE_COMMUNITY_MEMBER_WITH_INVITE_LINK",
	"CONFIRM_DESTROY_COMMUNITY",
	"CONFIRM_REMOVE_COMMUNITY_MEMBER",
	"SET_COMMUNITY_MEMBER_NOTE",
	"CONFIRM_DESTROY_COMMUNITY_STREAM",
	"CONFIRM_LEAVE_AND_DESTROY_COMMUNITY",
	"CONFIRM_LEAVE_COMMUNITY",
};

function ClassicFrameMixin:OnLoad()
	ClassicGuildFrame_RegisterPanel(self);
	CallbackRegistryBaseMixin.OnLoad(self);

	L_UIDropDownMenu_Initialize(self.StreamDropDownMenu, ClassicStreamDropDownMenu_Initialize);

	self.selectedStreamForClub = {};
	self.privilegesForClub = {};
	self.newClubIds = {};
end

function ClassicFrameMixin:OnShow()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);

	-- Don't allow ChannelFrame and CommunitiesFrame to show at the same time, because they share one presence subscription
	if ChannelFrame and ChannelFrame:IsShown() then
		HideUIPanel(ChannelFrame);
	end

	local clubId = self:GetSelectedClubId();
	if clubId  then
		C_Club.SetClubPresenceSubscription(clubId);
	end

	FrameUtil.RegisterFrameForEvents(self, COMMUNITIES_FRAME_EVENTS);
	self:UpdateClubSelection();
	self:UpdateStreamDropDown();
	UpdateMicroButtons();
end

function ClassicFrameMixin:OnEvent(event, ...)
	if event == "CLUB_STREAMS_LOADED" then
		local clubId = ...;
		self:StreamsLoadedForClub(clubId);
		if clubId == self:GetSelectedClubId() then
			local streams = C_Club.GetStreams(clubId);
			if not self:GetSelectedStreamForClub(clubId) then
				self:SelectStream(clubId, streams[1].streamId);
			end

			self:UpdateStreamDropDown();
		end
	elseif event == "CLUB_STREAM_ADDED" then
		local clubId, streamId = ...;
		if clubId == self:GetSelectedClubId() then
			if not self:GetSelectedStreamForClub(clubId) then
				self:SelectStream(clubId, streamId);
			end

			self:UpdateStreamDropDown();
		end
	elseif event == "CLUB_STREAM_REMOVED" then
		local clubId, streamId = ...;
		local selectedStream = self:GetSelectedStreamForClub(clubId);
		local isSelectedClub = clubId == self:GetSelectedClubId();
		local isSelectedStream = selectedStream and selectedStream.streamId == streamId;
		if isSelectedClub or isSelectedStream then
			local streams = C_Club.GetStreams(clubId);
			if isSelectedStream and #streams > 0 then
				self:SelectStream(clubId, streams[1].streamId);
			end

			if isSelectedClub then
				self:UpdateStreamDropDown();
			end
		end
	elseif event == "CLUB_ADDED" then
		local clubId = ...;
		self:AddNewClubId(clubId);

		if self:GetSelectedClubId() == nil then
			self:UpdateClubSelection();
		end
	elseif event == "CLUB_REMOVED" then
		local clubId = ...;
		self:SetPrivilegesForClub(clubId, nil);
		if clubId == self:GetSelectedClubId() then
			self:UpdateClubSelection();
		end
	elseif event == "CLUB_SELF_MEMBER_ROLE_UPDATED" then
		local clubId, roleId = ...;
		if clubId == self:GetSelectedClubId() then
			self:SetPrivilegesForClub(clubId, C_Club.GetClubPrivileges(clubId));
		else
			self:SetPrivilegesForClub(clubId, nil);
		end
	elseif event == "STREAM_VIEW_MARKER_UPDATED" then
		if self.StreamDropDownMenu:IsShown() then
			self.StreamDropDownMenu:UpdateUnreadNotification();
		end

		if self.ClassicListDropDownMenu:IsShown() then
			self.ClassicListDropDownMenu:UpdateUnreadNotification();
		end
	elseif event == "BN_DISCONNECTED" then
		HideUIPanel(self);
	elseif event == "PLAYER_GUILD_UPDATE" then
		local guildClubId = C_Club.GetGuildClubId();
		if guildClubId ~= nil and guildClubId == self:GetSelectedClubId() then
			--SetLargeGuildTabardTextures("player", self.PortraitOverlay.TabardEmblem, self.PortraitOverlay.TabardBackground, self.PortraitOverlay.TabardBorder);
			SetLargeGuildTabardTextures("player", ClassicGuildFrameTabardEmblem, ClassicGuildFrameTabardBackground, ClassicGuildFrameTabardBorder);
		end
	elseif event == "CHANNEL_UI_UPDATE" or event == "UPDATE_CHAT_COLOR" then
		self:UpdateStreamDropDown();
	end
end

function ClassicFrameMixin:AddNewClubId(clubId)
	self.newClubIds[#self.newClubIds + 1] = clubId;
end

function ClassicFrameMixin:StreamsLoadedForClub(clubId)
	-- When you add a new club we want to add the general stream to your chat window.
	if not ChatFrame_CanAddChannel() then
		return;
	end
	
	for i, newClubId in ipairs(self.newClubIds) do
		if newClubId == clubId then
			local streams = C_Club.GetStreams(clubId);
			if streams then
				for i, stream in ipairs(streams) do
					if stream.streamType == Enum.ClubStreamType.General then
						local DEFAULT_CHAT_FRAME_INDEX = 1;
						ChatFrame_AddNewCommunitiesChannel(DEFAULT_CHAT_FRAME_INDEX, clubId, stream.streamId);
						table.remove(self.newClubIds, i);
						break;
					end
				end
			end
		end
	end
end

function ClassicFrameMixin:CloseActiveSubPanel()
	if self.activeSubPanel then
		HideUIPanel(self.activeSubPanel);
		self.activeSubPanel = nil;
	end
end

function ClassicFrameMixin:RegisterDialogShown(dialog) -- ???
	self:CloseActiveDialogs(dialog);
	self.lastActiveDialog = dialog;
end

function ClassicFrameMixin:CloseStaticPopups() -- ???
	for i, popup in ipairs(COMMUNITIES_STATIC_POPUPS) do
		if StaticPopup_Visible(popup) then
			StaticPopup_Hide(popup);
		end
	end
end

function ClassicFrameMixin:CloseActiveDialogs(dialogBeingShown) -- ???
	L_CloseDropDownMenus();

	self:CloseStaticPopups();
	
	self:CloseActiveSubPanel();
	
	if self.lastActiveDialog ~= nil and self.lastActiveDialog ~= dialogBeingShown then
		self.lastActiveDialog:Hide();
		self.lastActiveDialog = nil;
	end
end

function ClassicFrameMixin:UpdateClubSelection()
	local lastSelectedClubId = tonumber(GetCVar("lastSelectedClubId")) or 0;
	local clubs = C_Club.GetSubscribedClubs();
	for i, club in ipairs(clubs) do
		if club.clubId == lastSelectedClubId then
			self:SelectClub(club.clubId);
			return;
		end
	end

	CommunitiesUtil.SortClubs(clubs);
	if #clubs > 0 then
		self:SelectClub(clubs[1].clubId);
		return;
	end

	self:SetDisplayMode(CLASSIC_FRAME_DISPLAY_MODES.MINIMIZED);
end

function ClassicFrameMixin:SelectClub(clubId, forceUpdate)
	if forceUpdate or clubId ~= self.selectedClubId then
		self.ChatEditBox:SetEnabled(clubId ~= nil);
		self.selectedClubId = clubId;
		self:OnClubSelected(clubId);
	end
end

local CLASSIC_FRAME_DISPLAY_MODES = {
	MINIMIZED = {
		"ClassicListDropDownMenu",
		"Chat",
		"ChatEditBox",
		"StreamDropDownMenu",
		"VoiceChatHeadset",
	},
};

function ClassicFrameMixin:SetDisplayMode(displayMode)
	if self.displayMode == displayMode then
		return;
	end
	
	self:CloseActiveDialogs();
	
	self.displayMode = displayMode;
	
	local subframesToUpdate = {};
	for i, mode in pairs(CLASSIC_FRAME_DISPLAY_MODES) do
		for j, subframe in ipairs(mode) do
			subframesToUpdate[subframe] = subframesToUpdate[subframe] or mode == displayMode;
		end
	end
	
	for subframe, shouldShow in pairs(subframesToUpdate) do
		self[subframe]:SetShown(shouldShow);
	end
end

function ClassicFrameMixin:OnClubSelected(clubId)
	local clubSelected = clubId ~= nil;
	self:CloseActiveDialogs();
	self.ChatEditBox:SetEnabled(clubSelected);
	if clubSelected then
		SetCVar("lastSelectedClubId", clubId)
	
		C_Club.SetClubPresenceSubscription(clubId);
		
		local clubInfo = C_Club.GetClubInfo(clubId);
		if clubInfo then
			local selectedStream = self:GetSelectedStreamForClub(clubId);
			if selectedStream ~= nil then
				self:SelectStream(clubId, selectedStream.streamId);
			else
				local streams = C_Club.GetStreams(clubId);
				CommunitiesUtil.SortStreams(streams);
				if #streams >= 1 then
					self:SelectStream(clubId, streams[1].streamId);
				else
					self:SelectStream(clubId, nil);
				end
			end
			
			if not self:HasPrivilegesForClub(clubId) then
				self:SetPrivilegesForClub(clubId, C_Club.GetClubPrivileges(clubId));
			end
			
			if clubInfo.clubType == Enum.ClubType.Guild then
				GuildRoster();
			end
		end
	end
	
	self:TriggerEvent(ClassicFrameMixin.Event.ClubSelected, clubId);
	
	self:UpdateStreamDropDown(); -- TODO:: Convert this to use the registry system of callbacks.
end

function ClassicFrameMixin:GetSelectedClubId()
	return self.selectedClubId;
end

function ClassicFrameMixin:GetSelectedStreamId()
	if not self.selectedClubId then
		return nil;
	end
	
	local stream = self:GetSelectedStreamForClub(self.selectedClubId);
	if not stream then
		return nil;
	end
	
	return stream.streamId;
end

function ClassicFrameMixin:SetFocusedStream(clubId, streamId)
	if self.focusedClubId and self.focusedStreamId then
		C_Club.UnfocusStream(self.focusedClubId, self.focusedStreamId);
	end
	
	self.focusedClubId = clubId;
	self.focusedStreamId = streamId;
	
	if clubId and streamId and not C_Club.FocusStream(clubId, streamId) then
		-- TODO:: Emit an error that we couldn't focus the stream.
	end
end

function ClassicFrameMixin:SelectStream(clubId, streamId)
	if streamId == nil then
		self.selectedStreamForClub[clubId] = nil;
		self:TriggerEvent(ClassicFrameMixin.Event.StreamSelected, streamId);
	else
		local streams = C_Club.GetStreams(clubId);
		for i, stream in ipairs(streams) do
			if stream.streamId == streamId then
				self.selectedStreamForClub[clubId] = stream;
				
				if clubId == self:GetSelectedClubId() then
					self:SetFocusedStream(clubId, streamId);
					C_Club.SetAutoAdvanceStreamViewMarker(clubId, streamId);
					if C_Club.IsSubscribedToStream(clubId, streamId) then
						self.Chat:RequestInitialMessages(clubId, streamId);
					end
					
					self:TriggerEvent(ClassicFrameMixin.Event.StreamSelected, streamId);
					self:UpdateStreamDropDown();

					self.VoiceChatHeadset.Button:SetCommunityInfo(clubId, stream);
				end
			end
		end
	end
end

function ClassicFrameMixin:GetSelectedStreamForClub(clubId)
	return self.selectedStreamForClub[clubId];
end

function ClassicFrameMixin:SetPrivilegesForClub(clubId, privileges)
	self.privilegesForClub[clubId] = privileges;
end

function ClassicFrameMixin:GetPrivilegesForClub(clubId)
  return self.privilegesForClub[clubId] or {};
end

function ClassicFrameMixin:HasPrivilegesForClub(clubId)
	return self.privilegesForClub[clubId] ~= nil;
end

function ClassicFrameMixin:UpdateStreamDropDown()
	local clubId = self:GetSelectedClubId();
	local selectedStream = self:GetSelectedStreamForClub(clubId);
	L_UIDropDownMenu_SetSelectedValue(self.StreamDropDownMenu, selectedStream and selectedStream.streamId or nil, true);
	local streamName = selectedStream and ClassicStreamDropDownMenu_GetStreamName(clubId, selectedStream) or "";
	L_UIDropDownMenu_SetText(self.StreamDropDownMenu, streamName);
	self.StreamDropDownMenu:UpdateUnreadNotification();
end

function ClassicFrameMixin:OnHide()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
	
	self:CloseActiveDialogs();
	C_Club.ClearClubPresenceSubscription();
	FrameUtil.UnregisterFrameForEvents(self, COMMUNITIES_FRAME_EVENTS);
	UpdateMicroButtons();
end

function ClassicFrameMixin:ShowCreateChannelDialog()
	self.EditStreamDialog:ShowCreateDialog(self:GetSelectedClubId());
end

function ClassicFrameMixin:ShowEditStreamDialog(clubId, streamId)
	local stream = C_Club.GetStreamInfo(clubId, streamId);
	if stream then
		self.EditStreamDialog:ShowEditDialog(clubId, stream);
	end
end

function ClassicFrameMixin:ShowNotificationSettingsDialog(clubId)
	self.NotificationSettingsDialog:SelectClub(clubId);
	self.NotificationSettingsDialog:Show();
end
