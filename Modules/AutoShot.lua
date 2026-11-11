-- Auto Shot timer. Red bar shrinking = reloading, yellow bar growing = aiming (the 0.5 s wind-up during which
-- you must stand still). Auto Shot fires UNIT_SPELLCAST_SUCCEEDED with spell 75 on this client, so there is no
-- need for the inventory-lock heuristics the vanilla addon used.
local _, ns = ...
local L = ns.L
local S = ns.SPELL

local AIM_TIME = 0.5
local M = ns.RegisterModule("AutoShot", {})

local frame, bar, text, status
local shooting = false      -- auto-repeat active
local reloadStart, reloadDur = 0, 0
local aimStart = 0
local casting = false
local lastShot, measured = 0, nil

local function RangedSpeed()
	local speed = UnitRangedDamage("player")
	if speed and not ns.IsSecret(speed) and speed > 0 then return speed end
	return measured or 2.5
end

local function Reloading(now)
	return now < reloadStart + reloadDur
end

-- for macros: ForeverQuiver.GetAutoShotState() -> isShooting, secondsUntilShot (nil if unknown)
function ns.GetAutoShotState()
	local now = GetTime()
	if not shooting then return false, nil end
	if Reloading(now) then
		return true, reloadStart + reloadDur - now + AIM_TIME
	end
	return true, math.max(0, aimStart + AIM_TIME - now)
end

local function Layout()
	local db = ns.db.autoShot
	frame:SetSize(db.width, db.height)
	bar:SetHeight(db.height - 2)
	bar:ClearAllPoints()
	if db.direction == "CENTER" then
		bar:SetPoint("CENTER") -- grows from the middle to both sides
	else
		bar:SetPoint("LEFT", 1, 0)
	end
	text:SetShown(db.showText)
end

local function OnUpdate()
	local now = GetTime()
	local width = frame:GetWidth() - 2
	if ns.demo then
		-- simulation: 2.5 s reload, 0.5 s aim, over and over
		local t = ns.DemoClock("autoShot") % 3
		local db = ns.db.autoShot
		status:SetText("")
		if t < 2.5 then
			local c = db.colorReload
			bar:SetColorTexture(c[1], c[2], c[3], 0.9)
			bar:SetWidth(math.max(1, width * (2.5 - t) / 2.5))
			text:SetFormattedText("%.1f", 2.5 - t)
		else
			local c = db.colorShoot
			bar:SetColorTexture(c[1], c[2], c[3], 0.9)
			bar:SetWidth(math.max(1, width * (t - 2.5) / AIM_TIME))
			text:SetFormattedText("%.1f", 3 - t)
		end
		frame:SetAlpha(1)
		return
	end
	if Reloading(now) then
		local remaining = reloadStart + reloadDur - now
		local c = ns.db.autoShot.colorReload
		bar:SetColorTexture(c[1], c[2], c[3], 0.9)
		bar:SetWidth(math.max(1, width * remaining / reloadDur))
		text:SetFormattedText("%.1f", remaining)
		frame:SetAlpha(1)
		if shooting then aimStart = now end
		return
	end
	if shooting and not casting and ns.InRange(S.AUTO_SHOT) == false then
		-- Auto Shot can't reach the target: grey bar with the reason instead of a wind-up that never fires
		local maxR
		if ns.RangeBracket then maxR = select(2, ns.RangeBracket()) end
		aimStart = now
		bar:SetColorTexture(0.5, 0.5, 0.5, 0.7)
		bar:SetWidth(width)
		status:SetText((maxR and maxR <= 15) and L["too close"] or L["too far"])
		text:SetText("")
		frame:SetAlpha(1)
		return
	end
	status:SetText("")
	if shooting and not casting then
		local moving = M.moving
		if moving then aimStart = now end
		local p = math.min(1, (now - aimStart) / AIM_TIME)
		local c = ns.db.autoShot.colorShoot
		bar:SetColorTexture(c[1], c[2], c[3], 0.9)
		bar:SetWidth(math.max(1, width * p))
		text:SetText(moving and "" or string.format("%.1f", math.max(0, AIM_TIME - (now - aimStart))))
		frame:SetAlpha(1)
		return
	end
	bar:SetWidth(1)
	text:SetText("")
	frame:SetAlpha(ns.db.locked and 0 or 1)
end

local function OnEvent(_, event, unit, _, spellID)
	local now = GetTime()
	-- GetUnitSpeed is secret on this client; the movement events are not
	if event == "PLAYER_STARTED_MOVING" then
		M.moving = true
	elseif event == "PLAYER_STOPPED_MOVING" then
		M.moving = false
		aimStart = now
	elseif event == "START_AUTOREPEAT_SPELL" then
		shooting = true
		if not Reloading(now) then aimStart = now end
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		shooting = false
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if ns.IsSecret(spellID) then return end
		if spellID == S.AUTO_SHOT then
			if lastShot > 0 and now - lastShot < 5 then
				measured = now - lastShot
			end
			lastShot = now
			reloadStart = now
			reloadDur = math.max(0.1, RangedSpeed() - AIM_TIME)
		elseif shooting and not Reloading(now) then
			-- any other cast during the wind-up restarts it
			aimStart = now
		end
	elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
		casting = true
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
		or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if casting then
			casting = false
			aimStart = now
		end
	end
end

function M:Init()
	frame = CreateFrame("Frame", "ForeverQuiverAutoShot", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("HIGH")
	ns.Backdrop(frame, 0.6)
	bar = frame:CreateTexture(nil, "ARTWORK")
	bar:SetPoint("LEFT", 1, 0)
	bar:SetWidth(1)
	text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER")
	-- always visible, unlike the seconds text
	status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	status:SetPoint("CENTER")
	ns.MakeMovable(frame, "autoShot", L["Auto Shot"], { "CENTER", "CENTER", 0, -150 })
	frame:SetScript("OnEvent", OnEvent)
	self:Refresh()
end

function M:Refresh()
	if not frame then return end
	local enabled = ns.db.autoShot.enabled and ns.IsHunter()
	Layout()
	if enabled then
		frame:RegisterEvent("START_AUTOREPEAT_SPELL")
		frame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
		frame:RegisterEvent("PLAYER_STARTED_MOVING")
		frame:RegisterEvent("PLAYER_STOPPED_MOVING")
		M.moving = IsPlayerMoving and ns.Plain(IsPlayerMoving()) and true or false
		frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
		frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
		frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
		frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
		frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
		frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
		frame:SetScript("OnUpdate", OnUpdate)
		frame:Show()
	else
		frame:UnregisterAllEvents()
		frame:SetScript("OnUpdate", nil)
		frame:Hide()
	end
end
