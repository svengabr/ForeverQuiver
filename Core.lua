-- Forever Quiver: hunter utilities for WoW: Forever.
-- Core: saved variables, module registry, spell helpers and the movable-frame helper every module uses.
local ADDON, ns = ...
local L = ns.L

ForeverQuiver = ns -- exposed for macros and other addons

ns.SPELL = {
	AUTO_SHOT = 75,
	AIMED_SHOT = 19434,
	MULTI_SHOT = 2643,
	STEADY_SHOT = 34120,
	ARCANE_SHOT = 3044,
	WING_CLIP = 2974,
	RAPTOR_STRIKE = 2973,
	SCARE_BEAST = 1513,
	SCATTER_SHOT = 19503,
	HUNTERS_MARK = 1130,
	TRANQ_SHOT = 19801,
	TRUESHOT_AURA = 19506,
	-- aspects
	ASPECT_HAWK = 13165,
	ASPECT_MONKEY = 13163,
	ASPECT_CHEETAH = 5118,
	ASPECT_PACK = 13159,
	ASPECT_BEAST = 13161,
	ASPECT_WILD = 20043,
	ASPECT_VIPER = 34074,
}

ns.defaults = {
	locked = true,
	frames = {},
	autoShot = { enabled = true, width = 160, height = 8, showText = false, direction = "LEFT",
		colorShoot = { 1, 0.85, 0.1 }, colorReload = { 1, 0.15, 0.15 } },
	castbar = { enabled = true, width = 160, height = 14, onlyShots = true, color = { 0.55, 0.6, 1 } },
	range = { enabled = true, width = 150, height = 24,
		colorMelee = { 0.1, 0.8, 0.1 }, colorDead = { 1, 0.5, 0 }, colorScare = { 0.1, 0.9, 0.4 },
		colorScatter = { 0, 0.8, 0.8 }, colorShort = { 0.2, 0.7, 0.9 }, colorLong = { 0.1, 0.5, 1 },
		colorMark = { 0.9, 0.2, 0.2 }, colorFar = { 0.8, 0.1, 0.1 } },
	aspect = { enabled = true, size = 36, hideAspect = "HAWK" },
	trueshot = { enabled = true, size = 36, threshold = 60 },
	tranq = { enabled = true, channel = "GROUP", showBars = true,
		msgCast = L["Casting Tranq Shot"], msgMiss = L["*** MISSED Tranq Shot ***"] },
	ammo = { enabled = true, threshold = 200, sound = true },
	flyout = { enabled = true, showAnchors = true, size = 32, direction = "UP",
		traps = true, pet = true, aspects = true },
	beast = { enabled = true, onlyUnknown = false, allClasses = false },
	nav = { enabled = true, arrow = true, native = true },
}

-------------------------------------------------------------------------------
-- Utilities
-------------------------------------------------------------------------------

local issecretvalue = issecretvalue or function() return false end
ns.IsSecret = issecretvalue

-- The value, or nil if the client hands it out as a secret (comparing or doing maths on a secret errors).
function ns.Plain(v)
	if issecretvalue(v) then return nil end
	return v
end

function ns.Print(...)
	print("|cffabd473Forever Quiver|r:", ...)
end

local function MergeDefaults(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} end
			MergeDefaults(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

function ns.SpellName(id)
	if C_Spell and C_Spell.GetSpellName then
		return C_Spell.GetSpellName(id)
	elseif GetSpellInfo then
		return (GetSpellInfo(id))
	end
end

function ns.SpellIcon(id)
	if C_Spell and C_Spell.GetSpellTexture then
		return C_Spell.GetSpellTexture(id)
	elseif GetSpellTexture then
		return GetSpellTexture(id)
	end
end

local function IsKnownID(id)
	if not id then return false end
	if IsPlayerSpell and IsPlayerSpell(id) then return true end
	if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(id) then return true end
	if IsSpellKnown and IsSpellKnown(id) then return true end
	return false
end
ns.IsKnownID = IsKnownID

-- True if the player knows any rank of the spell. Ranked spells resolve through the localized name,
-- which the client maps to the highest rank in the spellbook.
function ns.KnowsSpell(id)
	if IsKnownID(id) then return true end
	local name = ns.SpellName(id)
	if not name then return false end
	local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(name)
	return info and IsKnownID(info.spellID) or false
end

-- true / false, or nil when the check is not possible (spell unknown, no target, secret value)
function ns.InRange(id, unit)
	local name = ns.SpellName(id)
	if not name or not ns.KnowsSpell(id) then return nil end
	local r
	if C_Spell and C_Spell.IsSpellInRange then
		r = C_Spell.IsSpellInRange(name, unit or "target")
	elseif IsSpellInRange then
		r = IsSpellInRange(name, unit or "target")
		if r ~= nil then r = (r == 1) end
	end
	if issecretvalue(r) then return nil end
	return r
end

-- Iterates the player's helpful auras; callback(aura) returns true to stop.
function ns.ForEachPlayerBuff(callback)
	if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
	for i = 1, 255 do
		local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
		if not aura then return end
		if not issecretvalue(aura.name) and callback(aura) then return end
	end
end

function ns.FindPlayerBuffByName(name)
	if not name then return nil end
	local found
	ns.ForEachPlayerBuff(function(aura)
		if aura.name == name then found = aura return true end
	end)
	return found
end

-- "First Surname": Forever's characters have a surname, which UnitName returns second while regional unique
-- names are on (same rule as KeepOrSell). nil for a secret or missing name.
function ns.FullName(unit)
	local name, surname = UnitName(unit)
	if not name or issecretvalue(name) then return nil end
	if surname and not issecretvalue(surname) and surname ~= ""
		and RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() then
		local separators = Constants and Constants.CharacterNameSeparatorConsts
		name = name .. (separators and separators.CHARACTERNAME_SURNAME_SEPARATOR or " ") .. surname
	end
	return name
end

function ns.IsHunter()
	return select(2, UnitClass("player")) == "HUNTER"
end

function ns.Backdrop(f, alpha)
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	f:SetBackdropColor(0, 0, 0, alpha or 0.7)
	f:SetBackdropBorderColor(0, 0, 0, 1)
end

-------------------------------------------------------------------------------
-- Movable frames
-------------------------------------------------------------------------------

ns.movers = {}

-- Registers a frame whose position is saved under db.frames[key]. While unlocked an overlay with the
-- label shows, and the frame can be dragged. `point` is the default { point, relPoint, x, y } on UIParent.
function ns.MakeMovable(frame, key, label, point)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	local overlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(frame:GetFrameLevel() + 20)
	overlay:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
	overlay:SetBackdropColor(0.67, 0.83, 0.45, 0.35)
	overlay:SetBackdropBorderColor(0.67, 0.83, 0.45, 1)
	local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER")
	text:SetText(label)
	overlay:EnableMouse(true)
	overlay:RegisterForDrag("LeftButton")
	overlay:SetScript("OnDragStart", function()
		if InCombatLockdown() and frame:IsProtected() then return end
		frame:StartMoving()
	end)
	overlay:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		local p, _, rp, x, y = frame:GetPoint(1)
		ns.db.frames[key] = { p, rp, x, y }
	end)
	overlay:Hide()
	frame.fqOverlay = overlay
	frame.fqKey = key
	frame.fqDefault = point
	ns.movers[key] = frame
	ns.RestorePosition(frame)
