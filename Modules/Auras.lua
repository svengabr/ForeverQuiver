-- Aspect tracker, Trueshot Aura alarm and ammo warning: small reminder widgets driven by the player's buffs
-- and inventory.
local _, ns = ...
local L = ns.L
local S = ns.SPELL

local function MakeIcon(name, size)
	local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	f:SetSize(size, size)
	f:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
	f:SetBackdropBorderColor(0, 0, 0, 1)
	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetPoint("TOPLEFT", 2, -2)
	f.icon:SetPoint("BOTTOMRIGHT", -2, 2)
	f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	f.text = f:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	f.text:SetPoint("BOTTOM", f, "BOTTOM", 0, 2)
	return f
end

-------------------------------------------------------------------------------
-- Aspect tracker
-------------------------------------------------------------------------------

ns.ASPECTS = { -- key, spell
	{ "HAWK", S.ASPECT_HAWK }, { "MONKEY", S.ASPECT_MONKEY }, { "CHEETAH", S.ASPECT_CHEETAH },
	{ "PACK", S.ASPECT_PACK }, { "BEAST", S.ASPECT_BEAST }, { "WILD", S.ASPECT_WILD },
}
local DANGEROUS = { CHEETAH = true, PACK = true } -- daze on hit: red border

local Aspect = ns.RegisterModule("Aspect", {})
local aspectFrame

local function ActiveAspect()
	for _, a in ipairs(ns.ASPECTS) do
		local name = ns.SpellName(a[2])
		local aura = name and ns.FindPlayerBuffByName(name)
		if aura then return a[1], aura.icon end
	end
end

function Aspect:Update()
	local f = aspectFrame
	if ns.demo and ns.db.aspect.enabled then
		-- simulation: Aspect of the Cheetah, the one that gets a red border
		f.icon:SetTexture(ns.SpellIcon(S.ASPECT_CHEETAH))
		f.icon:SetDesaturated(false)
		f.icon:SetAlpha(1)
		f:SetBackdropBorderColor(1, 0.1, 0.1, 1)
		f:Show()
		return
	end
	if not (ns.db.aspect.enabled and ns.IsHunter() and ns.KnowsSpell(S.ASPECT_HAWK)) then
		f:SetShown(not ns.db.locked and ns.db.aspect.enabled)
		return
	end
	local key, icon = ActiveAspect()
	local hide = ns.db.aspect.hideAspect
	if key and key == hide and ns.db.locked then
		f:Hide()
		return
	end
	if key then
		f.icon:SetTexture(icon)
		f.icon:SetDesaturated(false)
		f.icon:SetAlpha(1)
		if DANGEROUS[key] then
			f:SetBackdropBorderColor(1, 0.1, 0.1, 1)
		else
			f:SetBackdropBorderColor(0, 0, 0, 1)
		end
	else
		-- no aspect at all: show the preferred one, faded, as a reminder
		local want = S.ASPECT_HAWK
		for _, a in ipairs(ns.ASPECTS) do
			if a[1] == hide then want = a[2] end
		end
		f.icon:SetTexture(ns.SpellIcon(want))
		f.icon:SetDesaturated(true)
		f.icon:SetAlpha(0.8)
		f:SetBackdropBorderColor(1, 0.8, 0, 1)
	end
	f:Show()
end

function Aspect:Init()
	aspectFrame = MakeIcon("ForeverQuiverAspect", ns.db.aspect.size)
	ns.MakeMovable(aspectFrame, "aspect", L["Aspect"], { "CENTER", "CENTER", -60, -110 })
	aspectFrame:RegisterUnitEvent("UNIT_AURA", "player")
	aspectFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	aspectFrame:RegisterEvent("SPELLS_CHANGED")
	aspectFrame:SetScript("OnEvent", function() Aspect:Update() end)
	self:Refresh()
end

function Aspect:Refresh()
	if not aspectFrame then return end
	aspectFrame:SetSize(ns.db.aspect.size, ns.db.aspect.size)
	self:Update()
end

-------------------------------------------------------------------------------
-- Trueshot Aura alarm
-------------------------------------------------------------------------------

local Trueshot = ns.RegisterModule("Trueshot", {})
local tsFrame
local tsElapsed = 0

