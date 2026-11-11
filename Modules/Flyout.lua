-- Spell menus: one key (or a click on the anchor button) opens a row of secure spell buttons, e.g. all traps.
-- While a menu is open, keys 1-9 cast its entries; casting closes the menu. Everything that changes the
-- secure frames runs out of combat only; changes made in combat are applied on PLAYER_REGEN_ENABLED.
-- Action bars: addons can't add real flyouts, so each menu has a macro ("FQ Traps" ...) that /clicks its toggle.
-- The Blizzard action buttons holding such a macro are handed to the toggle as frame refs, and the menu pops up
-- at the one under the mouse (or the first one when opened by key).
local _, ns = ...
local L = ns.L

local GROUPS = {
	{ key = "Traps", opt = "traps", label = L["Traps"], binding = L["Open trap menu"],
		spells = { 1499, 13809, 13795, 13813 } }, -- Freezing, Frost, Immolation, Explosive
	{ key = "Pet", opt = "pet", label = L["Pet"], binding = L["Open pet menu"],
		spells = { 883, 2641, 982, 136, 6991, 1515, 1462, 1002 } }, -- Call, Dismiss, Revive, Mend, Feed, Tame, Beast Lore, Eyes
	{ key = "Aspects", opt = "aspects", label = L["Aspects"], binding = L["Open aspect menu"],
		spells = { 13165, 13163, 5118, 13159, 13161, 20043 } }, -- Hawk, Monkey, Cheetah, Pack, Beast, Wild
}

BINDING_HEADER_FOREVERQUIVER = "Forever Quiver"
for _, g in ipairs(GROUPS) do
	_G["BINDING_NAME_CLICK ForeverQuiver" .. g.key .. "Toggle:LeftButton"] = g.binding
end

local M = ns.RegisterModule("Flyout", {})
local pending = false

local function ClickType()
	return GetCVarBool("ActionButtonUseKeyDown") and "AnyDown" or "AnyUp"
end

