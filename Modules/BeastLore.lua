-- Tooltip lines on tameable beasts: which pet ability (and rank) taming them teaches, marked new or known.
-- Data: BeastData.lua (generated from AllTheThings' WoW: Forever beast training list).
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

local function OnTooltipUnit(tooltip, data)
	local db = ns.db.beast
	if not db.enabled or tooltip ~= GameTooltip then return end
	if not db.allClasses and not ns.IsHunter() then return end
	local guid = data and data.guid
	if not guid then
		local _, unit = tooltip:GetUnit()
		guid = unit and UnitGUID(unit)
	end
	local abilities = ns.BeastAbilities[NpcID(guid)]
	if not abilities then return end
	local lines = {}
	for _, spellID in ipairs(abilities) do
		local known = ns.IsKnownID(spellID)
		if not (known and db.onlyUnknown) then
			lines[#lines + 1] = { AbilityName(spellID), known }
		end
	end
	if #lines == 0 then return end
	tooltip:AddLine(L["Beast Training:"], 0.67, 0.83, 0.45)
	for _, line in ipairs(lines) do
		if line[2] then
			tooltip:AddDoubleLine("  " .. line[1], L["known"], 0.6, 0.6, 0.6, 0.6, 0.6, 0.6)
		else
			tooltip:AddDoubleLine("  " .. line[1], L["new"], 1, 1, 1, 0.1, 1, 0.1)
		end
	end
	tooltip:Show()
end

function M:Init()
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipUnit)
	elseif GameTooltip:HasScript("OnTooltipSetUnit") then
		GameTooltip:HookScript("OnTooltipSetUnit", function(tt) OnTooltipUnit(tt, nil) end)
	end
end
