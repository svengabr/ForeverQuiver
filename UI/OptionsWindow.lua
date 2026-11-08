-- Forever Quiver's options window: sections in a sidebar on the left, the selected section's controls on the right
-- in two columns (layout as in KeepOrSell). Every control writes ns.db at once and refreshes the modules.
local ADDON, ns = ...
local L = ns.L
local Style = ns.Style

local WIDTH, HEIGHT = 760, 486
local NAV_W, PANEL_TOP, MARGIN = 190, -30, 12
local PANEL_H = HEIGHT + PANEL_TOP - MARGIN
local CONTENT_W = WIDTH - 3 * MARGIN - NAV_W
local PAGE_W, PAGE_H = CONTENT_W - 2 * MARGIN, PANEL_H - 2 * MARGIN
local COLUMN_TOP = 40
local COLUMN_W = (PAGE_W - MARGIN) / 2

local frame
local sections
local pages, navButtons, widgets = {}, {}, {}

local function Changed()
	ns.RefreshAll()
	for _, w in ipairs(widgets) do w.Refresh() end
end

local function ShowTip(owner, title, text)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(title)
	if text and text ~= "" then GameTooltip:AddLine(text, 1, 1, 1, true) end
	GameTooltip:Show()
end

local function Tip(region, control)
	if not control.tip then return end
	region:SetScript("OnEnter", function(self) ShowTip(self, control.label, control.tip) end)
	region:SetScript("OnLeave", GameTooltip_Hide)
end

local function Round(value, step)
	return math.floor(value / step + 0.5) * step
end

-- Controls ------------------------------------------------------------------------------------------------------

local function Check(parent, c, y)
	local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	box:SetSize(24, 24)
	box:SetPoint("TOPLEFT", 0, y)
	box.label = box:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	box.label:SetPoint("LEFT", box, "RIGHT", 2, 0)
	box.label:SetWidth(COLUMN_W - 30)
	box.label:SetJustifyH("LEFT")
	box.label:SetText(c.label)
	box:SetScript("OnClick", function(self)
		ns.db[c.sec][c.key] = self:GetChecked() and true or false
		Changed()
	end)
	Tip(box, c)
	box.Refresh = function() box:SetChecked(ns.db[c.sec][c.key] == true) end
	return box, 30
end

local function Slider(parent, c, y)
	local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOPLEFT", 4, y)
	title:SetText(c.label)
	local slider = CreateFrame("Slider", nil, parent)
	slider:SetOrientation("HORIZONTAL")
	slider:SetSize(COLUMN_W - 70, 16)
	slider:SetPoint("TOPLEFT", 4, y - 18)
	slider:SetHitRectInsets(0, 0, -6, -6)
	local track = slider:CreateTexture(nil, "BACKGROUND")
	track:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
	track:SetPoint("TOPLEFT", 0, -3)
	track:SetPoint("BOTTOMRIGHT", 0, 3)
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetMinMaxValues(c.min, c.max)
	slider:SetValueStep(c.step)
	slider:SetObeyStepOnDrag(true)
	slider.label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	slider.label:SetPoint("LEFT", slider, "RIGHT", 8, 0)
	local format = c.format or tostring
	slider:SetScript("OnValueChanged", function(self, value, userInput)
		value = Round(value, c.step)
		self.label:SetText(format(value))
		if not userInput then return end
		ns.db[c.sec][c.key] = value
		ns.RefreshAll()
	end)
	Tip(slider, c)
	slider.Refresh = function()
		local v = ns.db[c.sec][c.key] or c.min
		slider:SetValue(v)
		slider.label:SetText(format(Round(v, c.step)))
	end
	return slider, 48
end

local function SetColor(c, r, g, b)
	ns.db[c.sec][c.key] = { r, g, b }
	Changed()
end