local SNIPPET_TOGGLE = [[
	local f = self:GetFrameRef("flyout")
	if f:IsShown() then
		f:Hide()
		return
	end
	local count = f:GetAttribute("count") or 0
	if count == 0 then return end
	-- only one menu at a time: close the others first, so the 1-9 keys belong to this one
	for i = 1, 2 do
		local other = self:GetFrameRef("other" .. i)
		if other then other:Hide() end
	end
	-- pop up at the action bar slot holding this menu's macro: the one under the mouse, else the first shown;
	-- each slot brings its direction (away from the screen edge, along the bar's free side)
	local target, dir
	local n = self:GetAttribute("slots") or 0
	for i = 1, n do
		local b = self:GetFrameRef("slot" .. i)
		if b and b:IsVisible() and b:IsUnderMouse() then
			target, dir = b, self:GetAttribute("slotdir" .. i)
			break
		end
	end
	if not target then
		for i = 1, n do
			local b = self:GetFrameRef("slot" .. i)
			if b and b:IsVisible() then
				target, dir = b, self:GetAttribute("slotdir" .. i)
				break
			end
		end
	end
	target = target or self
	dir = dir or self:GetAttribute("dir") or "UP"
	local size = self:GetAttribute("size") or 32
	local step = size + 2
	local length = count * step - 2
	f:ClearAllPoints()
	if dir == "UP" or dir == "DOWN" then
		f:SetWidth(size)
		f:SetHeight(length)
	else
		f:SetWidth(length)
		f:SetHeight(size)
	end
	if dir == "UP" then
		f:SetPoint("BOTTOM", target, "TOP", 0, 2)
	elseif dir == "DOWN" then
		f:SetPoint("TOP", target, "BOTTOM", 0, -2)
	elseif dir == "LEFT" then
		f:SetPoint("RIGHT", target, "LEFT", -2, 0)
	else
		f:SetPoint("LEFT", target, "RIGHT", 2, 0)
	end
	for i = 1, count do
		local b = self:GetFrameRef("btn" .. i)
		if b then
			b:ClearAllPoints()
			if dir == "UP" then
				b:SetPoint("BOTTOM", f, "BOTTOM", 0, (i - 1) * step)
			elseif dir == "DOWN" then
				b:SetPoint("TOP", f, "TOP", 0, -(i - 1) * step)
			elseif dir == "LEFT" then
				b:SetPoint("RIGHT", f, "RIGHT", -(i - 1) * step, 0)
			else
				b:SetPoint("LEFT", f, "LEFT", (i - 1) * step, 0)
			end
		end
	end
	f:Show()
]]

local SNIPPET_SHOW = [[
	local n = self:GetAttribute("count") or 0
	local prefix = self:GetAttribute("prefix")
	for i = 1, n do
		if i <= 9 then
			self:SetBindingClick(true, tostring(i), prefix .. i, "LeftButton")
		end
	end
]]

local SNIPPET_HIDE = [[
	self:ClearBindings()
]]

local function UpdateCooldowns(g)
	for _, b in ipairs(g.buttons) do
		if b:IsShown() and b.known and b.spellName then
			local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(b.spellName)
			if info and ns.Plain(info.startTime) and ns.Plain(info.duration) then
				b.cd:SetCooldown(info.startTime, info.duration)
			end
		end
	end
end

local function CreateGroup(g, index)
	local size = ns.db.flyout.size
	-- no BackdropTemplate here: its OnLoad would replace SecureHandler_OnLoad
	local toggle = CreateFrame("Button", "ForeverQuiver" .. g.key .. "Toggle", UIParent, "SecureHandlerClickTemplate")
	toggle:SetSize(size, size)
	toggle.border = toggle:CreateTexture(nil, "BACKGROUND")
	toggle.border:SetAllPoints()
	toggle.border:SetColorTexture(0.67, 0.83, 0.45, 1)
	toggle.icon = toggle:CreateTexture(nil, "ARTWORK")
	toggle.icon:SetPoint("TOPLEFT", 1, -1)
	toggle.icon:SetPoint("BOTTOMRIGHT", -1, 1)
	toggle.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	toggle:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	toggle:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(g.label)
		local key = GetBindingKey("CLICK " .. self:GetName() .. ":LeftButton")
		if key then GameTooltip:AddLine(GetBindingText(key), 1, 1, 1) end
		GameTooltip:AddLine(L["Drag onto an action bar to use the menu from there."], 0.7, 0.7, 0.7, true)
		GameTooltip:Show()
	end)
	toggle:SetScript("OnLeave", GameTooltip_Hide)
	-- drag the button (frames locked) to put the menu's macro on an action bar
	toggle:RegisterForDrag("LeftButton")
	toggle:SetScript("OnDragStart", function()
		if ns.db.locked then ns.PickupMenuMacro(g.key) end
	end)

	local flyout = CreateFrame("Frame", "ForeverQuiver" .. g.key .. "Flyout", UIParent, "SecureHandlerShowHideTemplate")
	flyout:SetFrameStrata("DIALOG")
	flyout:SetAttribute("prefix", "ForeverQuiver" .. g.key .. "Button")
	flyout:SetAttribute("count", 0)
	flyout:SetAttribute("_onshow", SNIPPET_SHOW)
	flyout:SetAttribute("_onhide", SNIPPET_HIDE)
	flyout:Hide()

	SecureHandlerSetFrameRef(toggle, "flyout", flyout)
	toggle:SetAttribute("_onclick", SNIPPET_TOGGLE)
	-- feedback when the key does nothing because no spell of the menu is known yet
	toggle:HookScript("OnClick", function()
		if (g.known or 0) == 0 then
			ns.Print(string.format(L["%s: you don't know any of these spells yet."], g.label))
		end
	end)

	g.toggle, g.flyout, g.buttons = toggle, flyout, {}
	ns.MakeMovable(toggle, "flyout" .. g.key, g.label:sub(1, 3), { "CENTER", "CENTER", -340 + index * 40, -250 })

	flyout:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	flyout:SetScript("OnEvent", function() UpdateCooldowns(g) end)
	flyout:HookScript("OnShow", function() UpdateCooldowns(g) end)
