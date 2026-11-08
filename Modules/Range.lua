-- Range indicator for hostile targets. Uses spell range checks directly (no action bar slots needed).
local _, ns = ...
local L = ns.L
local S = ns.SPELL

local M = ns.RegisterModule("Range", {})
local frame, text
local elapsed = 0

local COLORS = {
	melee = { 0.1, 0.8, 0.1 },
	dead = { 1, 0.5, 0 },
	scare = { 0.1, 0.9, 0.4 },
	scatter = { 0, 0.8, 0.8 },
	short = { 0.2, 0.7, 0.9 },
	long = { 0.1, 0.5, 1 },
	mark = { 0.9, 0.2, 0.2 },
	far = { 0.8, 0.1, 0.1 },
}

-- CheckInteractDistance index 4 = ~28 yards. It may be blocked on hostile units in combat; nil then.
local function Within28()
	if not CheckInteractDistance then return nil end
	local ok, r = pcall(CheckInteractDistance, "target", 4)
	if not ok or ns.IsSecret(r) then return nil end
	return r and true or false
end

local function Classify()
	local melee = ns.InRange(S.WING_CLIP) or ns.InRange(S.RAPTOR_STRIKE)
	if melee then return "melee", L["Melee Range"] end
	local ranged = ns.InRange(S.AUTO_SHOT)
	if ranged == nil then ranged = ns.InRange(S.ARCANE_SHOT) end
	if ranged then
		local ctype = UnitCreatureType("target")
		if ctype == L["Beast"] and ns.InRange(S.SCARE_BEAST) then return "scare", L["Scare Beast"] end
		if ns.InRange(S.SCATTER_SHOT) then return "scatter", L["Scatter Shot"] end
		if Within28() then return "short", L["Short Range"] end
		return "long", L["Long Range"]
	end
	if Within28() then return "dead", L["Dead Zone"] end
	if ns.InRange(S.HUNTERS_MARK) then return "mark", L["Hunter's Mark"] end
	return "far", L["Out of Range"]
end

local function HasTarget()
	return UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
end

local function OnUpdate(_, dt)
	elapsed = elapsed + dt
	if elapsed < 0.1 then return end
	elapsed = 0
	if not HasTarget() then
		frame:SetAlpha(ns.db.locked and 0 or 1)
		text:SetText(L["Range"])
		return
	end
	local key, label = Classify()
	local c = COLORS[key]
	frame:SetBackdropColor(c[1], c[2], c[3], 0.75)
	text:SetText(label)
	frame:SetAlpha(1)
end

function M:Init()
	frame = CreateFrame("Frame", "ForeverQuiverRange", UIParent, "BackdropTemplate")
	ns.Backdrop(frame, 0.75)
	text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("CENTER")
	text:SetTextColor(1, 1, 1)
	ns.MakeMovable(frame, "range", L["Range"], { "CENTER", "CENTER", 0, -200 })
	self:Refresh()
end

function M:Refresh()
	if not frame then return end
	local db = ns.db.range
	frame:SetSize(db.width, db.height)
	if db.enabled and ns.IsHunter() then
		frame:SetScript("OnUpdate", OnUpdate)
		frame:Show()
	else
		frame:SetScript("OnUpdate", nil)
		frame:Hide()
	end
end
