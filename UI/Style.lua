-- The look of Forever Quiver's options window, built from Blizzard's textures (atlases, Morpheus font); nothing is
-- shipped with the addon. Same style as the maintainer's KeepOrSell. A missing atlas falls back to a plain line.
local _, ns = ...

local Style = {}
ns.Style = Style

Style.ICONS = "Interface\\Icons\\"
Style.HEADER_FONT = "Fonts\\MORPHEUS.TTF"
Style.GOLD = { 0.79, 0.64, 0.29 }
Style.PARCHMENT = { 0.95, 0.89, 0.71 }
local GOLD, PARCHMENT, HEADER_FONT = Style.GOLD, Style.PARCHMENT, Style.HEADER_FONT

local BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- Dark box with a gold-tinted border, like the panels of the quest log
function Style.Box(parent, shade, border)
	local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	box:SetBackdrop(BACKDROP)
	box:SetBackdropColor(shade, shade * 0.85, shade * 0.6, 0.95)
	box:SetBackdropBorderColor(GOLD[1] * border, GOLD[2] * border, GOLD[3] * border)
	return box
end

function Style.SetAtlasOr(texture, atlas, r, g, b)
	if C_Texture and C_Texture.GetAtlasExists and C_Texture.GetAtlasExists(atlas) then
		texture:SetAtlas(atlas)
	else
		texture:SetColorTexture(r, g, b, 0.8)
	end
end

-- Heading in the quest book font with an ornamental divider below
function Style.Heading(parent, text, size, y)
	local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	label:SetFont(HEADER_FONT, size, "")
	label:SetTextColor(unpack(PARCHMENT))
	label:SetPoint("TOP", 0, y)
	label:SetText(text)
	local divider = parent:CreateTexture(nil, "ARTWORK")
	Style.SetAtlasOr(divider, "Campaign-QuestLog-LoreDivider", unpack(GOLD))
	divider:SetSize(parent:GetWidth() - 40, size > 16 and 10 or 6)
	divider:SetPoint("TOP", label, "BOTTOM", 0, -2)
	return label
end

function Style.Button(parent, text, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetText(text)
	button:SetSize(120, 22)
	button:SetScript("OnClick", onClick)
	return button
end

-- A hidden, movable window in the style of Blizzard's own (ButtonFrameTemplate, no portrait), closed by Esc
function Style.Window(name, title, width, height)
	local frame = CreateFrame("Frame", name, UIParent, "ButtonFrameTemplate")
	frame:Hide()
	if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(frame) end
	if ButtonFrameTemplate_HideButtonBar then ButtonFrameTemplate_HideButtonBar(frame) end
	if frame.Inset then frame.Inset:Hide() end
	if frame.SetTitle then frame:SetTitle(title) end
	frame:SetSize(width, height)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetPoint("CENTER")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	table.insert(UISpecialFrames, name) -- Esc closes it
	return frame
end
