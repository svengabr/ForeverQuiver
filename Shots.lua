-- /fq shots: takes the reference screenshots for the gallery. Nobody has a fight at hand in which the Auto Shot
-- timer, an Aimed Shot cast, three hunters' Tranq cooldowns and a low quiver all show at once, so the pictures use
-- the simulation (/fq demo) with its clock stopped: every display is frozen at one made-up moment and looks the
-- same in every picture. The player's name is made up too, and other players' names are hidden. For the world picture the rest of the interface is
-- hidden, like with Alt-Z. The game names a screenshot after the second it was taken in, so the pictures are two
-- seconds apart. /fq shots demo shows the same frozen simulation for pictures taken by hand.
local _, ns = ...
local L = ns.L

-- The moment each display is frozen at, as a value of the simulation clock (ns.DemoClock in Core.lua).
local FREEZE = {
	autoShot = 1.0, -- reloading, 1.5 s to go
	castbar = 1.2,  -- Aimed Shot, 1.8 s to go
	range = 7.6,    -- "Long Range"
	trueshot = 22,  -- Trueshot Aura runs out in 37 s
	tranq = 26,     -- own Tranq Shot ready in 14 s, the second hunter's in 4 s, the third is ready
	nav = 0.6,      -- arrow up and to the left, 135 yd
	name = "Sylvara Dawnwhisper",
	navTitle = L["Taming the Beast"],
}

local OPTIONS = "ForeverQuiverOptionsFrame"

local saved -- [frame] = { strata, level } of every display while pictures are taken

