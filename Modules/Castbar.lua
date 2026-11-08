-- Castbar for the player's cast shots (Aimed Shot, Multi-Shot, Steady Shot), or every cast if wanted.
local _, ns = ...
local L = ns.L
local S = ns.SPELL

local M = ns.RegisterModule("Castbar", {})
local frame, bar, label, timer
local shotNames = {}

local function IsShot(name)
	return name and shotNames[name] or false
end

local function Current()
	local name, _, _, startMS, endMS = UnitCastingInfo("player")
	if not name then
		name, _, _, startMS, endMS = UnitChannelInfo("player")
	end
	if not name or ns.IsSecret(name) or ns.IsSecret(startMS) then return nil end
	if ns.db.castbar.onlyShots and not IsShot(name) then return nil end
	return name, startMS / 1000, endMS / 1000
end

local function OnUpdate()
	local name, startT, endT = Current()
	if not name then
		frame:SetAlpha(ns.db.locked and 0 or 1)
		bar:SetWidth(1)
		label:SetText("")
		timer:SetText("")
		return
	end
	local now = GetTime()
	local p = math.min(1, math.max(0, (now - startT) / math.max(0.01, endT - startT)))
	bar:SetWidth(math.max(1, (frame:GetWidth() - 2) * p))
	label:SetText(name)
	timer:SetFormattedText("%.1f", math.max(0, endT - now))
	frame:SetAlpha(1)
end

function M:Init()
	for _, id in ipairs({ S.AIMED_SHOT, S.MULTI_SHOT, S.STEADY_SHOT }) do
		local n = ns.SpellName(id)
		if n then shotNames[n] = true end
	end
	frame = CreateFrame("Frame", "ForeverQuiverCastbar", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("HIGH")
	ns.Backdrop(frame, 0.6)
	bar = frame:CreateTexture(nil, "ARTWORK")
	bar:SetPoint("TOPLEFT", 1, -1)
	bar:SetPoint("BOTTOMLEFT", 1, 1)
	bar:SetColorTexture(0.55, 0.6, 1, 0.9)
	bar:SetWidth(1)
	label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", 4, 0)
	timer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	timer:SetPoint("RIGHT", -4, 0)
	ns.MakeMovable(frame, "castbar", L["Castbar"], { "CENTER", "CENTER", 0, -170 })
	self:Refresh()
end

function M:Refresh()
	if not frame then return end
	local db = ns.db.castbar
	frame:SetSize(db.width, db.height)
	if db.enabled and ns.IsHunter() then
		frame:SetScript("OnUpdate", OnUpdate)
		frame:Show()
	else
		frame:SetScript("OnUpdate", nil)
		frame:Hide()
	end
end
