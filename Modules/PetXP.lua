-- Pet experience inside the XP bar the player already has: FlareUI's if that addon replaced the game's, else the
-- game's own.
--
-- The game has two bar slots (the containers below) and fills them with XP, reputation and so on. The pet's bar is
-- drawn in a slot the game leaves empty; when both are taken it can cover the reputation bar. Registering the bar
-- with the game's StatusTrackingBarManager would taint it, and that code also positions the action bars: they would
-- be blocked in combat. So nothing here writes to the game's tables or calls its layout code. Frames are only shown,
-- faded and anchored, and only out of combat. Restack repeats what
-- EditModeManagerFrame:UpdateBottomActionBarPositions does (Blizzard_EditMode), with the plain frame methods.
local _, ns = ...
local L = ns.L

local M = ns.RegisterModule("PetXP", {})
local bar     -- the pet's bar in the game's slots
local flare   -- FlareUI's XP bar, when it replaces the game's
local slot    -- the container the bar sits in
local covered -- the game's reputation bar it hides there, or nil when the slot was empty
local containers = {}

local FILL = {
	EXPERIENCE = "UI-HUD-ExperienceBar-Fill-Experience",
	RESTED = "UI-HUD-ExperienceBar-Fill-Rested",
	REPUTATION = "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Green",
	HONOR = "UI-HUD-ExperienceBar-Fill-Honor",
	ARTIFACT = "UI-HUD-ExperienceBar-Fill-ArtifactPower",
}
-- the same colours for FlareUI's plain textures
local COLOR = {
	EXPERIENCE = { 0.58, 0, 0.55 },
	RESTED = { 0, 0.39, 0.88 },
	REPUTATION = { 0, 0.6, 0.1 },
	HONOR = { 1, 0.4, 0 },
	ARTIFACT = { 0.9, 0.8, 0.5 },
}

-- current XP, XP for the next level, pet level; nil when there is nothing to show
local function Data()
	if not ns.db.petxp.enabled then return nil end
	if ns.demo then return 4120, 9800, 23 end
	if not UnitExists("pet") or not GetPetExperience then return nil end
	local cur, max = GetPetExperience()
	cur, max = ns.Plain(cur), ns.Plain(max)
	if not cur or not max or max <= 0 then return nil end -- no hunter pet, or a pet that gets no XP
	return cur, max, ns.Plain(UnitLevel("pet"))
end

local function Number(n)
	return BreakUpLargeNumbers and BreakUpLargeNumbers(n) or tostring(n)
end

local function Text(cur, max, level)
	local pct = math.floor(cur / max * 100)
	if level then
		return L["Pet level %d: %s / %s (%d%%)"]:format(level, Number(cur), Number(max), pct)
	end
	return ("%s / %s (%d%%)"):format(Number(cur), Number(max), pct)
end

-------------------------------------------------------------------------------
-- FlareUI's XP bar: two sections, Left and Right, that FlareUI lays out anew on every update. It ends each update
-- with Show, or with Hide when it has nothing to show; the pet's section is put in after that. An update of its
-- own (FlareUI.XPBar:Refresh) takes it out again.
-------------------------------------------------------------------------------

local FLARE_GAP = 3 -- between the two bars in its Double style
local PET = { kind = "pet" } -- marks a section the pet's XP is in
local drawing = false
local hadData = false

-- FlareUI places the dividers for the width it knows; here the section got another one.
local function FlareBubbles(section, width)
	local count = 1
	for _, pair in ipairs(section.Bubbles) do
		if pair[1]:IsShown() then count = count + 1 end
	end
	if count == 1 then return end
	local px = section.Bubbles[1][1]:GetWidth()
	local total = math.floor(width / px + 0.5)
	for i = 1, count - 1 do
		local x = math.floor(total * i / count + 0.5) * px
		for side, line in ipairs(section.Bubbles[i]) do
			local dx = side == 1 and x - px or x
			line:ClearAllPoints()
			line:SetPoint("TOPLEFT", section, "TOPLEFT", dx, 0)
			line:SetPoint("BOTTOMLEFT", section, "BOTTOMLEFT", dx, 0)
		end
	end
	section.ftBubbles = nil -- FlareUI's own note of what it laid out
