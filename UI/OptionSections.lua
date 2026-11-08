-- What the options window shows, as data: the sections of the sidebar and the controls in their two columns.
-- UI/OptionsWindow.lua only draws this. `sec`/`key` address ns.db[sec][key]; labels go through ns.L.
local _, ns = ...
local L = ns.L

local function Check(sec, key, label, tip)
	return { kind = "check", sec = sec, key = key, label = label, tip = tip }
end

local function Slider(sec, key, label, min, max, step, fmt)
	return { kind = "slider", sec = sec, key = key, label = label, min = min, max = max, step = step, format = fmt }
end

local function Color(sec, key, label)
	return { kind = "color", sec = sec, key = key, label = label }
end

local function Select(sec, key, label, choices, tip)
	return { kind = "select", sec = sec, key = key, label = label, choices = choices, tip = tip }
end

local function Text(sec, key, label, tip)
	return { kind = "text", sec = sec, key = key, label = label, tip = tip }
end

local function Button(label, text, action, tip)
	return { kind = "button", label = label, text = text, action = action, tip = tip }
end

local function Note(text)
	return { kind = "note", text = text }
end

local function Seconds(v) return string.format(L["%d s"], v) end
local function Pixels(v) return string.format("%d px", v) end

local function AspectChoices()
	local choices = { { "NONE", L["None"] } }
	for _, a in ipairs(ns.ASPECTS) do
		choices[#choices + 1] = { a[1], ns.SpellName(a[2]) or a[1] }
	end
	return choices
end

-- id, label, icon (Interface\Icons\...), { left column, right column }
function ns.BuildOptionSections()
	return {
		{ id = "general", label = L["General"], icon = "INV_Weapon_Bow_07", columns = {
			{
				Button(L["Frames"], function() return ns.db.locked and L["Unlock frames"] or L["Lock frames"] end,
					function() ns.SetLocked(not ns.db.locked) end,
					L["While unlocked, every frame shows a green box you can drag."]),
				Button(L["Positions"], L["Reset positions"], function() ns.ResetPositions() end),
				Button(L["Simulation"], function() return ns.demo and L["Stop simulation"] or L["Start simulation"] end,
					function() ns.SetDemo(not ns.demo) end,
					L["All displays show test data, so you can look at colours and sizes. Combat ends it. Also /fq demo."]),
			},
			{
				Note(L["Hunter utilities for WoW: Forever, inspired by Quiver (Turtle WoW)."]),
				Note(L["/fq opens this window, /fq lock and /fq unlock move frames, /fq debug prints range data."]),
			},
		} },
		{ id = "autoShot", label = L["Auto Shot timer"], icon = "Ability_Whirlwind", columns = {
			{
				Check("autoShot", "enabled", ENABLE),
				Check("autoShot", "showText", L["Show seconds"]),
				Select("autoShot", "direction", L["Bar direction"],
					{ { "LEFT", L["Left to right"] }, { "CENTER", L["Both sides"] } }),
				Slider("autoShot", "width", L["Width"], 60, 400, 10, Pixels),
				Slider("autoShot", "height", L["Height"], 3, 30, 1, Pixels),
			},
			{
				Note(L["Red = reloading, yellow = aiming (stand still)."]),
				Color("autoShot", "colorShoot", L["Shooting"]),
				Color("autoShot", "colorReload", L["Reloading"]),
				Button(L["Shoot / Reload"], L["Swap colours"], function()
					local db = ns.db.autoShot
					db.colorShoot, db.colorReload = db.colorReload, db.colorShoot
				end),
			},
		} },
		{ id = "castbar", label = L["Castbar"], icon = "INV_Spear_07", columns = {
			{
				Check("castbar", "enabled", ENABLE),
				Check("castbar", "onlyShots", L["Only hunter shots"],
					L["Aimed Shot, Multi-Shot and Steady Shot. Off: every cast with a cast time."]),
				Slider("castbar", "width", L["Width"], 60, 400, 10, Pixels),
				Slider("castbar", "height", L["Height"], 6, 30, 1, Pixels),
			},
			{
				Color("castbar", "color", L["Casting"]),
			},
		} },
		{ id = "range", label = L["Range indicator"], icon = "Ability_Hunter_SniperShot", columns = {
			{
				Check("range", "enabled", ENABLE),
				Slider("range", "width", L["Width"], 60, 300, 10, Pixels),
				Slider("range", "height", L["Height"], 12, 50, 1, Pixels),
			},
			{
				Color("range", "colorMelee", L["Melee Range"]),
				Color("range", "colorDead", L["Dead Zone"]),
				Color("range", "colorScare", L["Scare Beast"]),
				Color("range", "colorScatter", L["Scatter Shot"]),
				Color("range", "colorShort", L["Short Range"]),
				Color("range", "colorLong", L["Long Range"]),
				Color("range", "colorMark", L["Hunter's Mark"]),
				Color("range", "colorFar", L["Out of Range"]),
			},
		} },
		{ id = "aspect", label = L["Aspects & Trueshot"], icon = "Spell_Nature_RavenForm", columns = {
			{
				Check("aspect", "enabled", L["Aspect tracker"]),
				Select("aspect", "hideAspect", L["Hide while in"], AspectChoices()),
				Slider("aspect", "size", L["Size"], 20, 80, 2, Pixels),
			},
			{
				Check("trueshot", "enabled", L["Trueshot Aura alarm"]),
				Slider("trueshot", "threshold", L["Warn when less than"], 10, 600, 10, Seconds),
				Slider("trueshot", "size", L["Size"], 20, 80, 2, Pixels),
			},
		} },
		{ id = "tranq", label = L["Tranq Shot announcer"], icon = "Spell_Nature_Drowsy", columns = {
			{
				Check("tranq", "enabled", ENABLE),
				Select("tranq", "channel", L["Tranq speech"],
					{ { "NONE", L["None"] }, { "GROUP", L["Party / raid"] }, { "RAID_WARNING", L["Raid warning"] } },
					L["Raid warning needs raid lead or assist; otherwise it falls back to the raid channel."]),
				Check("tranq", "showBars", L["Show hunters' Tranq cooldowns"]),
			},
			{
				Text("tranq", "msgCast", L["Cast message"], L["%t is replaced with your target's name."]),
				Text("tranq", "msgMiss", L["Miss message"],
					L["Needs the combat log, which this client may keep from addons."]),
			},
		} },
		{ id = "ammo", label = L["Ammo warning"], icon = "INV_Ammo_Arrow_02", columns = {
			{
				Check("ammo", "enabled", ENABLE),
				Slider("ammo", "threshold", L["Warn below"], 0, 1000, 50),
				Check("ammo", "sound", L["Play sound"]),
			},
			{
				Note(L["Yellow below the threshold, red below a quarter of it."]),
			},
		} },
		{ id = "flyout", label = L["Spell menus"], icon = "Spell_Frost_ChainsOfIce", columns = {
			{
				Check("flyout", "enabled", ENABLE),
				Check("flyout", "traps", L["Traps"]),
				Check("flyout", "pet", L["Pet"]),
				Check("flyout", "aspects", L["Aspects"]),
			},
			{
				Check("flyout", "showAnchors", L["Show menu buttons on screen"]),
				Select("flyout", "direction", L["Menu opens"], { { "UP", L["Upwards"] }, { "RIGHT", L["To the right"] } }),
				Slider("flyout", "size", L["Size"], 20, 60, 2, Pixels),
				Note(L["Bind the keys under Key Bindings > Forever Quiver. While a menu is open, keys 1-9 cast its entries."]),
			},
		} },
		{ id = "beast", label = L["Beast abilities"], icon = "Ability_Hunter_BeastTaming", columns = {
			{
				Check("beast", "enabled", L["Beast ability tooltip"], L["Shows which pet ability a tameable beast teaches."]),
				Check("beast", "onlyUnknown", L["Only abilities you don't know yet"]),
				Check("beast", "allClasses", L["Also for other classes"]),
			},
			{},
		} },
		{ id = "nav", label = L["Quest arrow"], icon = "INV_Misc_Map_01", columns = {
			{
				Check("nav", "enabled", ENABLE),
				Check("nav", "arrow", L["Show arrow"]),
				Check("nav", "native", L["Also set the game's map pin"]),
			},
			{
				Note(L["Ctrl-click a Questie map icon or quest in the tracker to point the arrow there."]),
			},
		} },
	}
end
