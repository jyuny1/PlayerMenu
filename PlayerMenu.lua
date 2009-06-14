--[[ $Id: PlayerMenu.lua 70828 2008-04-22 03:41:29Z hshh $ ]]--
PlayerMenu = LibStub("AceAddon-3.0"):NewAddon("PlayerMenu", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("PlayerMenu")

--save blizzard origin variables
local menus = {"FRIEND", "PLAYER", "PARTY", "RAID_PLAYER"}
local menus_new_items = {"GUILD_INVITE", "ADD_FRIEND", "GET_NAME", "WHO", "EXTMENU"}
local PM_BLZ_ORIGIN = {}
local m,k,v
local _G = getfenv(0)
for _,m in ipairs(menus) do
	PM_BLZ_ORIGIN[m]={}
	for k,v in pairs(_G.UnitPopupMenus[m]) do
		PM_BLZ_ORIGIN[m][k]=v
	end
end

local ExtMaxButton = 20


--db get/set function
local function get(info)
    local k = info[#info]
	return PlayerMenu.db.profile[k]
end
local function set(info,value)
    local k = info[#info]
    PlayerMenu.db.profile[k] = value
end

function PlayerMenu:OnInitialize()
	local defaults = {
		profile = {
			leftButton = false,
			useFocus = false,
			extAutoHide = 3,
			clearTargetAfterCast = true,
		}
	}
	self.db = LibStub("AceDB-3.0"):New("PlayerMenu_Settings", defaults, "Default")

	local options = {
		type = "group",
		get = get,
		set = set,
		args = {
			leftButton = {
				order = 100,
				type = "toggle",
				name = L["Left Button Menu"],
				desc = L["Mouse left click to show menu"],
			},
			useFocus = {
				order = 200,
				type = "toggle",
				name = L["Use Focus to Cast"],
				desc = L["Use focus feature to cast spell instead of using target."],
			},
			extAutoHide = {
				order = 300,
				type = "range",
				name = L["Extend Menu Hide Delay"],
				desc = L["Set extend menu auto hide delay time."],
				min = 1,
				max = 20,
				step = 1,
			},
			clearTargetAfterCast = {
				order = 400,
				type = "toggle",
				name = L["Clear Target After Cast"],
			},
			resetdb = {
				order = 500,
				type = "execute",
				name = L["Reset"],
				confirm = true,
				confirmText = L["ResetDB_Confirm"],
				func = function()
					self.db:ResetDB()
					self:OnDisable()
					self:OnEnable()
					self:Print(L["All settings are reset to default value."])
				end,
			},
		}
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable("PlayerMenu", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("PlayerMenu", "PlayerMenu")
end

function PlayerMenu:OnEnable()
	self:InitSpell()
	self:RegisterEvent("SPELLS_CHANGED", "InitSpell")
	self:RegisterEvent("LEARNED_SPELL_IN_TAB", "InitSpell")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "ExtMenu_AutoHide") --hide ext menu in battle

	self:SecureHook("UnitPopup_OnClick")
	self:SecureHook("UnitPopup_HideButtons")
	if (self.db.profile.leftButton) then
		self:SecureHook("SetItemRef")
	end

	local v,vv
	for _,v in ipairs(menus_new_items) do
		UnitPopupButtons[v] = { text = L[v], dist = 0 }
		for _,vv in ipairs(menus) do
			tinsert(UnitPopupMenus[vv], getn(UnitPopupMenus[vv])-1, v)
		end
	end
end

function PlayerMenu:OnDisable()
	local v,vv,kkk,vvv
	for _,v in ipairs(menus_new_items) do
		for _,vv in ipairs(menus) do
			UnitPopupMenus[vv]={}
			for kkk,vvv in pairs(PM_BLZ_ORIGIN[vv]) do
				UnitPopupMenus[vv][kkk]=vvv
			end
		end
		UnitPopupButtons[v] = nil
	end
	self:ExtMenu_AutoHide()
end

function PlayerMenu:UnitPopup_HideButtons()
	-- hide ext menu
	self:ExtMenu_AutoHide()

	--local dropdownMenu = getglobal(UIDROPDOWNMENU_INIT_MENU) --fix 3.08 bug by rimu
	local dropdownMenu = UIDROPDOWNMENU_INIT_MENU;
	local diffFactionGroup
	if dropdownMenu.unit and UnitFactionGroup("player") ~= UnitFactionGroup(dropdownMenu.unit) then
		diffFactionGroup = true
	end
	local realm
	if dropdownMenu.unit then
		_,realm = UnitName(dropdownMenu.unit)
	end

	for index, value in ipairs(UnitPopupMenus[dropdownMenu.which]) do
		if value == "GET_NAME" then
			if dropdownMenu.name == UnitName("player") then
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0
			else
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1
			end
		elseif value == "WHO" or value == "ADD_FRIEND" then
			if dropdownMenu.name == UnitName("player") or (realm and realm ~="") or diffFactionGroup then
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0
			else
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1
			end
		elseif value == "GUILD_INVITE" then
			if not CanGuildInvite() or dropdownMenu.name == UnitName("player") or (realm and realm ~="") or diffFactionGroup then
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0
			else
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1
			end
		elseif value == "EXTMENU" then
			UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1
		end
	end
end

function PlayerMenu:UnitPopup_OnClick()
	--local dropdownFrame = getglobal(UIDROPDOWNMENU_INIT_MENU) --fix 3.08 bug by rimu
	local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
	local button = this.value
	local name = dropdownFrame.name

	if (button == "ADD_FRIEND") then
		AddFriend(name)
	elseif (button == "GUILD_INVITE") then
		GuildInvite(name)
	elseif (button == "GET_NAME") then
		ChatFrameEditBox:Show()
		local realm
		if dropdownFrame.unit then
			_,realm = UnitName(dropdownFrame.unit)
		end
		if (realm and realm ~="") then
			ChatFrameEditBox:Insert(name .. " - " .. realm)
		else
			ChatFrameEditBox:Insert(name)
		end
	elseif (button == "WHO") then
		SendWho(name)
	elseif (button == "EXTMENU") then
		self:ExtMenu_InitButton(name)
		self:ExtMenu_Show()
	end
	PlaySound("UChatScrollButton")
end

function PlayerMenu:SetItemRef(link, text, button)
	if ( strsub(link, 1, 6) == "player" ) then
		local namelink = strsub(link, 8);
		local name, lineid = strsplit(":", namelink);
		if ( name and (strlen(name) > 0) ) then
			if ( IsModifiedClick("CHATLINK") ) then
				local staticPopup;
				staticPopup = StaticPopup_Visible("ADD_IGNORE");
				if ( staticPopup ) then
					-- If add ignore dialog is up then enter the name into the editbox
					getglobal(staticPopup.."EditBox"):SetText(name);
					return;
				end
				staticPopup = StaticPopup_Visible("ADD_MUTE");
				if ( staticPopup ) then
					-- If add ignore dialog is up then enter the name into the editbox
					getglobal(staticPopup.."EditBox"):SetText(name);
					return;
				end
				staticPopup = StaticPopup_Visible("ADD_FRIEND");
				if ( staticPopup ) then
					-- If add ignore dialog is up then enter the name into the editbox
					getglobal(staticPopup.."EditBox"):SetText(name);
					return;
				end
				staticPopup = StaticPopup_Visible("ADD_GUILDMEMBER");
				if ( staticPopup ) then
					-- If add ignore dialog is up then enter the name into the editbox
					getglobal(staticPopup.."EditBox"):SetText(name);
					return;
				end
				staticPopup = StaticPopup_Visible("ADD_TEAMMEMBER");
				if ( staticPopup ) then
					-- If add ignore dialog is up then enter the name into the editbox
					getglobal(staticPopup.."EditBox"):SetText(name);
					return;
				end
				staticPopup = StaticPopup_Visible("ADD_RAIDMEMBER");
				if ( staticPopup ) then
					-- If add ignore dialog is up then enter the name into the editbox
					getglobal(staticPopup.."EditBox"):SetText(name);
					return;
				end
				staticPopup = StaticPopup_Visible("CHANNEL_INVITE");
				if ( staticPopup ) then
					getglobal(staticPopup.."EditBox"):SetText(name);
					return;
				end
				if ( ChatFrameEditBox:IsVisible() ) then
					ChatFrameEditBox:Insert(name);
				elseif ( HelpFrameOpenTicketText:IsVisible() ) then
					HelpFrameOpenTicketText:Insert(name);
				else
					SendWho("n-"..name);					
				end
				
			else
				ChatFrameEditBox:Hide()
				FriendsFrame_ShowDropdown(name, 1, lineid);
			end
		end
		return;
	end
end

function PlayerMenu:InitSpell()
	self.SpellCache = {}
	self.SpellCache_Count = 0

	local _, class = UnitClass("player")
	if class == "ROGUE" or class == "WARRIOR" or class == "HUNTER" then return end

	-- check if spell is in spellbook
	local k,v
	local spell = {}
	for k,v in pairs(self.Spell) do
		if GetSpellInfo(k) then
			tinsert(spell, k)
		end
	end

	self.SpellCache = spell
	self.SpellCache_Count = getn(spell)
end

function PlayerMenu:ExtMenu_ButtonOnClick()
	PlayerMenu:ExtMenu_AutoHide()
end

function PlayerMenu:ExtMenu_InitButton(name)
	if not name then
		name = UnitName("player")
	end
	local lastTarget = UnitName("target")

	PMEM_Frame_Button1:SetText(L["Set Target"])
	PMEM_Frame_Button1:SetAttribute("type1", "macro")
	PMEM_Frame_Button1:SetAttribute("macrotext", "/target "..name)
	PMEM_Frame_Button1:Show()
	PMEM_Frame_Button2:SetText(L["Set Focus"])
	PMEM_Frame_Button2:SetAttribute("type1", "macro")
	if lastTarget and lastTarget~=name then
		PMEM_Frame_Button2:SetAttribute("macrotext", "/target "..name.."\n/focus\n/target "..lastTarget)
	else
		PMEM_Frame_Button2:SetAttribute("macrotext", "/target "..name.."\n/focus")
	end
	PMEM_Frame_Button2:Show()
	PMEM_Frame_Button3:SetText(TRADE)
	PMEM_Frame_Button3:SetAttribute("type1", "macro")
	PMEM_Frame_Button3:SetAttribute("macrotext", "/target "..name.."\n/trade")
	PMEM_Frame_Button3:Show()

	local spell_id = 1
	for i=4, self.SpellCache_Count+3 do
		local button = getglobal("PMEM_Frame_Button"..i)
		button:SetText(self.SpellCache[spell_id])
		button:SetAttribute("type1", "macro")
		if self.db.profile.useFocus then
			button:SetAttribute("macrotext", "/focus "..name.."\n/cast [target=focus] "..self.SpellCache[spell_id].."\n/stopcasting\n/clearfocus")
		else
			if lastTarget and self.db.profile.clearTargetAfterCast and not self.SpellIgnoreClearTarget[self.SpellCache[spell_id]] then
				button:SetAttribute("macrotext", "/target "..name.."\n/cast "..self.SpellCache[spell_id].."\n/stopcasting\n/target "..lastTarget)
			else
				button:SetAttribute("macrotext", "/target "..name.."\n/cast "..self.SpellCache[spell_id].."\n/stopcasting\n")
			end
		end
		button:Show()
		spell_id = spell_id + 1
	end

	for i=self.SpellCache_Count+4,ExtMaxButton do
		local button = getglobal("PMEM_Frame_Button"..i)
		button:Hide()
	end

	self.ExtMenuWidth = 0
	for i=1, ExtMaxButton do
		local button = getglobal("PMEM_Frame_Button"..i)
		local width = button:GetTextWidth()
		if width > self.ExtMenuWidth then
			self.ExtMenuWidth = width
		end
	end
	self.ExtMenuWidth = self.ExtMenuWidth + 2*12
	self.ExtMenuHeight = (self.SpellCache_Count + 3 + 2) * 12 -- 3 fix button, top and bottom space
end

function PlayerMenu:ExtMenu_AutoHide()
	if PlayerMenu.Timer_ExtMenu_AutoHide then
		PlayerMenu:CancelTimer(PlayerMenu.Timer_ExtMenu_AutoHide, true)
		PlayerMenu.Timer_ExtMenu_AutoHide = nil
	end
	
	if PMEM_Frame:IsVisible() then
		PMEM_Frame:Hide()
	end
end

function PlayerMenu:ExtMenu_Show()
	self.Timer_ExtMenu_AutoHide = self:ScheduleTimer("ExtMenu_AutoHide", self.db.profile.extAutoHide)

	local point, relativeTo, relativePoint, xOfs, yOfs = this:GetParent():GetPoint()
	PMEM_Frame:SetHeight(self.ExtMenuHeight)
	PMEM_Frame:SetWidth(self.ExtMenuWidth)
	PMEM_Frame:ClearAllPoints()
	PMEM_Frame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
	PMEM_Frame:Show()
end
function PlayerMenu:ExtMenu_OnEnter(button)
	if PlayerMenu.Timer_ExtMenu_AutoHide then
		PlayerMenu:CancelTimer(PlayerMenu.Timer_ExtMenu_AutoHide, true)
		PlayerMenu.Timer_ExtMenu_AutoHide = nil
	end

	if button then
		local spell = this:GetText()
		if spell and spell ~= L["Set Target"] and spell ~= L["Set Focus"] and spell ~= TRADE then
			PMEM_FrameSpellIcon:SetTexture(self.Spell[spell])
			PMEM_FrameSpellIcon:Show()
		end
	end
end
function PlayerMenu:ExtMenu_OnLeave()
	PlayerMenu.Timer_ExtMenu_AutoHide = PlayerMenu:ScheduleTimer("ExtMenu_AutoHide", PlayerMenu.db.profile.extAutoHide)
	
	PMEM_FrameSpellIcon:Hide()
end