end

local function FlarePaint(section, cur, max, level)
	local color = COLOR[ns.db.petxp.fill] or COLOR.HONOR
	section.info = PET
	section.ftFraction = nil -- FlareUI's next value there lands at once
	section.Rested:Hide()
	section.Quest:Hide()
	section.QuestOpen:Hide()
	section:SetStatusBarColor(color[1], color[2], color[3], 1)
	section:SetValue(math.min(1, cur / max))
	section.Text:SetText(Text(cur, max, level))
	if ns.db.petxp.alwaysText then section.Text:Show() end
	section:Show()
end

local function FlareDraw()
	if drawing or not flare:IsShown() then return end
	local cur, max, level = Data()
	if not cur or FlareUI.EditPreviewing() then return end
	local left, right = flare.Left, flare.Right
	if left.info == PET then return FlarePaint(left, cur, max, level) end -- alone, see FlareHidden
	local inset = select(4, left:GetPoint(1))
	local width, height = flare:GetWidth() - 2 * inset, left:GetHeight()
	if right:IsShown() and right.info ~= PET then
		if not (ns.db.petxp.cover and right.info and right.info.kind == "rep") then return end
	elseif FlareUI.XPBar.Style() == "double" then
		flare:SetHeight(2 * height + FLARE_GAP + 2 * inset)
		right:ClearAllPoints()
		right:SetPoint("TOPLEFT", left, "BOTTOMLEFT", 0, -FLARE_GAP)
		right:SetSize(width, height)
	else
		local half = width / 2
		local ratio = half / left:GetWidth() -- 1 when it is split already
		left:SetWidth(half)
		for _, texture in ipairs({ left.Rested, left.Quest, left.QuestOpen }) do
			texture:SetWidth(math.max(1, texture:GetWidth() * ratio))
		end
		right:ClearAllPoints()
		right:SetPoint("TOPRIGHT", flare, "TOPRIGHT", -inset, -inset)
		right:SetSize(half, height)
		FlareBubbles(left, half)
		FlareBubbles(right, half)
		local pip = height + 4 -- FlareUI's own size for it
		flare.Pip:SetSize(math.max(4, math.floor(pip * 10 / 14 + 0.5)), pip)
		flare.Pip:Show()
	end
	FlarePaint(right, cur, max, level)
end

-- Nothing of FlareUI's own to show (max level, no reputation watched): the pet gets the whole bar.
local function FlareHidden()
	local cur, max, level = Data()
	if drawing or not cur or FlareUI.EditPreviewing() then return end
	local left = flare.Left
	local inset = select(4, left:GetPoint(1)) or 4
	local width, height = flare:GetWidth() - 2 * inset, left:GetHeight()
	if height < 1 then height = flare:GetHeight() - 2 * inset end -- never laid out yet
	left:ClearAllPoints()
	left:SetPoint("TOPLEFT", flare, "TOPLEFT", inset, -inset)
	left:SetSize(width, height)
	flare:SetHeight(height + 2 * inset)
	FlareBubbles(left, width)
	flare.Right:Hide()
	flare.Pip:Hide()
	FlarePaint(left, cur, max, level)
	drawing = true
	flare:Show()
	drawing = false
end

local function FindFlare()
	local f, addon = rawget(_G, "FlareUI_XPBar"), rawget(_G, "FlareUI")
	if not (f and f.Left and f.Right and f.Pip and f.Left.Bubbles and addon and addon.EditPreviewing
		and addon.XPBar and addon.XPBar.Refresh and addon.XPBar.Style) then return end
	flare = f
	hooksecurefunc(flare, "Show", FlareDraw)
	hooksecurefunc(flare, "Hide", FlareHidden)
	for _, section in ipairs({ flare.Left, flare.Right }) do
		section:HookScript("OnLeave", function(self) -- FlareUI hides the text there
			if self.info == PET and ns.db.petxp.alwaysText then self.Text:Show() end
		end)
	end