end

function ns.RestorePosition(frame)
	if InCombatLockdown() and frame:IsProtected() then return end
	local pos = ns.db.frames[frame.fqKey] or frame.fqDefault
	frame:ClearAllPoints()
	frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

function ns.SetLocked(locked)
	ns.db.locked = locked and true or false
	for _, frame in pairs(ns.movers) do
		frame.fqOverlay:SetShown(not ns.db.locked)
	end
	ns.RefreshAll()
end

function ns.ResetPositions()
	wipe(ns.db.frames)
	for _, frame in pairs(ns.movers) do ns.RestorePosition(frame) end
end

-------------------------------------------------------------------------------
-- Modules
-------------------------------------------------------------------------------

ns.modules = {}

function ns.RegisterModule(name, module)
	module.name = name
	ns.modules[#ns.modules + 1] = module
	return module
end

function ns.RefreshAll()
	for _, m in ipairs(ns.modules) do
		if m.Refresh then
			local ok, err = pcall(m.Refresh, m)
			if not ok then geterrorhandler()(err) end
		end
	end
end

-- Simulation: every display module shows made-up data so it can be looked at and styled without a fight.
-- Not saved; entering combat ends it.
ns.demo = false

function ns.SetDemo(on)
	ns.demo = on and true or false
	ns.RefreshAll()
end

local demoWatch = CreateFrame("Frame")
demoWatch:RegisterEvent("PLAYER_REGEN_DISABLED")
demoWatch:SetScript("OnEvent", function()
	if ns.demo then
		ns.SetDemo(false)
		ns.Print(L["Simulation ended (combat)."])
	end
end)

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON then
		ForeverQuiverDB = ForeverQuiverDB or {}
		local t = ForeverQuiverDB.tranq
		if t and t.announce ~= nil and t.channel == nil then -- 0.1.0 had an on/off switch
			t.channel = t.announce and "GROUP" or "NONE"
			t.announce = nil
		end
		MergeDefaults(ForeverQuiverDB, ns.defaults)
		ns.db = ForeverQuiverDB
	elseif event == "PLAYER_LOGIN" then
		for _, m in ipairs(ns.modules) do
			if m.Init then
				local ok, err = pcall(m.Init, m)
				if not ok then geterrorhandler()(err) end
			end
		end
		ns.SetLocked(ns.db.locked)
	end
end)

-------------------------------------------------------------------------------
-- Slash commands
-------------------------------------------------------------------------------

SLASH_FOREVERQUIVER1 = "/fq"
SLASH_FOREVERQUIVER2 = "/fquiver"
SLASH_FOREVERQUIVER3 = "/foreverquiver"
SLASH_FOREVERQUIVER4 = "/qq" -- Quiver's own command, for players coming from Turtle WoW
SLASH_FOREVERQUIVER5 = "/quiver"
SlashCmdList.FOREVERQUIVER = function(msg)
	local cmd, rest = strtrim(msg or ""):match("^(%S*)%s*(.-)$")
	cmd = cmd:lower()
	if cmd == "lock" or cmd == "unlock" then
		ns.SetLocked(cmd == "lock")
		ns.Print(ns.db.locked and L["Frames locked."] or L["Frames unlocked. Drag them, then /fq lock."])
	elseif cmd == "reset" then
		ns.ResetPositions()
		ns.Print(L["Positions reset."])
	elseif cmd == "demo" or cmd == "test" then
		ns.SetDemo(not ns.demo)
	elseif cmd == "debug" and ns.DebugRange then
		ns.DebugRange()
	elseif cmd == "way" and ns.Nav then
		ns.Nav:SlashWay(rest)
	elseif cmd == "clear" and ns.Nav then
		ns.Nav:Clear()
	else
		if ns.OpenOptions then ns.OpenOptions() end
	end
end