end

local function GetButton(g, i)
	local b = g.buttons[i]
	if b then return b end
	b = CreateFrame("Button", "ForeverQuiver" .. g.key .. "Button" .. i, g.flyout, "SecureActionButtonTemplate")
	b:SetAttribute("type", "spell")
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints()
	b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
	b.cd:SetAllPoints()
	b.hotkey = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
	b.hotkey:SetPoint("TOPRIGHT", -2, -2)
	b.hotkey:SetText(i <= 9 and tostring(i) or "")
	b:SetScript("OnEnter", function(self)
		if not self.spellName then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(self.spellName)
		if info and info.spellID then GameTooltip:SetSpellByID(info.spellID) else GameTooltip:SetText(self.spellName) end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	-- close the menu after a cast
	SecureHandlerWrapScript(b, "OnClick", g.flyout, [[ return button, "close" ]], [[ owner:Hide() ]])
	SecureHandlerSetFrameRef(g.toggle, "btn" .. i, b)
	g.buttons[i] = b
	return b
end

-- The on-screen menu button. It must stay shown for its key binding to keep working, so "hidden" only means
-- invisible. It hides itself while the menu's macro sits on an action bar (no need for both), except when the
-- frames are unlocked for moving. Out of combat only (protected frame).
function M.ApplyAnchor(g)
	if InCombatLockdown() then return end
	local db = ns.db.flyout
	local onBar = (g.toggle:GetAttribute("slots") or 0) > 0
	local visible = g.enabled and (g.count or 0) > 0
		and (not ns.db.locked or (db.showAnchors and not onBar))
	g.toggle:SetAlpha(visible and 1 or 0)
	g.toggle:EnableMouse(visible and true or false)
end

local function Build(g)
	local db = ns.db.flyout
	local size = db.size
	local enabled = db.enabled and db[g.opt] and ns.IsHunter()
	local clicks = ClickType()

	g.toggle:SetSize(size, size)
	g.toggle:RegisterForClicks(clicks)
	g.flyout:Hide()

	-- Spells not learned yet stay in the menu, greyed out and without a cast action, so the menu has its final
	-- layout from level 1; they light up on SPELLS_CHANGED once learned.
	local n, known = 0, 0
	if enabled then
		for _, id in ipairs(g.spells) do
			local name = ns.SpellName(id)
			if name then
				local isKnown = ns.KnowsSpell(id)
				n = n + 1
				if isKnown then known = known + 1 end
				local b = GetButton(g, n)
				b.spellName = name
				b:SetAttribute("type", isKnown and "spell" or nil)
				b:SetAttribute("spell", isKnown and name or nil)
				b:RegisterForClicks(clicks)
				b.icon:SetTexture(ns.SpellIcon(id))
				b.icon:SetDesaturated(not isKnown)
				b.icon:SetVertexColor(isKnown and 1 or 0.6, isKnown and 1 or 0.6, isKnown and 1 or 0.6)
				b.hotkey:SetShown(isKnown)
				b.known = isKnown
				b:SetSize(size, size)
				b:ClearAllPoints()
				-- laid out inside the flyout, which the toggle snippet anchors where it should pop up
				if db.direction == "UP" then
					b:SetPoint("BOTTOM", g.flyout, "BOTTOM", 0, (n - 1) * (size + 2))
				else
					b:SetPoint("LEFT", g.flyout, "LEFT", (n - 1) * (size + 2), 0)
				end
				b:Show()
			end
		end
	end
	for i = n + 1, #g.buttons do
		g.buttons[i].spellName = nil
		g.buttons[i]:Hide()
	end
	g.flyout:SetAttribute("count", n)
	local length = math.max(1, n * (size + 2) - 2)
	if db.direction == "UP" then g.flyout:SetSize(size, length) else g.flyout:SetSize(length, size) end
	g.flyout:ClearAllPoints()
	g.flyout:SetPoint("BOTTOM", g.toggle, "TOP", 0, 2)
	g.toggle:SetAttribute("dir", db.direction == "UP" and "UP" or "RIGHT")
	g.toggle:SetAttribute("size", size)
	g.known = known
	g.toggle.icon:SetTexture(n > 0 and g.buttons[1].icon:GetTexture() or "Interface\\Icons\\INV_Misc_QuestionMark")
	for i = 1, n do
		if g.buttons[i].known then
			g.toggle.icon:SetTexture(g.buttons[i].icon:GetTexture())
			break
		end
	end
	g.toggle.icon:SetDesaturated(known == 0)
	M.UpdateMacroIcon(g)

	g.enabled, g.count = enabled, n
	g.toggle:SetShown(enabled)
	M.ApplyAnchor(g)
end

-------------------------------------------------------------------------------
-- Action bar macros
-------------------------------------------------------------------------------

local QUESTION_MARK = 134400
local BAR_BUTTONS = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton",
	"MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button" }
