local _, ns = ...
local E, C, D, L = ns.E, ns.C, ns.D, ns.L

-- Lua
local _G = getfenv(0)
local t_insert = _G.table.insert

-- Mine
local backdrops = {}

local backdrop_proto = {}
do
	function backdrop_proto:UpdateAlpha(a)
		-- Keep castbar style dark background if it's a castbar backdrop
		if self.isCastbarBackdrop then
			self:SetBackdropColor(0.2, 0.2, 0.2, a)
			self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
		-- Keep Nihui_uf border color if it's a tab backdrop
		elseif self.isTabBackdrop then
			self:SetBackdropColor(0, 0, 0, a)
			self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
		else
			self:SetBackdropColor(0, 0, 0, a)
			self:SetBackdropBorderColor(0, 0, 0, a)
		end
	end

	function backdrop_proto:UpdateOffsets(xOffset, yOffset)
		self:SetPoint("TOPLEFT", xOffset or 0, -(yOffset or 0))
		self:SetPoint("BOTTOMRIGHT", -(xOffset or 0), yOffset or 0)
	end
end

function E:CreateBackdrop(parent, alpha,  xOffset, yOffset)
	local backdrop = Mixin(CreateFrame("Frame", nil, parent, "BackdropTemplate"), backdrop_proto)
	backdrop:SetFrameLevel(parent:GetFrameLevel() - 1)
	backdrop:SetPoint("TOPLEFT", xOffset or 0, -(yOffset or 0))
	backdrop:SetPoint("BOTTOMRIGHT", -(xOffset or 0), yOffset or 0)
	backdrop:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\AddOns\\Nihui_chat\\assets\\border",
		tile = true,
		tileEdge = true,
		tileSize = 8,
		edgeSize = 8,
		-- insets = {left = 4, right = 4, top = 4, bottom = 4},
	})

	-- the way Blizz position it creates really weird gaps, so fix it
	backdrop.Center:ClearAllPoints()
	backdrop.Center:SetPoint("TOPLEFT", backdrop.TopLeftCorner, "BOTTOMRIGHT", 0, 0)
	backdrop.Center:SetPoint("BOTTOMRIGHT", backdrop.BottomRightCorner, "TOPLEFT", 0, 0)

	backdrop:SetBackdropColor(0, 0, 0, alpha)
	backdrop:SetBackdropBorderColor(0, 0, 0, alpha)

	t_insert(backdrops, backdrop)

	return backdrop
end

-- Create backdrop with Nihui_uf style border
function E:CreateTabBackdrop(parent, alpha, xOffset, yOffset)
	local backdrop = Mixin(CreateFrame("Frame", nil, parent, "BackdropTemplate"), backdrop_proto)
	backdrop.isTabBackdrop = true
	backdrop:SetFrameLevel(parent:GetFrameLevel() - 1)
	backdrop:SetPoint("TOPLEFT", -12, 12)
	backdrop:SetPoint("BOTTOMRIGHT", 12, -12)
	backdrop:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\AddOns\\Nihui_chat\\textures\\MirroredFrameSingleUF",
		tile = false,
		edgeSize = 16,
		insets = {left = 12, right = 12, top = 12, bottom = 12},
	})

	backdrop:SetBackdropColor(0, 0, 0, alpha)
	backdrop:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) -- Nihui_uf gray border

	t_insert(backdrops, backdrop)

	return backdrop
end

-- Create backdrop with Nihui_cb castbar style border
function E:CreateCastbarBackdrop(parent, alpha)
	local backdrop = Mixin(CreateFrame("Frame", nil, parent, "BackdropTemplate"), backdrop_proto)
	backdrop.isCastbarBackdrop = true
	backdrop:SetFrameLevel(parent:GetFrameLevel() - 1)
	backdrop:SetPoint("TOPLEFT", -12, 12)
	backdrop:SetPoint("BOTTOMRIGHT", 12, -12)
	backdrop:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\AddOns\\Nihui_chat\\textures\\MirroredFrameSingle2",
		tile = false,
		edgeSize = 16,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})

	backdrop:SetBackdropColor(0.2, 0.2, 0.2, alpha)
	backdrop:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) -- Nihui_cb gray border

	t_insert(backdrops, backdrop)

	return backdrop
end

-- Create backdrop with Nihui_uf style (border + glass effect)
function E:CreateGlassBackdrop(parent, alpha, addGlass)
	local backdrop = Mixin(CreateFrame("Frame", nil, parent, "BackdropTemplate"), backdrop_proto)
	backdrop:SetFrameLevel(parent:GetFrameLevel() - 1)
	backdrop:SetPoint("TOPLEFT", -12, 12)
	backdrop:SetPoint("BOTTOMRIGHT", 12, -12)
	backdrop:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\AddOns\\Nihui_chat\\textures\\MirroredFrameSingleUF",
		tile = false,
		edgeSize = 16,
		insets = {left = 12, right = 12, top = 12, bottom = 12},
	})

	backdrop:SetBackdropColor(0, 0, 0, alpha or 0.8)
	backdrop:SetBackdropBorderColor(0.5, 0.5, 0.5, 1) -- Nihui_uf gray border

	-- Add glass overlay effect if requested
	if addGlass then
		local glass = parent:CreateTexture(nil, "ARTWORK", nil, 7)
		glass:SetTexture("Interface\\AddOns\\Nihui_chat\\textures\\HPGlass.tga")
		glass:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
		glass:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

		-- Texture slicing (exact Nihui_uf style)
		glass:SetTextureSliceMargins(16, 16, 16, 16)
		glass:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)

		glass:SetAlpha(0.2)
		glass:SetBlendMode("ADD")

		backdrop.glass = glass
	end

	t_insert(backdrops, backdrop)

	return backdrop
end