end

-------------------------------------------------------------------------------
-- The game's bars
-------------------------------------------------------------------------------

-- Without data the last values stay: in combat the bar can only be taken away afterwards.
local function Update()
	if flare then return FlareDraw() end
	local cur, max, level = Data()
	if not bar or not cur then return end
	bar:SetBarValues(math.min(cur, max), 0, max)
	bar:SetBarText(Text(cur, max, level))
	bar:UpdateTextVisibility()
end

-- Same margins as the game's bars in their containers (StatusTrackingManagerOverrides.lua).
local function Resize()
	if not slot then return end
	local margin = STATUS_BAR_SIZE_ADJUSTMENT or 3
	local width, height = slot:GetWidth() - margin, slot:GetHeight() - margin
	bar:ClearAllPoints()
	bar:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 1, margin - 1)
	bar:SetSize(width, height)
	bar.StatusBar:SetSize(width, height)
end

-- Moves the bottom action bars to make room for a container that was shown or hidden. Out of combat only.
local function Restack()
	if not ACTION_BARS_RELATIVE_TO_BASE_POSITIONING then return end -- not Forever's layout
	local bars = EditModeUtil.GetBottomActionBars()
	local base = bars[1]
	if not base then return end -- gamepad layout
	local spacer = BOTTOM_ACTION_BARS_SPACER_Y
	local y = 0
	if base:IsShown() and not base:IsInDefaultPosition() then y = base:GetHeight() + spacer end
	for i, f in ipairs(bars) do
		if f:IsShown() and f:IsInDefaultPosition() then
			local anchor = EditModeManagerFrame:GetDefaultAnchor(f)
			if f ~= base and not f.skipAutomaticPositioning then
				f:ClearAllPointsBase()
				f:SetPointBase("BOTTOMLEFT", base, "BOTTOMLEFT", anchor and anchor.bottomBarOffsetX or 0, y)
			end
			if not (anchor and anchor.bottomBarExcludeFromStackIncrement) then
				local pair = f == SecondaryStatusTrackingBarContainer and bars[i + 1] == MainStatusTrackingBarContainer
				y = y + f:GetHeight() + (pair and PRIMARY_AND_SECONDARY_STATUS_TRACKING_BAR_SPACER_Y or spacer)
			end
		end
	end
	ManageFramePositions() -- dispatches to secure code
end

local function IsEmpty(c)
	return c.shownBarIndex == StatusTrackingBarInfo.BarsEnum.None
end

-- the container to use, and the game's bar to hide in it
local function FindSlot()
	if slot and IsEmpty(slot) then return slot end
	for _, c in ipairs(containers) do
		if IsEmpty(c) then return c end
	end
	if not ns.db.petxp.cover then return nil end
	for _, c in ipairs(containers) do
		if c.shownBarIndex == StatusTrackingBarInfo.BarsEnum.Reputation then return c, c:GetShownBar() end
	end
end

local function IsFading(c)
	return c.pendingBarToShowIndex ~= nil or c.FadeInAnimation:IsPlaying() or c.FadeOutAnimation:IsPlaying()
		or c.MaxLevelFadeOutAnimation:IsPlaying()
end

local releasing = false
local hides = 0 -- times something else hid the slot in use; an addon that replaces the game's bars keeps doing it

