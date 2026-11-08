-- Tranquilizing Shot announcer and cooldown list of every hunter in the group running Forever Quiver.
-- Casts are detected with UNIT_SPELLCAST_SUCCEEDED. Misses need the combat log; if the client does not let
-- addons read it, the miss announcement is simply skipped.
local _, ns = ...
local L = ns.L
local S = ns.SPELL

local PREFIX = "FQuiver"
local DEFAULT_CD = 20
local M = ns.RegisterModule("Tranq", {})
local frame, rows = nil, {}
local cooldowns = {} -- [name] = { start, duration }
local lastTarget

local function GroupChannel()
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
	if IsInRaid() then return "RAID" end
	if IsInGroup() then return "PARTY" end
end

-- The chat channel for announcements, from the "Tranq speech" option; nil = stay silent
local function SpeechChannel()
	local mode = ns.db.tranq.channel
	local group = GroupChannel()
	if mode == "NONE" or not group then return nil end
	if mode == "RAID_WARNING" and IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
		return "RAID_WARNING"
	end
	return group
end

local function Announce(msg)
	local channel = SpeechChannel()
	if not (channel and msg and msg ~= "") then return end
	local target = ns.FullName("target") or lastTarget
	msg = msg:gsub("%%t", target or "")
	local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
	if send then pcall(send, msg, channel) end
end

local function Broadcast(duration)
	local channel = GroupChannel()
	if channel and C_ChatInfo and C_ChatInfo.SendAddonMessage then
		-- the full name travels along: the sender field may carry the first name only
		local msg = string.format("TRANQ:%.1f:%s", duration, ns.FullName("player") or "")
		pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, channel)
	end
end

local function Row(i)
	local r = rows[i]
	if r then return r end
	r = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	r:SetSize(150, 14)
	r:SetPoint("TOPLEFT", 0, -(i - 1) * 15)
	ns.Backdrop(r, 0.6)
	r.bar = r:CreateTexture(nil, "ARTWORK")
	r.bar:SetPoint("TOPLEFT", 1, -1)
	r.bar:SetPoint("BOTTOMLEFT", 1, 1)
	r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	r.name:SetPoint("LEFT", 3, 0)
	r.time = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	r.time:SetPoint("RIGHT", -3, 0)
	rows[i] = r
	return r
end

local elapsed = 0
local function OnUpdate(_, dt)
	elapsed = elapsed + dt
	if elapsed < 0.1 then return end
	elapsed = 0
	local now = GetTime()
	local names = {}
	local source = cooldowns
	if ns.demo then
		-- simulation: you on cooldown, one hunter half way, one ready
		local start = now - now % 20
		source = { [ns.FullName("player") or "?"] = { start, 20 }, Legolas = { now - (now + 10) % 20, 20 }, Hawkeye = { now - 60, 20 } }
	end
	for name in pairs(source) do names[#names + 1] = name end
	table.sort(names)
	local show = ns.db.tranq.showBars and (ns.demo or IsInGroup() or not ns.db.locked)
	local i = 0
	if show then
		for _, name in ipairs(names) do
			i = i + 1
			local cd = source[name]
			local r = Row(i)
			local remaining = cd[1] + cd[2] - now
			r.name:SetText(name)
			if remaining > 0 then
				r.bar:SetColorTexture(0.8, 0.2, 0.2, 0.9)
				r.bar:SetWidth(math.max(1, 148 * (1 - remaining / cd[2])))
				r.time:SetFormattedText("%.0f", remaining)
			else
				r.bar:SetColorTexture(0.2, 0.8, 0.2, 0.9)
				r.bar:SetWidth(148)
				r.time:SetText("")
			end
			r:Show()
		end
	end
	for j = i + 1, #rows do rows[j]:Hide() end
end

local function OnCombatLog()
	local _, sub, _, srcGUID, _, _, _, _, _, _, _, _, spellName = CombatLogGetCurrentEventInfo()
	if ns.IsSecret(srcGUID) or srcGUID ~= UnitGUID("player") then return end
	if (sub == "SPELL_MISSED" or sub == "SPELL_DISPEL_FAILED") and spellName == ns.SpellName(S.TRANQ_SHOT) then
		Announce(ns.db.tranq.msgMiss)
	end
end

local function OnEvent(_, event, ...)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local _, _, spellID = ...
		if ns.IsSecret(spellID) then return end
		if ns.SpellName(spellID) == ns.SpellName(S.TRANQ_SHOT) then
			Announce(ns.db.tranq.msgCast)
			C_Timer.After(0.1, function()
				local duration = DEFAULT_CD
				local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellID)
				if info and not ns.IsSecret(info.duration) and info.duration and info.duration > 1.5 then
					duration = info.duration
				end
				cooldowns[ns.FullName("player") or UnitName("player")] = { GetTime(), duration }
				Broadcast(duration)
			end)
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		lastTarget = ns.FullName("target") or lastTarget
	elseif event == "CHAT_MSG_ADDON" then
		local prefix, msg, _, sender = ...
		if prefix ~= PREFIX or ns.IsSecret(msg) then return end
		local d, name = msg:match("^TRANQ:([%d%.]+):?(.*)$")
		if not d or ns.IsSecret(sender) then return end
		if name == "" then name = (sender:gsub("%-.*$", "")) end -- 0.1.0 sent no name
		local me = ns.FullName("player")
		if name ~= me and Ambiguate(sender, "none") ~= UnitName("player") then
			cooldowns[name] = { GetTime(), tonumber(d) or DEFAULT_CD }
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		if not IsInGroup() then
			local me = ns.FullName("player") or UnitName("player")
			for name in pairs(cooldowns) do
				if name ~= me then cooldowns[name] = nil end
			end
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		OnCombatLog()
	end
end

function M:Init()
	if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
		C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
	end
	frame = CreateFrame("Frame", "ForeverQuiverTranq", UIParent)
	frame:SetSize(150, 14)
	ns.MakeMovable(frame, "tranq", L["Tranq Shot"], { "CENTER", "CENTER", 250, 0 })
	frame:SetScript("OnEvent", OnEvent)
	self:Refresh()
end

function M:Refresh()
	if not frame then return end
	frame:UnregisterAllEvents()
	if ns.db.tranq.enabled and ns.IsHunter() then
		frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		frame:RegisterEvent("PLAYER_TARGET_CHANGED")
		frame:RegisterEvent("CHAT_MSG_ADDON")
		frame:RegisterEvent("GROUP_ROSTER_UPDATE")
		-- the combat log is off-limits on clients with secret restrictions; the miss announcement then stays off
		if not (C_Secrets and C_Secrets.HasSecretRestrictions and C_Secrets.HasSecretRestrictions()) then
			frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
		frame:SetScript("OnUpdate", OnUpdate)
		frame:Show()
	else
		frame:SetScript("OnUpdate", nil)
		frame:Hide()
	end
end
