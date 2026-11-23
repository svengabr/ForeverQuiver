-- Tooltip lines on tameable beasts: which pet ability (and rank) taming them teaches, marked new or known.
-- Data: BeastData.lua (generated from AllTheThings' WoW: Forever beast training list).
--
-- The hunter's learned Beast Training abilities are not in the player spellbook, and the client has no call
-- for them outside the Beast Training window (a pet trainer on Forever). So every time it opens, the highest rank
-- of each ability listed there is saved per character (ForeverQuiverCharDB.beastRanks, keyed by the English
-- name so a client language change keeps it). Abilities the current pet knows count as known as well.
local _, ns = ...
local L = ns.L

local M = ns.RegisterModule("BeastLore", {})

local function NpcID(guid)
	if not guid or ns.IsSecret(guid) then return nil end
	local unitType, _, _, _, _, id = strsplit("-", guid)
	if unitType ~= "Creature" then return nil end
	return tonumber(id)
end

local function AbilityName(spellID)
	local data = ns.BeastRank[spellID]
	local name = ns.SpellName(spellID)
	if name and data then
		-- the client's spell name has no rank; the data carries it
		return string.format(L["%s (Rank %d)"], name, data[1])
	end
	return data and string.format(L["%s (Rank %d)"], data[2], data[1]) or tostring(spellID)
end

local function CharDB()
	ForeverQuiverCharDB = ForeverQuiverCharDB or {}
	return ForeverQuiverCharDB
end

-- localized ability name -> English name, built on first use (spell names may not be cached at login)
local englishByLocal
local function EnglishName(localName)
	if not englishByLocal then
		englishByLocal = {}
		for spellID, data in pairs(ns.BeastRank) do
			local name = ns.SpellName(spellID)
			if name and not ns.IsSecret(name) then englishByLocal[name] = data[2] end
			englishByLocal[data[2]] = data[2]
		end
	end
	return englishByLocal[localName]
end

local function IsPetTrainer()
	return C_Trainer and C_Trainer.GetTrainerType and Enum.TrainerType and Enum.TrainerType.Pet ~= nil
		and C_Trainer.GetTrainerType() == Enum.TrainerType.Pet
end

-- English name and rank of a trainer entry: from the spell ID in its tooltip data when the client gives one,
-- else from the shown name and the "Rank N" subtext.
local function ServiceAbility(index)
	if C_TooltipInfo and C_TooltipInfo.GetTrainerService then
		local data = C_TooltipInfo.GetTrainerService(index)
		local id = data and ns.Plain(data.id)
		local known = id and ns.BeastRank[id]
		if known then return known[2], known[1] end
	end
	local name, _, _, _, sub = GetTrainerServiceInfo(index)
	name, sub = ns.Plain(name), ns.Plain(sub)
	local english = name and EnglishName(name)
	if not english then return nil end
	return english, tonumber(sub and sub:match("%d+")) or 1
end

-- Debug: /fq beast prints the last scan, /fq beast watch prints every scan as it happens.
local lastScan, watch = { "no trainer window opened since login" }, false

local function Trace(lines, text)
	lines[#lines + 1] = text
	if watch then ns.Print("|cff999999beast:|r " .. text) end
end

local function TraceEntry(lines, i, english, rank)
	local name, serviceType, _, _, sub = GetTrainerServiceInfo(i)
	local data = C_TooltipInfo and C_TooltipInfo.GetTrainerService and C_TooltipInfo.GetTrainerService(i)
	Trace(lines, string.format("  #%d id=%s name=%s sub=%s type=%s -> %s", i, tostring(data and data.id),
		tostring(name), tostring(sub), tostring(serviceType),
		english and (english .. " " .. rank) or "|cffff5555not a beast ability|r"))
end

-- The window's filter hides "used" (the pet has it) and "unavailable" entries by default, but those are
-- learned abilities too. So once per opening, every filter is switched on; the player's own settings come
-- back after the next list update (the filter may apply asynchronously) or when the window closes.
local FILTERS = { "available", "unavailable", "used" }
local savedFilters, widenedThisOpen, settingFilters

local function RestoreFilters(lines)
	if not savedFilters then return end
	local restore = savedFilters
	savedFilters = nil
	settingFilters = true
	for filter, on in pairs(restore) do SetTrainerServiceTypeFilter(filter, on) end
	settingFilters = nil
	if lines then Trace(lines, "filters restored") end
end

local function WidenFilters(lines)
	if widenedThisOpen or not (GetTrainerServiceTypeFilter and SetTrainerServiceTypeFilter) then return end
	widenedThisOpen = true
	local states, anyOff = {}, false
	for _, filter in ipairs(FILTERS) do
		states[filter] = GetTrainerServiceTypeFilter(filter) and true or false
		if not states[filter] then anyOff = true end
	end
	if not anyOff then return end
	savedFilters = states
	settingFilters = true
	for _, filter in ipairs(FILTERS) do SetTrainerServiceTypeFilter(filter, true) end
	settingFilters = nil
	Trace(lines, string.format("filters widened (were available=%s unavailable=%s used=%s)",
		tostring(states.available), tostring(states.unavailable), tostring(states.used)))
end

-- Reads the open Beast Training window, which Forever shows as a pet trainer: every entry is an ability the
-- hunter has learned. Ranks are merged, never lowered.
local function ScanTrainer(event)
	if settingFilters then return end -- an update fired by our own filter change
	if event == "TRAINER_CLOSED" then
		RestoreFilters()
		widenedThisOpen = nil
		return
	end
	local lines = {}
	lastScan = lines
	local trainerType = C_Trainer and C_Trainer.GetTrainerType and C_Trainer.GetTrainerType()
	Trace(lines, string.format("%s at %s, trainer type %s (pet = %s)", tostring(event), date("%H:%M:%S"),
		tostring(trainerType), tostring(Enum.TrainerType and Enum.TrainerType.Pet)))
	if not (GetNumTrainerServices and GetTrainerServiceInfo) or not ns.IsHunter() or not IsPetTrainer() then
		Trace(lines, "skipped: not a hunter at the Beast Training window")
		return
	end
	-- an update after widening carries the full list: read it, then give the player their filters back
	local restoreAfter = savedFilters ~= nil and event == "TRAINER_UPDATE"
	WidenFilters(lines)
	local count = ns.Plain(GetNumTrainerServices()) or 0
	Trace(lines, "entries: " .. tostring(count))
	local found = {}
	for i = 1, count do
		local english, rank = ServiceAbility(i)
		TraceEntry(lines, i, english, rank)
		if english and rank > (found[english] or 0) then found[english] = rank end
	end
	if next(found) then
		local db = CharDB()
		db.beastRanks = db.beastRanks or {}
		for english, rank in pairs(found) do
			if rank > (db.beastRanks[english] or 0) then db.beastRanks[english] = rank end
		end
		Trace(lines, "saved")
	elseif count > 0 then
		Trace(lines, "nothing saved: no entry matched a beast ability")
	end
	if restoreAfter then RestoreFilters(lines) end
end

local function PetKnows(spellID)
	if C_SpellBook and C_SpellBook.IsSpellKnown and Enum.SpellBookSpellBank then
		return C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet) == true
	elseif IsSpellKnown then
		return IsSpellKnown(spellID, true) == true
	end
	return false
end

-- true / false, or nil when it can't be told (Beast Training window never opened on this character)
local function Known(spellID, ranks)
	local data = ns.BeastRank[spellID]
	if ranks and data and (ranks[data[2]] or 0) >= data[1] then return true end
	if ns.IsKnownID(spellID) or PetKnows(spellID) then return true end
	if ranks then return false end
	return nil
end

local function OnTooltipUnit(tooltip, data)
	local db = ns.db.beast
	if not db.enabled or tooltip ~= GameTooltip then return end
	local hunter = ns.IsHunter()
	if not db.allClasses and not hunter then return end
	local guid = data and data.guid
	if not guid then
		local _, unit = tooltip:GetUnit()
		guid = unit and UnitGUID(unit)
	end
	local abilities = ns.BeastAbilities[NpcID(guid)]
	if not abilities then return end
	local ranks = hunter and CharDB().beastRanks or nil
	local lines, unsure = {}, false
	for _, spellID in ipairs(abilities) do
		local known = nil
		if hunter then known = Known(spellID, ranks) end
		if known == nil then unsure = true end
		if not (known and db.onlyUnknown) then
			lines[#lines + 1] = { AbilityName(spellID), known }
		end
	end
	if #lines == 0 then return end
	tooltip:AddLine(L["Beast Training:"], 0.67, 0.83, 0.45)
	for _, line in ipairs(lines) do
		if line[2] == true then
			tooltip:AddDoubleLine("  " .. line[1], L["known"], 0.6, 0.6, 0.6, 0.6, 0.6, 0.6)
		elseif line[2] == false then
			tooltip:AddDoubleLine("  " .. line[1], L["new"], 1, 1, 1, 0.1, 1, 0.1)
		else
			tooltip:AddLine("  " .. line[1], 1, 1, 1)
		end
	end
	if hunter and unsure then
		tooltip:AddLine(L["Open Beast Training once to see which abilities you know."], 0.6, 0.6, 0.6, true)
	end
	tooltip:Show()
end

function M:Init()
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipUnit)
	elseif GameTooltip:HasScript("OnTooltipSetUnit") then
		GameTooltip:HookScript("OnTooltipSetUnit", function(tt) OnTooltipUnit(tt, nil) end)
	end
	if ns.IsHunter() then
		local f = CreateFrame("Frame")
		f:RegisterEvent("TRAINER_SHOW")
		f:RegisterEvent("TRAINER_UPDATE")
		f:RegisterEvent("TRAINER_CLOSED")
		f:SetScript("OnEvent", function(_, event)
			local ok, err = pcall(ScanTrainer, event)
			if not ok then geterrorhandler()(err) end
		end)
	end
end

-- /fq beast [watch | reset]: saved ranks, the last Beast Training scan and the verdicts for the target.
function ns.DebugBeast(arg)
	arg = (arg or ""):lower()
	if arg == "watch" then
		watch = not watch
		ns.Print("beast watch " .. (watch and "on: every Beast Training scan is printed" or "off"))
		return
	elseif arg == "reset" then
		CharDB().beastRanks = nil
		ns.Print("beast: saved ranks cleared for this character")
		return
	end
	local ranks = CharDB().beastRanks
	ns.Print("beast: saved ranks" .. (ranks and "" or ": none (Beast Training not scanned yet)"))
	if ranks then
		local names = {}
		for name in pairs(ranks) do names[#names + 1] = name end
		table.sort(names)
		for _, name in ipairs(names) do print(string.format("  %s %d", name, ranks[name])) end
	end
	ns.Print("beast: last scan")
	for _, line in ipairs(lastScan) do print("  " .. line) end
	local npc = UnitExists("target") and NpcID(UnitGUID("target"))
	local abilities = npc and ns.BeastAbilities[npc]
	if not abilities then
		ns.Print("beast: target a tameable beast to see its verdicts")
		return
	end
	ns.Print(string.format("beast: target %s (npc %d)", tostring(UnitName("target")), npc))
	for _, spellID in ipairs(abilities) do
		local data = ns.BeastRank[spellID]
		print(string.format("  %s id=%d saved=%s player=%s pet=%s -> %s", AbilityName(spellID), spellID,
			tostring(ranks and data and ranks[data[2]]), tostring(ns.IsKnownID(spellID)),
			tostring(PetKnows(spellID)), tostring(Known(spellID, ranks))))
	end
end
