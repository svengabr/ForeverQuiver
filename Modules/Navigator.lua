-- Quest arrow. Questie already sends waypoints to TomTom (Ctrl-click a map icon or a tracker quest). When
-- TomTom is not installed, this module answers those calls with a minimal TomTom stand-in: it shows its own
-- arrow and, if allowed, sets the game's map pin with super tracking.
local _, ns = ...
local L = ns.L

local Nav = ns.RegisterModule("Navigator", {})
ns.Nav = Nav

local target -- { mapID, x, y, title = ..., from = ... } (TomTom's waypoint shape, which Questie compares)
local frame, arrow, title, dist
local ARRIVE_YARDS = 6

local function WorldPos(mapID, x, y)
	if not (C_Map and C_Map.GetWorldPosFromMapPos) then return nil end
	local cont, pos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
	if not pos then return nil end
	return cont, pos:GetXY()
end

local function PlayerWorldPos()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return nil end
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then return nil end
	local px, py = pos:GetXY()
	if ns.IsSecret(px) then return nil end
	return WorldPos(mapID, px, py)
end

local function SetNativePin(mapID, x, y)
	if not (ns.db.nav.native and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(mapID)) then return end
	C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
	if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
		C_SuperTrack.SetSuperTrackedUserWaypoint(true)
	end
end

function Nav:Set(mapID, x, y, opts)
	if not (mapID and x and y) then return nil end
	target = { mapID, x, y, title = opts and opts.title, from = opts and opts.from }
	if ns.db.nav.enabled then
		SetNativePin(mapID, x, y)
		self:Refresh()
	end
	return target
end

local function SameWaypoint(a, b)
	return a == b or (a and b and a[1] == b[1] and a[2] == b[2] and a[3] == b[3])
end

function Nav:Clear(wp)
	if wp and not SameWaypoint(wp, target) then return end
	target = nil
	if ns.db.nav.native and C_Map.ClearUserWaypoint and C_Map.HasUserWaypoint and C_Map.HasUserWaypoint() then
		C_Map.ClearUserWaypoint()
	end
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

local elapsed = 0
local function OnUpdate(_, dt)
	elapsed = elapsed + dt
	if elapsed < 0.05 or not target then return end
	elapsed = 0
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
		Nav:Clear()
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
		GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
		GameTooltip:SetText(target and target.title or L["Quest arrow"])
		GameTooltip:AddLine(L["Right-click to clear"], 1, 1, 1)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", GameTooltip_Hide)
	ns.MakeMovable(frame, "arrow", L["Quest arrow"], { "TOP", "TOP", 0, -120 })
	frame:SetScript("OnUpdate", OnUpdate)
	self:Refresh()
end

function Nav:Refresh()
	if not frame then return end
	local db = ns.db.nav
	local show = db.enabled and db.arrow and (target ~= nil or not ns.db.locked)
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
