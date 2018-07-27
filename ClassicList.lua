ClassicListDropDownMenuMixin = {};

function ClassicListDropDownMenuMixin:OnLoad()
	L_UIDropDownMenu_SetWidth(self, self.width or 115);
	self.Text:SetJustifyH("LEFT");
end

function ClassicListDropDownMenuMixin:OnShow()
	L_UIDropDownMenu_Initialize(self, ClassicListDropDownMenu_Initialize);
	local parent = self:GetParent();
	L_UIDropDownMenu_SetSelectedValue(self, parent:GetSelectedClubId());
	self:UpdateUnreadNotification();

	if parent.RegisterCallback then
		local function ClassicClubSelectedCallback(event, clubId)
			if clubId and self:IsVisible() then
				self:OnClubSelected();
			end
		end

		self.clubSelectedCallback = ClassicClubSelectedCallback;
		parent:RegisterCallback(ClassicFrameMixin.Event.ClubSelected, self.clubSelectedCallback);
	end
end

function ClassicListDropDownMenuMixin:OnHide()
	local parent = self:GetParent();
	if parent.RegisterCallback then
		parent:UnregisterCallback(ClassicFrameMixin.Event.ClubSelected, self.clubSelectedCallback);
	end
end

function ClassicListDropDownMenuMixin:OnClubSelected()
	local parent = self:GetParent();
	local clubId = parent:GetSelectedClubId();
	L_UIDropDownMenu_SetSelectedValue(self, clubId);

	local clubInfo = C_Club.GetClubInfo(clubId);
	L_UIDropDownMenu_SetText(self, clubInfo and clubInfo.name or "");

	self:UpdateUnreadNotification();
end

function ClassicListDropDownMenuMixin:UpdateUnreadNotification()
	local parent = self:GetParent();
	if parent.RegisterCallback then
		local clubId = parent:GetSelectedClubId();
		self.NotificationOverlay:SetShown(CommunitiesUtil.DoesOtherCommunityHaveUnreadMessages(clubId));
	else
		-- If our parent is not the communities frame we don't show unread notifications.
		self.NotificationOverlay:SetShown(false);
	end

end

function ClassicListDropDownMenu_Initialize(self)
	local clubs = C_Club.GetSubscribedClubs();
	if clubs ~= nil then
		CommunitiesUtil.SortClubs(clubs);
		local info = L_UIDropDownMenu_CreateInfo();
		local parent = self:GetParent();
		for i, clubInfo in ipairs(clubs) do
			info.text = clubInfo.name;
			if CommunitiesUtil.DoesCommunityHaveUnreadMessages(clubInfo.clubId) then
				info.text = info.text.." "..CreateAtlasMarkup("communities-icon-notification", 11, 11);
			end

			info.value = clubInfo.clubId;
			info.func = function(button)
				parent:SelectClub(button.value);
			end
			L_UIDropDownMenu_AddButton(info);
		end

		local clubId = parent:GetSelectedClubId();
		if clubId then
			L_UIDropDownMenu_SetSelectedValue(self, clubId);

			local clubInfo = C_Club.GetClubInfo(clubId);
			L_UIDropDownMenu_SetText(self, clubInfo and clubInfo.name or "");
		end
	end
end
