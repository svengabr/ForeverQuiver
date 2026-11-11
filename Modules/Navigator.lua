-- Quest arrow. By default it always points at the nearest open objective of every quest in the log (the turn-in
-- NPC once a quest is complete), using Questie's own data and distance code. With TomTom installed the target
-- goes to TomTom and its arrow shows; otherwise this module draws its own arrow and, if allowed, sets the game's
-- map pin. A target set by hand (Ctrl-click a Questie map icon or tracker quest, /fq way) wins until it is
-- reached or cleared; for that, without TomTom, a minimal TomTom stand-in answers Questie's calls.
local _, ns = ...
local L = ns.L

local Nav = ns.RegisterModule("Navigator", {})
ns.Nav = Nav

-- waypoints use TomTom's shape { mapID, x, y, title = ..., from = ... }, which Questie compares
local manual, auto
local frame, arrow, title, dist
local ARRIVE_YARDS = 6
local AUTO_INTERVAL = 2
local pinned -- the waypoint the game's map pin was last set to
local tomtomWaypoint -- the waypoint handed to the real TomTom

local function Target() return manual or auto end

local function RealTomTom()
	return TomTom and not TomTom.isForeverQuiverShim and TomTom.AddWaypoint and true or false
end

local function SameWaypoint(a, b)
	return a == b or (a and b and a[1] == b[1] and a[2] == b[2] and a[3] == b[3]) or false
end

local function WorldPos(mapID, x, y)
	if not (C_Map and C_Map.GetWorldPosFromMapPos) then return nil end
	local cont, pos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
	if not pos then return nil end
	local wx, wy = pos:GetXY()
	cont, wx, wy = ns.Plain(cont), ns.Plain(wx), ns.Plain(wy)
	if not (cont and wx and wy) then return nil end
	return cont, wx, wy
end

local function PlayerWorldPos()
	local mapID = ns.Plain(C_Map.GetBestMapForUnit("player"))
	if not mapID then return nil end
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then return nil end
	local px, py = pos:GetXY()
	px, py = ns.Plain(px), ns.Plain(py)
	if not (px and py) then return nil end
	return WorldPos(mapID, px, py)
end

local function SetNativePin(wp)
	if not (ns.db.nav.native and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(wp[1])) then return end
	C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(wp[1], wp[2], wp[3]))
	if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
		C_SuperTrack.SetSuperTrackedUserWaypoint(true)
	end
end

local function ClearNativePin()
	if ns.db.nav.native and C_Map.ClearUserWaypoint and C_Map.HasUserWaypoint and C_Map.HasUserWaypoint() then
		C_Map.ClearUserWaypoint()
	end
end

-- Hands the current target to TomTom or to the game's map pin, but only when it changed
local function Publish()
	local wp = ns.db.nav.enabled and Target() or nil
	if RealTomTom() then
		if SameWaypoint(wp, tomtomWaypoint) then return end
		if tomtomWaypoint and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, tomtomWaypoint) end
		tomtomWaypoint = nil
		-- a hand-set target already sits in TomTom (Questie put it there); only the automatic one is ours
		if wp and wp == auto then
			local ok, res = pcall(TomTom.AddWaypoint, TomTom, wp[1], wp[2], wp[3],
				{ title = wp.title, crazy = true, persistent = false, silent = true, from = "ForeverQuiver" })
			if ok then tomtomWaypoint = res end
		end
		return
	end
	if SameWaypoint(wp, pinned) then return end
	pinned = wp
	if wp then SetNativePin(wp) else ClearNativePin() end
end

-------------------------------------------------------------------------------
-- Nearest objective from Questie
-------------------------------------------------------------------------------

local function QuestieModule(name)
	if not (QuestieLoader and QuestieLoader.ImportModule) then return nil end
	local ok, module = pcall(QuestieLoader.ImportModule, QuestieLoader, name)
	return ok and module or nil
end