local function Color(parent, c, y)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(COLUMN_W, 24)
	row:SetPoint("TOPLEFT", 0, y)
	local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	label:SetPoint("LEFT", 4, 0)
	label:SetText(c.label)
	-- reset to the default colour
	local reset = CreateFrame("Button", nil, row)
	reset:SetSize(18, 18)
	reset:SetPoint("RIGHT", -4, 0)
	reset:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
	reset:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	reset:SetScript("OnClick", function()
		local d = ns.defaults[c.sec][c.key]
		SetColor(c, d[1], d[2], d[3])
	end)
	reset:SetScript("OnEnter", function(self) ShowTip(self, L["Reset to default"]) end)
	reset:SetScript("OnLeave", GameTooltip_Hide)
	local swatch = CreateFrame("Button", nil, row)
	swatch:SetSize(48, 18)
	swatch:SetPoint("RIGHT", reset, "LEFT", -6, 0)
	local border = swatch:CreateTexture(nil, "BACKGROUND")
	border:SetAllPoints()
	border:SetColorTexture(0.8, 0.8, 0.8, 1)
	swatch.fill = swatch:CreateTexture(nil, "ARTWORK")
	swatch.fill:SetPoint("TOPLEFT", 1, -1)
	swatch.fill:SetPoint("BOTTOMRIGHT", -1, 1)
	swatch:SetScript("OnClick", function()
		local cur = ns.db[c.sec][c.key]
		local pr, pg, pb = cur[1], cur[2], cur[3]
		ColorPickerFrame:SetupColorPickerAndShow({
			r = pr, g = pg, b = pb,
			hasOpacity = false,
			swatchFunc = function() SetColor(c, ColorPickerFrame:GetColorRGB()) end,
			cancelFunc = function() SetColor(c, pr, pg, pb) end,
		})
	end)
	row.Refresh = function()
		local cur = ns.db[c.sec][c.key]
		swatch.fill:SetColorTexture(cur[1], cur[2], cur[3], 1)
	end
	return row, 28
end