local slotsPending = false

local function MacroName(g) return "FQ " .. g.key end
local function MacroBody(g) return "/click " .. g.toggle:GetName() .. " LeftButton 1" end
local function MacroIcon(g) return g.toggle.icon:GetTexture() or QUESTION_MARK end

local function FindGroup(key)
	for _, g in ipairs(GROUPS) do
		if g.key == key then return g end
	end
end

-- the icon a menu shows (its first known spell), for the options window
function ns.MenuIcon(key)
	local g = FindGroup(key)
	return g and g.toggle and MacroIcon(g) or QUESTION_MARK
end

-- Creates (or refreshes) the menu's account macro and puts it on the cursor, ready to drop on an action bar
function ns.PickupMenuMacro(key)
	local g = FindGroup(key)
	if not g then return end
	if InCombatLockdown() then
		ns.Print(L["Not in combat."])
		return
	end
	local name, body, icon = MacroName(g), MacroBody(g), MacroIcon(g)
	local index = GetMacroIndexByName(name)
	if index == 0 then
		local numAccount = GetNumMacros()
		if numAccount >= (MAX_ACCOUNT_MACROS or 120) then
			ns.Print(L["No room for another general macro."])
			return
		end
		index = CreateMacro(name, icon, body, nil)
	else
		EditMacro(index, name, icon, body)
	end
	if index and index > 0 then PickupMacro(index) end
end

-- keeps the macro icon on the menu's first known spell
function M.UpdateMacroIcon(g)
	if InCombatLockdown() then return end
	local index = GetMacroIndexByName(MacroName(g))
	if index == 0 then return end
	local _, icon, body = GetMacroInfo(index)
	if icon ~= MacroIcon(g) or body ~= MacroBody(g) then
		EditMacro(index, MacroName(g), MacroIcon(g), MacroBody(g))
	end
end

-- Which way a menu opens from an action button: vertical bars open away from their screen edge (right half ->
-- left), horizontal bars towards the screen middle (bottom half -> up). Same idea as Blizzard's own flyouts.
local DIRECTIONS = { UP = true, DOWN = true, LEFT = true, RIGHT = true }

local function SlotDirection(btn)
	-- Blizzard's bars know the direction their own spell flyouts open in; use that first
	local bar = btn.bar
	if bar and bar.GetSpellFlyoutDirection then
		local ok, dir = pcall(bar.GetSpellFlyoutDirection, bar)
		if ok and DIRECTIONS[dir] then return dir end
	end
	bar = btn:GetParent()
	local x, y = btn:GetCenter()
	if not (x and y) then return "UP" end
	local scale = btn:GetEffectiveScale() / UIParent:GetEffectiveScale()
	x, y = x * scale, y * scale
	local w, h = UIParent:GetSize()
	local vertical = bar and bar.GetHeight and bar:GetHeight() > bar:GetWidth() * 1.5
	if vertical then
		return x > w / 2 and "LEFT" or "RIGHT"
	end
	return y > h / 2 and "DOWN" or "UP"