function Trueshot:Update()
	local f = tsFrame
	local db = ns.db.trueshot
	if ns.demo and db.enabled then
		-- simulation: the aura is about to run out
		f.icon:SetTexture(ns.SpellIcon(S.TRUESHOT_AURA))
		f:SetBackdropBorderColor(1, 0.8, 0, 1)
		f.text:SetFormattedText("%d", 59 - math.floor(ns.DemoClock("trueshot") % 60))
		f:Show()
		return
	end
	if not (db.enabled and ns.IsHunter() and ns.KnowsSpell(S.TRUESHOT_AURA)) then
		f:SetShown(not ns.db.locked and db.enabled)
		f.text:SetText("")
		return
	end
	local aura = ns.FindPlayerBuffByName(ns.SpellName(S.TRUESHOT_AURA))
	f.icon:SetTexture(ns.SpellIcon(S.TRUESHOT_AURA))
	if not aura then
		f:SetBackdropBorderColor(1, 0.1, 0.1, 1)
		f.text:SetText(L["missing"])
		f:Show()
		return
	end
	local expires = ns.Plain(aura.expirationTime)
	local remaining = expires and expires > 0 and (expires - GetTime()) or nil
	if remaining and remaining < db.threshold then
		f:SetBackdropBorderColor(1, 0.8, 0, 1)
		f.text:SetFormattedText("%d", remaining)
		f:Show()
	elseif not ns.db.locked then
		f:SetBackdropBorderColor(0, 0, 0, 1)
		f.text:SetText("")
		f:Show()
	else
		f:Hide()
	end
end

function Trueshot:Init()
	tsFrame = MakeIcon("ForeverQuiverTrueshot", ns.db.trueshot.size)
	ns.MakeMovable(tsFrame, "trueshot", L["Trueshot Aura"], { "CENTER", "CENTER", 60, -110 })
	tsFrame:RegisterUnitEvent("UNIT_AURA", "player")
	tsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	tsFrame:RegisterEvent("SPELLS_CHANGED")
	tsFrame:SetScript("OnEvent", function() Trueshot:Update() end)
	-- countdown text needs a tick; once per second is plenty
	local ticker = CreateFrame("Frame")
	ticker:SetScript("OnUpdate", function(_, dt)
		tsElapsed = tsElapsed + dt
		if tsElapsed >= 1 then tsElapsed = 0 Trueshot:Update() end
	end)
	self:Refresh()
end

function Trueshot:Refresh()
	if not tsFrame then return end
	tsFrame:SetSize(ns.db.trueshot.size, ns.db.trueshot.size)
	self:Update()
end

-------------------------------------------------------------------------------
-- Ammo warning
-------------------------------------------------------------------------------

local Ammo = ns.RegisterModule("Ammo", {})
local ammoFrame, ammoText
local warned = false
local primed = false -- the first reading after login only sets the state, so a reload doesn't warn again

local function AmmoCount()
	if UnitUsesAmmo and ns.Plain(UnitUsesAmmo("player")) == false then return nil end
	if not GetInventoryItemID("player", INVSLOT_RANGED or 18) then return nil end
	local slot = INVSLOT_AMMO or 0
	if not GetInventoryItemID("player", slot) then return 0 end
	local count = GetInventoryItemCount("player", slot)
	if ns.IsSecret(count) then return nil end
	return count or 0
end

function Ammo:Update()
	local db = ns.db.ammo
	if not (db.enabled and ns.IsHunter()) then
		ammoFrame:Hide()
		return
	end
	local count = ns.demo and 37 or AmmoCount() -- simulation: nearly out
	if count == nil then
		ammoText:SetFormattedText(L["Ammo: %d"], 0)
		ammoFrame:SetShown(not ns.db.locked)
		return
	end
	if count == 0 then
		ammoText:SetText(L["No ammo!"])
		ammoText:SetTextColor(1, 0.1, 0.1)
	elseif count < db.threshold then
		ammoText:SetFormattedText(L["Ammo low: %d left"], count)
		if count < db.threshold / 4 then
			ammoText:SetTextColor(1, 0.1, 0.1)
		else
			ammoText:SetTextColor(1, 0.8, 0)
		end
	else
		ammoText:SetFormattedText(L["Ammo: %d"], count)
		ammoText:SetTextColor(1, 1, 1)
	end
	local low = count < db.threshold
	if not primed and not ns.demo then
		primed = true
		warned = low
	end
	if low and not warned and not ns.demo then
		warned = true
		if db.sound then PlaySound(SOUNDKIT.RAID_WARNING or 8959, "Master") end
		if RaidNotice_AddMessage and RaidWarningFrame then
			RaidNotice_AddMessage(RaidWarningFrame, ammoText:GetText(), ChatTypeInfo.RAID_WARNING)
		end
	elseif not low then
		warned = false
	end
	ammoFrame:SetShown(low or not ns.db.locked)
end

function Ammo:Init()
	ammoFrame = CreateFrame("Frame", "ForeverQuiverAmmo", UIParent)
	ammoFrame:SetSize(180, 20)
	ammoText = ammoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	ammoText:SetPoint("CENTER")
	ns.MakeMovable(ammoFrame, "ammo", L["Ammo"], { "CENTER", "CENTER", 0, -80 })
	ammoFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	ammoFrame:RegisterEvent("BAG_UPDATE_DELAYED")
	ammoFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	ammoFrame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
	ammoFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	ammoFrame:SetScript("OnEvent", function() Ammo:Update() end)
	self:Refresh()
end

function Ammo:Refresh()
	if ammoFrame then self:Update() end
end