-- A button that cycles through the choices; the label above names the option
local function Select(parent, c, y)
	local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOPLEFT", 4, y)
	title:SetText(c.label)
	local button = Style.Button(parent, "", nil)
	button:SetPoint("TOPLEFT", 4, y - 18)
	button:SetWidth(180)
	button:SetScript("OnClick", function()
		local idx = 1
		for i, choice in ipairs(c.choices) do
			if choice[1] == ns.db[c.sec][c.key] then idx = i end
		end
		ns.db[c.sec][c.key] = c.choices[idx % #c.choices + 1][1]
		Changed()
	end)
	Tip(button, c)
	button.Refresh = function()
		button:SetText(c.choices[1][2])
		for _, choice in ipairs(c.choices) do
			if choice[1] == ns.db[c.sec][c.key] then button:SetText(choice[2]) end
		end
	end
	return button, 50
end

local function Text(parent, c, y)
	local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOPLEFT", 4, y)
	title:SetText(c.label)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(COLUMN_W - 16, 20)
	box:SetPoint("TOPLEFT", 10, y - 18)
	box:SetAutoFocus(false)
	box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	box:SetScript("OnEscapePressed", function(self)
		self:SetText(ns.db[c.sec][c.key] or "")
		self:ClearFocus()
	end)
	box:SetScript("OnEditFocusLost", function(self) ns.db[c.sec][c.key] = self:GetText() end)
	Tip(box, c)
	box.Refresh = function()
		if not box:HasFocus() then box:SetText(ns.db[c.sec][c.key] or "") end
	end
	return box, 50
end

local function ActionButton(parent, c, y)
	local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOPLEFT", 4, y)
	title:SetText(c.label)
	local button = Style.Button(parent, "", function()
		c.action()
		Changed()
	end)
	button:SetPoint("TOPLEFT", 4, y - 18)
	button:SetWidth(180)
	Tip(button, c)
	button.Refresh = function()
		button:SetText(type(c.text) == "function" and c.text() or c.text)
	end
	return button, 50
end

local function Note(parent, c, y)
	local text = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", 4, y)
	text:SetWidth(COLUMN_W - 8)
	text:SetJustifyH("LEFT")
	text:SetText(c.text)
	text.Refresh = function() end
	return text, text:GetStringHeight() + 12
end

local BUILDERS = { check = Check, slider = Slider, color = Color, select = Select, text = Text,
	button = ActionButton, note = Note }

-- Pages and sidebar ---------------------------------------------------------------------------------------------

local function BuildPage(parent, section)
	local page = CreateFrame("Frame", nil, parent)
	page:SetSize(PAGE_W, PAGE_H)
	page:SetPoint("TOPLEFT", MARGIN, -MARGIN)
	Style.Heading(page, section.label, 20, 0)
	for i, controls in ipairs(section.columns) do
		local column = CreateFrame("Frame", nil, page)
		column:SetSize(COLUMN_W, PAGE_H - COLUMN_TOP)
		column:SetPoint("TOPLEFT", (i - 1) * (COLUMN_W + MARGIN), -COLUMN_TOP)
		local y = 0
		for _, control in ipairs(controls) do
			local widget, height = BUILDERS[control.kind](column, control, y)
			widgets[#widgets + 1] = widget
			y = y - height
		end
	end
	page:Hide()
	return page
end

local function SelectSection(id)
	if not pages[id] then id = sections[1].id end
	ns.db.optionsSection = id
	for key, page in pairs(pages) do page:SetShown(key == id) end
	for key, button in pairs(navButtons) do button.selected:SetShown(key == id) end
end

local function NavButton(parent, section, index)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(NAV_W - 16, 30)
	button:SetPoint("TOPLEFT", 8, -8 - (index - 1) * 34)
	button.selected = button:CreateTexture(nil, "BACKGROUND")
	button.selected:SetAllPoints()
	button.selected:SetColorTexture(Style.GOLD[1], Style.GOLD[2], Style.GOLD[3], 0.25)
	button.selected:Hide()
	button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(22, 22)
	icon:SetPoint("LEFT", 4, 0)
	icon:SetTexture(Style.ICONS .. section.icon)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
	text:SetWidth(NAV_W - 50)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	text:SetText(section.label)
	button:SetScript("OnClick", function() SelectSection(section.id) end)
	navButtons[section.id] = button
end

local function Refresh()
	for _, w in ipairs(widgets) do w.Refresh() end
end

local function CreateWindow()
	frame = Style.Window(ADDON .. "OptionsFrame", "Forever Quiver", WIDTH, HEIGHT)
	local nav = Style.Box(frame, 0.08, 0.7)
	nav:SetSize(NAV_W, PANEL_H)
	nav:SetPoint("TOPLEFT", MARGIN, PANEL_TOP)
	local content = Style.Box(frame, 0.08, 0.7)
	content:SetSize(CONTENT_W, PANEL_H)
	content:SetPoint("TOPRIGHT", -MARGIN, PANEL_TOP)
	sections = ns.BuildOptionSections()
	for i, section in ipairs(sections) do
		NavButton(nav, section, i)
		pages[section.id] = BuildPage(content, section)
	end
	frame:SetScript("OnShow", Refresh)
end

function ns.OpenOptions(id)
	if not frame then CreateWindow() end
	SelectSection(id or ns.db.optionsSection)
	frame:Show()
	Refresh()
end

function ns.ToggleOptions()
	if frame and frame:IsShown() then frame:Hide() else ns.OpenOptions() end
end

-- Entry under Esc > Options > AddOns: one button that opens the window (as in KeepOrSell). No search tags: a tag
-- table added from addon code is tainted and Blizzard's settings search reads it on every keystroke.
local function RegisterSettingsEntry()
	if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnCategory) then return end
	local category, layout = Settings.RegisterVerticalLayoutCategory("Forever Quiver")
	if layout and CreateSettingsButtonInitializer then
		layout:AddInitializer(CreateSettingsButtonInitializer(L["Options"], L["Open options window"],
			function() ns.OpenOptions() end, nil, false))
	end
	Settings.RegisterAddOnCategory(category)
end
RegisterSettingsEntry()