local function Place(newSlot, newCovered)
	if covered and covered ~= newCovered then covered:SetAlpha(1) end
	local moved = false
	if slot and slot ~= newSlot and IsEmpty(slot) and slot:IsShown() then
		releasing = true
		slot:HideBase()
		releasing = false
		slot:SetAlpha(0)
		moved = true
	end
	slot, covered = newSlot, newCovered
	if slot then
		if covered then
			covered:SetAlpha(0)
		elseif not slot:IsShown() or slot:GetAlpha() < 1 then
			slot:Show()
			slot:SetAlpha(1)
			moved = true
		end
		bar:SetParent(slot)
		bar:SetFrameLevel(slot:GetFrameLevel() + 10) -- takes the mouse from a covered bar
		Resize()
		Update()
		bar:Show()
	else
		bar:Hide()
	end
	if moved then Restack() end
end

local EvaluateSoon

local function Evaluate()
	if not flare then FindFlare() end
	if flare then
		if bar and slot and not InCombatLockdown() then Place(nil) end
		local has = Data() ~= nil
		if has ~= hadData then
			hadData = has
			FlareUI.XPBar:Refresh() -- draws without the pet; FlareDraw puts it in
		end
		return
	end
	if not bar or InCombatLockdown() then return end -- again on PLAYER_REGEN_ENABLED
	if EditModeManagerFrame:IsEditModeActive() then return end -- again on EditMode.Exit
	if not EditModeManagerFrame:IsInitialized() then return EvaluateSoon() end
	for _, c in ipairs(containers) do
		if IsFading(c) then return EvaluateSoon() end
	end
	if hides < 5 and Data() then
		Place(FindSlot())
	else
		Place(nil)
	end
end

-- the game's bars take half a second to fade; look again once they settled
local pending
function EvaluateSoon()
	if pending then return end
	pending = true
	C_Timer.After(0.3, function()
		pending = nil
		Evaluate()
	end)
end

local function CreateBar()
	containers = { MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }
	if #containers < 2 or not StatusTrackingBarInfo or not EditModeManagerFrame then return end

	bar = CreateFrame("Frame", "ForeverQuiverPetXP", containers[1], "StatusTrackingBarTemplate")
	bar:Hide()
	local shouldShow = bar.ShouldBarTextBeDisplayed
	function bar:ShouldBarTextBeDisplayed()
		return ns.db.petxp.alwaysText or shouldShow(self)
	end
	bar:SetScript("OnEnter", bar.ShowText)
	bar:SetScript("OnLeave", bar.HideText)

	for _, c in ipairs(containers) do
		hooksecurefunc(c, "ApplyPendingBarToShow", EvaluateSoon) -- the game put another bar in this slot
		c:HookScript("OnShow", EvaluateSoon)
		c:HookScript("OnHide", function()
			if c == slot and not releasing and IsEmpty(c) and not c:IsShown() then hides = hides + 1 end
			EvaluateSoon()
		end)
		c:HookScript("OnSizeChanged", function() if c == slot then Resize() end end)
	end
	EventRegistry:RegisterCallback("EditMode.Exit", EvaluateSoon, M)
end

function M:Init()
	if not ns.IsHunter() then return end
	FindFlare()
	if not flare then CreateBar() end

	local events = CreateFrame("Frame")
	events:RegisterEvent("PLAYER_ENTERING_WORLD")
	events:RegisterEvent("PLAYER_REGEN_ENABLED")
	events:RegisterEvent("UNIT_PET_EXPERIENCE")
	events:RegisterUnitEvent("UNIT_PET", "player")
	events:RegisterUnitEvent("UNIT_LEVEL", "pet")
	events:RegisterEvent("CVAR_UPDATE")
	events:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_ENTERING_WORLD" then hides = 0 end
		Update()
		if event ~= "CVAR_UPDATE" then EvaluateSoon() end
	end)
	self.ready = true
	self:Refresh()
end

function M:Refresh()
	if not self.ready then return end
	if flare then
		hadData = Data() ~= nil
		FlareUI.XPBar:Refresh()
		return
	end
	if not bar then return end
	hides = 0
	bar.StatusBar:SetBarTexture(FILL[ns.db.petxp.fill] or FILL.HONOR)
	Update()
	bar:UpdateTextVisibility()
	EvaluateSoon()
end
