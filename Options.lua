-- Options panel (Settings > AddOns > Forever Quiver), opened with /fq.
local _, ns = ...
local L = ns.L

local canvas = CreateFrame("Frame")
canvas.name = "Forever Quiver"
local scroll = CreateFrame("ScrollFrame", nil, canvas, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 0, -4)
scroll:SetPoint("BOTTOMRIGHT", -28, 4)
local panel = CreateFrame("Frame", nil, scroll)
panel:SetSize(640, 1600)
scroll:SetScrollChild(panel)

local syncers = {}
local y = -16

local function Apply()
	ns.RefreshAll()
end

local function Place(widget, x, height)
	widget:SetPoint("TOPLEFT", x or 16, y)
	y = y - (height or 26)
end

local function Header(text, note)
	y = y - 10
	local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	Place(fs, 16, 22)
	fs:SetText(text)
	if note then
		local n = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		n:SetWidth(580)
		n:SetJustifyH("LEFT")
		Place(n, 18, 16)
		n:SetText(note)
		y = y - math.max(0, n:GetStringHeight() - 12)
	end
end

local function Check(label, section, key, indent)
	local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	Place(cb, indent or 16, 26)
	cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	cb.text:SetText(label)
	cb:SetScript("OnClick", function(self)
		ns.db[section][key] = self:GetChecked() and true or false
		Apply()
	end)
	syncers[#syncers + 1] = function() cb:SetChecked(ns.db[section][key]) end
	return cb
end

local function Slider(label, section, key, minV, maxV, step, indent)
	local name = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	Place(name, (indent or 16) + 6, 20)
	name:SetText(label)
	local s = CreateFrame("Slider", nil, panel)
	s:SetOrientation("HORIZONTAL")
	s:SetSize(220, 16)
	s:SetPoint("LEFT", name, "LEFT", 200, 0)
	s:SetHitRectInsets(0, 0, -8, -8)
	local track = s:CreateTexture(nil, "BACKGROUND")
	track:SetColorTexture(0, 0, 0, 0.6)
	track:SetPoint("LEFT")
	track:SetPoint("RIGHT")
	track:SetHeight(4)
	s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	s:GetThumbTexture():SetSize(24, 24)
	s:SetMinMaxValues(minV, maxV)
	s:SetValueStep(step)
	s:SetObeyStepOnDrag(true)
	local value = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	value:SetPoint("LEFT", s, "RIGHT", 10, 0)
	local syncing = false
	s:SetScript("OnValueChanged", function(_, v)
		v = math.floor(v / step + 0.5) * step
		value:SetText(v)
		if syncing then return end
		ns.db[section][key] = v
		Apply()
	end)
	syncers[#syncers + 1] = function()
		syncing = true
		s:SetValue(ns.db[section][key])
		value:SetText(ns.db[section][key])
		syncing = false
	end
	y = y - 4
end

local function TextInput(label, section, key, indent)
	local name = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	Place(name, (indent or 16) + 6, 22)
	name:SetText(label)
	local eb = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	eb:SetSize(320, 20)
	eb:SetPoint("LEFT", name, "LEFT", 220, 0)
	eb:SetAutoFocus(false)
	eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	eb:SetScript("OnEscapePressed", function(self)
		self:SetText(ns.db[section][key] or "")
		self:ClearFocus()
	end)
	eb:SetScript("OnEditFocusLost", function(self) ns.db[section][key] = self:GetText() end)
	syncers[#syncers + 1] = function() eb:SetText(ns.db[section][key] or "") end
	y = y - 4
end

-- Cycles through a list of { value, label } on click.
local function Cycle(label, section, key, choices, indent)
	local name = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	Place(name, (indent or 16) + 6, 26)
	name:SetText(label)
	local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	b:SetSize(180, 22)
	b:SetPoint("LEFT", name, "LEFT", 200, 0)
	local function Sync()
		for _, c in ipairs(choices) do
			if c[1] == ns.db[section][key] then b:SetText(c[2]) end
		end
	end
	b:SetScript("OnClick", function()
		local idx = 1
		for i, c in ipairs(choices) do
			if c[1] == ns.db[section][key] then idx = i end
		end
		ns.db[section][key] = choices[idx % #choices + 1][1]
		Sync()
		Apply()
	end)
	syncers[#syncers + 1] = Sync
end

-------------------------------------------------------------------------------

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
Place(title, 16, 30)
title:SetText("Forever Quiver")
local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
Place(sub, 16, 30)
sub:SetText(L["Hunter utilities for WoW: Forever, inspired by Quiver (Turtle WoW)."])

local lockBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
lockBtn:SetSize(160, 24)
lockBtn:SetPoint("TOPLEFT", 16, y)
lockBtn:SetScript("OnClick", function()
	ns.SetLocked(not ns.db.locked)
	lockBtn:SetText(ns.db.locked and L["Unlock frames"] or L["Lock frames"])
end)
syncers[#syncers + 1] = function() lockBtn:SetText(ns.db.locked and L["Unlock frames"] or L["Lock frames"]) end
local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetSize(160, 24)
resetBtn:SetPoint("LEFT", lockBtn, "RIGHT", 8, 0)
resetBtn:SetText(L["Reset positions"])
resetBtn:SetScript("OnClick", function() ns.ResetPositions() end)
y = y - 34

Header(L["Auto Shot timer"], L["Red = reloading, yellow = aiming (stand still)."])
Check(ENABLE, "autoShot", "enabled")
Slider(L["Width"], "autoShot", "width", 60, 400, 10, 32)
Slider(L["Height"], "autoShot", "height", 3, 30, 1, 32)
Check(L["Show seconds"], "autoShot", "showText", 32)

Header(L["Castbar (Aimed Shot, Multi-Shot, Steady Shot)"])
Check(ENABLE, "castbar", "enabled")
Check(L["Only hunter shots"], "castbar", "onlyShots", 32)
Slider(L["Width"], "castbar", "width", 60, 400, 10, 32)
Slider(L["Height"], "castbar", "height", 6, 30, 1, 32)

Header(L["Range indicator"])
Check(ENABLE, "range", "enabled")
Slider(L["Width"], "range", "width", 60, 300, 10, 32)
Slider(L["Height"], "range", "height", 12, 50, 1, 32)

Header(L["Aspect tracker"])
Check(ENABLE, "aspect", "enabled")
do
	local choices = { { "NONE", L["None"] } }
	for _, a in ipairs(ns.ASPECTS) do
		choices[#choices + 1] = { a[1], ns.SpellName(a[2]) or a[1] }
	end
	Cycle(L["Hide while in"], "aspect", "hideAspect", choices, 32)
end
Slider(L["Size"], "aspect", "size", 20, 80, 2, 32)

Header(L["Trueshot Aura alarm"])
Check(ENABLE, "trueshot", "enabled")
Slider(L["Warn when less than (seconds)"], "trueshot", "threshold", 10, 600, 10, 32)
Slider(L["Size"], "trueshot", "size", 20, 80, 2, 32)

Header(L["Tranq Shot announcer"])
Check(ENABLE, "tranq", "enabled")
Check(L["Announce in party/raid"], "tranq", "announce", 32)
Check(L["Show hunters' Tranq cooldowns"], "tranq", "showBars", 32)
TextInput(L["Cast message (%t = target)"], "tranq", "msgCast", 32)
TextInput(L["Miss message"], "tranq", "msgMiss", 32)

Header(L["Ammo warning"])
Check(ENABLE, "ammo", "enabled")
Slider(L["Warn below"], "ammo", "threshold", 0, 1000, 50, 32)
Check(L["Play sound"], "ammo", "sound", 32)

Header(L["Spell menus (one key opens a drop-down)"],
	L["Bind the keys under Key Bindings > AddOns > Forever Quiver. While a menu is open, keys 1-9 cast its entries."])
Check(ENABLE, "flyout", "enabled")
Check(L["Traps"], "flyout", "traps", 32)
Check(L["Pet"], "flyout", "pet", 32)
Check(L["Aspects"], "flyout", "aspects", 32)
Check(L["Show menu buttons on screen"], "flyout", "showAnchors", 32)
Cycle(L["Open upwards"], "flyout", "direction", { { "UP", YES }, { "RIGHT", NO } }, 32)
Slider(L["Size"], "flyout", "size", 20, 60, 2, 32)
do
	local n = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	Place(n, 38, 18)
	n:SetText(L["Some changes to menus apply after combat."])
end

Header(L["Beast ability tooltip"], L["Shows which pet ability a tameable beast teaches."])
Check(ENABLE, "beast", "enabled")
Check(L["Only abilities you don't know yet"], "beast", "onlyUnknown", 32)
Check(L["Also for other classes"], "beast", "allClasses", 32)

Header(L["Quest arrow (Questie)"], L["Ctrl-click a Questie map icon or quest in the tracker to point the arrow there."])
Check(ENABLE, "nav", "enabled")
Check(L["Show arrow"], "nav", "arrow", 32)
Check(L["Also set the game's map pin"], "nav", "native", 32)

panel:SetHeight(-y + 40)

canvas:SetScript("OnShow", function()
	for _, s in ipairs(syncers) do s() end
end)

local category = Settings.RegisterCanvasLayoutCategory(canvas, canvas.name)
Settings.RegisterAddOnCategory(category)

function ns.OpenOptions()
	Settings.OpenToCategory(category:GetID())
end