end

-- Hands each toggle the Blizzard action buttons that hold its macro (secure frame refs, so out of combat only)
local function ScanSlots()
	if InCombatLockdown() then
		slotsPending = true
		return
	end
	slotsPending = false
	local found = {}
	for _, g in ipairs(GROUPS) do found[g] = {} end
	for _, prefix in ipairs(BAR_BUTTONS) do
		for i = 1, 12 do
			local btn = _G[prefix .. i]
			local slot = btn and (btn.action or btn:GetAttribute("action"))
			if type(slot) == "number" and HasAction(slot) then
				local kind, id = GetActionInfo(slot)
				local body = kind == "macro" and id and GetMacroBody(id)
				if body then
					for _, g in ipairs(GROUPS) do
						if body:find(g.toggle:GetName(), 1, true) then
							table.insert(found[g], btn)
						end
					end
				end
			end
		end
	end
	for g, list in pairs(found) do
		for i, btn in ipairs(list) do
			SecureHandlerSetFrameRef(g.toggle, "slot" .. i, btn)
			g.toggle:SetAttribute("slotdir" .. i, SlotDirection(btn))
		end
		g.toggle:SetAttribute("slots", #list)
		M.ApplyAnchor(g)
	end
end

-- part of /fq debug: which action buttons hold a menu macro and which way the menu opens there
function ns.DebugMenus()
	for _, g in ipairs(GROUPS) do
		local n = g.toggle and g.toggle:GetAttribute("slots") or 0
		local parts = {}
		for i = 1, n do
			parts[#parts + 1] = tostring(g.toggle:GetAttribute("slotdir" .. i))
		end
		ns.Print(string.format("menu %s: %d slot(s) %s, button dir %s", g.key, n, table.concat(parts, ","),
			tostring(g.toggle and g.toggle:GetAttribute("dir"))))
	end
end

local scanQueued = false
local function QueueScan()
	if scanQueued then return end
	scanQueued = true
	C_Timer.After(0.2, function()
		scanQueued = false
		ScanSlots()
	end)
end

function M:Rebuild()
	if InCombatLockdown() then
		pending = true
		return
	end
	pending = false
	for _, g in ipairs(GROUPS) do Build(g) end
end

function M:Init()
	for i, g in ipairs(GROUPS) do CreateGroup(g, i) end
	for _, g in ipairs(GROUPS) do
		local n = 0
		for _, other in ipairs(GROUPS) do
			if other ~= g then
				n = n + 1
				SecureHandlerSetFrameRef(g.toggle, "other" .. n, other.flyout)
			end
		end
	end
	local ev = CreateFrame("Frame")
	ev:RegisterEvent("SPELLS_CHANGED")
	ev:RegisterEvent("PLAYER_REGEN_ENABLED")
	ev:RegisterEvent("CVAR_UPDATE")
	ev:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_REGEN_ENABLED" then
			if slotsPending then QueueScan() end
			if not pending then return end
		end
		M:Rebuild()
	end)
	local bars = CreateFrame("Frame")
	for _, event in ipairs({ "ACTIONBAR_SLOT_CHANGED", "UPDATE_MACROS", "ACTIONBAR_PAGE_CHANGED",
		"UPDATE_BONUS_ACTIONBAR", "PLAYER_ENTERING_WORLD", "EDIT_MODE_LAYOUTS_UPDATED" }) do
		bars:RegisterEvent(event)
	end
	bars:SetScript("OnEvent", QueueScan)
	self:Rebuild()
end

function M:Refresh()
	if GROUPS[1].toggle then self:Rebuild() end
end