-- The display frames the addon may reparent: the secure menu buttons stay where they are.
local function Displays()
	local list = {}
	for _, frame in pairs(ns.movers) do
		if not frame:IsProtected() then list[#list + 1] = frame end
	end
	return list
end

local function Freeze(on)
	ns.demoFreeze = on and FREEZE or nil
	ns.SetDemo(on) -- clears demoFreeze when switched off
	if on then ns.demoFreeze = FREEZE end
	ns.RefreshAll()
end

function ns.ToggleShotsDemo()
	local on = not (ns.demo and ns.demoFreeze)
	Freeze(on)
	ns.Print("shots: frozen simulation " .. (on and "on" or "off"))
end

local function Remember()
	saved = {}
	for _, frame in ipairs(Displays()) do
		saved[frame] = { frame:GetFrameStrata(), frame:GetFrameLevel() }
	end
end

local function RestoreLayers()
	if not saved then return end
	for frame, layer in pairs(saved) do
		frame:SetFrameStrata(layer[1])
		frame:SetFrameLevel(layer[2])
	end
end

-- Hides the whole interface except the addon's displays, like Alt-Z, so the world picture shows no other addon.
-- The displays leave UIParent for that time and take its scale along.
local function HideInterface(hide)
	for _, frame in ipairs(Displays()) do
		if hide then
			frame:SetParent(nil)
			frame:SetScale(UIParent:GetEffectiveScale())
		else
			frame:SetParent(UIParent)
			frame:SetScale(1)
		end
	end
	RestoreLayers() -- a new parent hands down its own strata
	if hide then pcall(UIParent.Hide, UIParent) else pcall(UIParent.Show, UIParent) end
	ns.RefreshAll()
end

-- Names over players' heads belong to the game world and stay when the interface is hidden. For the world picture
-- they are switched off, so no other player's name ends up in the gallery, and put back right after. Only the
-- name cvars: the nameplate ones can't be changed in combat, and a run that combat stops must still clean up.
local NAME_CVARS = { "UnitNameOwn", "UnitNameFriendlyPlayerName", "UnitNameEnemyPlayerName",
	"UnitNameFriendlyPetName", "UnitNameEnemyPetName" }
local names -- [cvar] = the player's value while the names are hidden

local function HideNames(hide)
	if not (C_CVar and C_CVar.GetCVar and C_CVar.SetCVar) then return end
	if hide then
		if names then return end
		names = {}
		for _, cvar in ipairs(NAME_CVARS) do
			local value = C_CVar.GetCVar(cvar) -- nil for a cvar this client doesn't have
			if value ~= nil then
				names[cvar] = value
				C_CVar.SetCVar(cvar, "0")
			end
		end
	elseif names then
		for cvar, value in pairs(names) do C_CVar.SetCVar(cvar, value) end
		names = nil
	end
end

-- A plain dark sheet over the whole screen. With `raise` the displays sit on top of it and show alone; without,
-- they stay behind it and only the options window (strata DIALOG, raised above the sheet) is in the picture.
local backdrop
local function Backdrop(on, raise)
	RestoreLayers()
	if not on then
		if backdrop then backdrop:Hide() end
		return
	end
	if not backdrop then
		backdrop = CreateFrame("Frame", nil, UIParent)
		backdrop:SetAllPoints(UIParent)
		backdrop.Fill = backdrop:CreateTexture(nil, "BACKGROUND")
		-- beyond UIParent's edges too (an ultrawide screen, a UI scale that leaves a margin)
		backdrop.Fill:SetPoint("TOPLEFT", -2000, 2000)
		backdrop.Fill:SetPoint("BOTTOMRIGHT", 2000, -2000)
		backdrop.Fill:SetColorTexture(0.07, 0.07, 0.08, 1)
		backdrop:EnableMouse(true) -- nothing behind it lights up under the mouse
	end
	backdrop:SetFrameStrata("DIALOG")
	backdrop:SetFrameLevel(0)
	backdrop:Show()
	if raise then
		for _, frame in ipairs(Displays()) do
			frame:SetFrameStrata("DIALOG")
			frame:SetFrameLevel(20)
		end
	end
end

local function Options(section)
	local window = rawget(_G, OPTIONS)
	if not section then
		if window then window:Hide() end
		return
	end
	ns.OpenOptions(section)
	window = rawget(_G, OPTIONS)
	if window then
		window:SetFrameLevel(40) -- above the sheet
		window:Raise()
	end
end

-- name of the picture, then what shows it
local SHOTS = {
	-- the displays in the game world, wherever the player stands, with the rest of the interface hidden
	{ "01-world", function()
		Options(nil)
		Backdrop(false)
		HideNames(true)
		HideInterface(true)
	end },
	-- the displays alone on the dark sheet
	{ "02-displays", function()
		HideNames(false)
		HideInterface(false)
		Backdrop(true, true)
	end },
	-- the options window, two of its sections
	{ "03-options-general", function()
		Backdrop(true, false)
		Options("general")
	end },
	{ "04-options-autoshot", function()
		Options("autoShot")
	end },
	{ "05-options-range", function()
		Options("range")
	end },
}

local STEP = 2 -- seconds per picture: shown, one second to settle, the picture, one second to the next
local running

local function Finish(state)
	running = nil
	if state.status and state.status.RegisterEvent then state.status:RegisterEvent("SCREENSHOT_SUCCEEDED") end
	pcall(HideNames, false) -- first: the player's own settings
	pcall(HideInterface, false) -- in case a step failed in between
	pcall(Backdrop, false)
	saved = nil
	ns.db.optionsSection = state.section
	pcall(Options, state.hadOptions and (state.section or "general") or nil)
	Freeze(false)
	ns.SetLocked(state.locked)
end

function ns.TakeShots()
	local shoot = rawget(_G, "Screenshot")
	if running then return end
	if not shoot then return ns.Print("shots: this client has no Screenshot()") end
	if not ns.IsHunter() then return ns.Print("shots: the displays only exist on a hunter.") end
	-- hiding the interface is not allowed in combat, and combat ends the simulation
	if InCombatLockdown() then return ns.Print("shots: leave combat first.") end
	local window = rawget(_G, OPTIONS)
	local state = {
		locked = ns.db.locked,
		section = ns.db.optionsSection,
		hadOptions = window and window:IsShown() or false,
		-- the "screen captured" line of one picture would be in the next one
		status = rawget(_G, "ActionStatus"),
	}
	running = state
	if state.status and state.status.UnregisterEvent then state.status:UnregisterEvent("SCREENSHOT_SUCCEEDED") end
	ns.Print(("shots: %d pictures, about %d seconds. Leave mouse and keyboard alone."):format(#SHOTS, #SHOTS * STEP))
	ns.SetLocked(true) -- no green boxes in the pictures
	Freeze(true)
	Remember()
	for index, shot in ipairs(SHOTS) do
		C_Timer.After((index - 1) * STEP, function()
			if running ~= state then return end
			local ok, err = pcall(shot[2])
			if not ok then ns.Print("shots: " .. shot[1] .. " failed: " .. tostring(err)) end
			GameTooltip:Hide()
		end)
		C_Timer.After((index - 1) * STEP + 1, function()
			if running ~= state then return end
			GameTooltip:Hide() -- of whatever the resting mouse is on
			pcall(shoot)
		end)
	end
	C_Timer.After(#SHOTS * STEP, function()
		if running ~= state then return end
		Finish(state)
		ns.Print("shots: done. The pictures are in the game's Screenshots folder, in this order: "
			.. "world, displays, options (General, Auto Shot timer, Range indicator).")
	end)
end

-- Combat ends the simulation (Core.lua); a run that is under way stops with it and puts the interface back.
local watch = CreateFrame("Frame")
watch:RegisterEvent("PLAYER_REGEN_DISABLED")
watch:SetScript("OnEvent", function()
	if not running then return end
	Finish(running)
	ns.Print("shots: stopped (combat).")
end)