-- The nearest open objective (or turn-in) over all quests in the log, as a waypoint, or nil
local function NearestObjective()
	if not (Questie and Questie.API and Questie.API.isReady) then return nil end
	local QuestieDB, DistanceUtils, ZoneDB = QuestieModule("QuestieDB"), QuestieModule("DistanceUtils"), QuestieModule("ZoneDB")
	if not (QuestieDB and QuestieDB.GetQuest and DistanceUtils and DistanceUtils.GetNearestSpawnForQuest
		and ZoneDB and ZoneDB.GetUiMapIdByAreaId) then
		return nil
	end
	local best
	for i = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(i)
		if info and not info.isHeader and not info.isHidden and info.questID and info.questID > 0 then
			local quest = QuestieDB.GetQuest(info.questID)
			if quest then
				local ok, spawn, zone, name, distance = pcall(DistanceUtils.GetNearestSpawnForQuest, quest)
				if ok and spawn and zone and distance and spawn[1] and spawn[1] >= 0
					and (not best or distance < best.distance) then
					best = { spawn = spawn, zone = zone, name = name, quest = info.title, distance = distance }
				end
			end
		end
	end
	if not best then return nil end
	local ok, mapID = pcall(ZoneDB.GetUiMapIdByAreaId, ZoneDB, best.zone)
	if not (ok and mapID) then return nil end
	local label = best.name and best.quest and (best.name .. " - " .. best.quest) or best.name or best.quest
	return { mapID, best.spawn[1] / 100, best.spawn[2] / 100, title = label, from = "ForeverQuiver" }
end

function Nav:UpdateAuto()
	local db = ns.db.nav
	local wp = db.enabled and db.auto and NearestObjective() or nil
	if SameWaypoint(wp, auto) and (not wp or wp.title == auto.title) then return end
	auto = wp
	Publish()
	self:Refresh()
end

-------------------------------------------------------------------------------
-- Hand-set targets (Questie Ctrl-click, /fq way)
-------------------------------------------------------------------------------

function Nav:Set(mapID, x, y, opts)
	if not (mapID and x and y) then return nil end
	manual = { mapID, x, y, title = opts and opts.title, from = opts and opts.from }
	Publish()
	self:Refresh()
	return manual
end

-- wp given: clear only if it is the current hand-set target. No wp: clear the hand-set target.
function Nav:Clear(wp)
	if wp and not SameWaypoint(wp, manual) then return end
	manual = nil
	Publish()
	self:Refresh()
end

function Nav:SlashWay(args)
	local x, y, rest = (args or ""):match("^([%d%.]+)[,%s]+([%d%.]+)%s*(.*)$")
	x, y = tonumber(x), tonumber(y)
	local mapID = C_Map.GetBestMapForUnit("player")
	if not (x and y and mapID) then
		ns.Print(L["Usage: /fq way <x> <y> [title]"])
		return
	end
	local label = rest ~= "" and rest or string.format("%.1f, %.1f", x, y)
	self:Set(mapID, x / 100, y / 100, { title = label, from = "ForeverQuiver" })
	ns.Print(string.format(L["Waypoint set: %s"], label))
end

-------------------------------------------------------------------------------
-- Own arrow
-------------------------------------------------------------------------------

