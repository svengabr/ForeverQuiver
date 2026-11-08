-- Range indicator for hostile targets. Uses spell range checks directly (no action bar slots needed).
local _, ns = ...
local L = ns.L
local S = ns.SPELL

local M = ns.RegisterModule("Range", {})
local frame, text
local elapsed = 0

-- classification key -> saved colour option
local COLOR_KEYS = {
	melee = "colorMelee", dead = "colorDead", scare = "colorScare", scatter = "colorScatter",
	short = "colorShort", long = "colorLong", mark = "colorMark", far = "colorFar",
}

-- CheckInteractDistance: index 3 = ~10 yards, index 4 = ~28 yards. It may be blocked on hostile units in
-- combat; nil then.
local function Within(index)
	if not CheckInteractDistance then return nil end
	local ok, r = pcall(CheckInteractDistance, "target", index)
	if not ok or ns.IsSecret(r) then return nil end
	return r and true or false
end
local function Within28() return Within(4) end

-- Distance bracket from LibRangeCheck-3.0 (embedded). It measures with item ranges (e.g. 5 yd items), which work
-- on hostile targets in combat too. Returns minYards, maxYards or nil.
local function Bracket()
	local rc = LibStub and LibStub("LibRangeCheck-3.0", true)
	if not rc then return nil end
	local ok, minR, maxR = pcall(rc.GetRange, rc, "target")
	if not ok then return nil end
	return ns.Plain(minR), ns.Plain(maxR)
end
ns.RangeBracket = Bracket

local function Classify()
	local _, maxR = Bracket()
	-- Melee spells can't be trusted on this client: Raptor Strike answered "in range" at 28+ yd.
	if maxR and maxR <= 5 then return "melee", L["Melee Range"] end
	-- Auto Shot has a minimum range, so "in range" also rules out melee and the dead zone.
	local ranged = ns.InRange(S.AUTO_SHOT)
	if ranged == nil then ranged = ns.InRange(S.ARCANE_SHOT) end
	if not ranged and not maxR then
		-- no distance data: fall back to the spell check, cross-checked with the ~10 yd interact distance
		local melee = (ns.InRange(S.WING_CLIP) or ns.InRange(S.RAPTOR_STRIKE)) and Within(3) ~= false
		if melee then return "melee", L["Melee Range"] end
	end
	if ranged then
		local ctype = ns.Plain(UnitCreatureType("target"))
		if ctype == L["Beast"] and ns.InRange(S.SCARE_BEAST) then return "scare", L["Scare Beast"] end
		if ns.InRange(S.SCATTER_SHOT) then return "scatter", L["Scatter Shot"] end
		local short = maxR and maxR <= 30 or (not maxR and Within28())
		if short then return "short", L["Short Range"] end
		return "long", L["Long Range"]
	end
	if (maxR and maxR <= 15) or (not maxR and Within28()) then return "dead", L["Dead Zone"] end
	if ns.InRange(S.HUNTERS_MARK) then return "mark", L["Hunter's Mark"] end
	return "far", L["Out of Range"]
end

-- /fq debug: prints the raw range answers of the client for the current target
function ns.DebugRange()
	local function show(v)
		if ns.IsSecret(v) then return "<secret>" end
		return tostring(v)
	end
	ns.Print("target:", show(UnitName("target")), "classified as:", select(2, Classify()))
	local minR, maxR = Bracket()
	ns.Print("LibRangeCheck:", show(minR), "-", show(maxR), "yd")
	for _, key in ipairs({ "WING_CLIP", "RAPTOR_STRIKE", "AUTO_SHOT", "ARCANE_SHOT", "SCARE_BEAST",
		"SCATTER_SHOT", "HUNTERS_MARK" }) do
		local id = S[key]
		local name = ns.SpellName(id)
		local info = name and C_Spell.GetSpellInfo(name)
		local byName = name and C_Spell.IsSpellInRange(name, "target")
		local byID = C_Spell.IsSpellInRange(id, "target")
		ns.Print(string.format("%s: id %d, name %s, resolves to %s, known %s, byName %s, byID %s",
			key, id, show(name), show(info and info.spellID), show(ns.KnowsSpell(id)), show(byName), show(byID)))
	end
	for _, index in ipairs({ 3, 4 }) do
		local ok, r = pcall(CheckInteractDistance, "target", index)
		ns.Print("CheckInteractDistance(" .. index .. "):", ok and show(r) or ("error " .. tostring(r)))
	end
end

local function HasTarget()
	return ns.Plain(UnitExists("target")) and not ns.Plain(UnitIsDead("target"))
		and ns.Plain(UnitCanAttack("player", "target")) and true or false
end

local DEMO_ORDER = {
	{ "melee", "Melee Range" }, { "dead", "Dead Zone" }, { "scare", "Scare Beast" }, { "scatter", "Scatter Shot" },
	{ "short", "Short Range" }, { "long", "Long Range" }, { "mark", "Hunter's Mark" }, { "far", "Out of Range" },
}

local function OnUpdate(_, dt)
	elapsed = elapsed + dt
	if elapsed < 0.1 then return end
	elapsed = 0
	if ns.demo then
		-- simulation: every bracket for 1.5 s in turn
		local entry = DEMO_ORDER[math.floor(GetTime() / 1.5) % #DEMO_ORDER + 1]
		local c = ns.db.range[COLOR_KEYS[entry[1]]]
		frame:SetBackdropColor(c[1], c[2], c[3], 0.75)
		text:SetText(L[entry[2]])
		frame:SetAlpha(1)
		return
	end
	if not HasTarget() then
		frame:SetAlpha(ns.db.locked and 0 or 1)
		text:SetText(L["Range"])
		return
	end
	local key, label = Classify()
	local c = ns.db.range[COLOR_KEYS[key]]
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