local elapsed, autoElapsed = 0, AUTO_INTERVAL
local function OnUpdate(_, dt)
	autoElapsed = autoElapsed + dt
	if autoElapsed >= AUTO_INTERVAL then
		autoElapsed = 0
		Nav:UpdateAuto()
	end
	elapsed = elapsed + dt
	if elapsed < 0.05 then return end
	elapsed = 0
	local target = Target()
	if ns.demo and (not target or ns.demoFreeze) then
		-- simulation: a slowly circling target. In pictures (Shots.lua) it also replaces a real quest target.
		local now = ns.DemoClock("nav")
		title:SetText(ns.demoFreeze and ns.demoFreeze.navTitle or L["Demo target"])
		arrow:SetRotation(now % (2 * math.pi))
		arrow:Show()
		dist:SetFormattedText("%d yd", 120 + math.floor(80 * math.sin(now / 3)))
		return
	end
	if not target then return end
	title:SetText(target.title or "")
	local pc, px, py = PlayerWorldPos()
	local tc, tx, ty = WorldPos(target[1], target[2], target[3])
	if not (pc and tc) then
		arrow:Hide()
		dist:SetText("")
		return
	end
	if pc ~= tc then
		arrow:Hide()
		dist:SetText(L["Other continent"])
		return
	end
	-- world x points north, world y points west; facing 0 = north, counter-clockwise
	local dx, dy = tx - px, ty - py
	local yards = math.sqrt(dx * dx + dy * dy)
	if yards < ARRIVE_YARDS then
		dist:SetText(L["Arrived"])
		-- a hand-set target is done; the automatic one moves on by itself once the objective updates
		if target == manual then Nav:Clear() end
		return
	end
	local facing = GetPlayerFacing()
	if facing and not ns.IsSecret(facing) then
		arrow:SetRotation(math.atan2(dy, dx) - facing)
		arrow:Show()
	else
		arrow:Hide()
	end
	dist:SetFormattedText("%d yd", yards)
end

function Nav:Init()
	frame = CreateFrame("Frame", "ForeverQuiverArrow", UIParent)
	frame:SetSize(64, 64)
	arrow = frame:CreateTexture(nil, "ARTWORK")
	-- both textures point up; the game's navigation arrow first, the old minimap arrow as fallback
	if not (arrow.SetAtlas and arrow:SetAtlas("Navigation-Tracked-Arrow")) then
		arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
	end
	arrow:SetSize(40, 40)
	arrow:SetPoint("CENTER")
	title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", frame, "BOTTOM", 0, -2)
	dist = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	dist:SetPoint("TOP", title, "BOTTOM", 0, -2)
	frame:EnableMouse(true)
	frame:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then Nav:Clear() end
	end)
	frame:SetScript("OnEnter", function(owner)
		local target = Target()
		GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
		GameTooltip:SetText(target and target.title or L["Quest arrow"])
		if manual then GameTooltip:AddLine(L["Right-click to clear"], 1, 1, 1) end
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", GameTooltip_Hide)
	ns.MakeMovable(frame, "arrow", L["Quest arrow"], { "TOP", "TOP", 0, -200 })

	-- the target updates on a timer (the player moves) and right away when the quest log changes
	local driver = CreateFrame("Frame")
	driver:SetScript("OnUpdate", OnUpdate)
	driver:RegisterEvent("QUEST_LOG_UPDATE")
	driver:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	driver:RegisterEvent("PLAYER_ENTERING_WORLD")
	driver:SetScript("OnEvent", function() autoElapsed = AUTO_INTERVAL - 0.3 end)
	self:Refresh()
end

function Nav:Refresh()
	if not frame then return end
	local db = ns.db.nav
	if not (db.enabled and db.auto) and auto then
		auto = nil
		Publish()
	end
	local target = Target()
	-- with TomTom installed its own arrow shows the way
	local show = db.enabled and db.arrow and not RealTomTom() and (target ~= nil or ns.demo or not ns.db.locked)
	frame:SetShown(show)
	if not target then
		arrow:Show()
		arrow:SetRotation(0)
		title:SetText("")
		dist:SetText("")
	end
end

-- TomTom stand-in for Questie, only if the real TomTom is not going to load.
local function TomTomWillLoad()
	if not (C_AddOns and C_AddOns.GetAddOnEnableState) then return false end
	local state = C_AddOns.GetAddOnEnableState("TomTom", UnitName("player"))
	return state and state > 0 and C_AddOns.IsAddOnLoadable and C_AddOns.IsAddOnLoadable("TomTom") or false
end

if not TomTom and not TomTomWillLoad() then
	TomTom = {
		isForeverQuiverShim = true,
		AddWaypoint = function(_, mapID, x, y, opts) return Nav:Set(mapID, x, y, opts) end,
		RemoveWaypoint = function(_, wp) Nav:Clear(wp) end,
	}
end
