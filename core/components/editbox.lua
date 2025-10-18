local _, ns = ...
local E, C, D, L = ns.E, ns.C, ns.D, ns.L

-- Lua
local _G = getfenv(0)
local next = _G.next

-- Mine
local handledEditBoxes = {}

local EDIT_BOX_TEXTURES = {
	"Left",
	"Mid",
	"Right",

	"FocusLeft",
	"FocusMid",
	"FocusRight",
}

function E:HandleEditBox(frame)
	if not handledEditBoxes[frame] then
		-- Auto-hide functionality
		if C.db.profile.edit.autohide then
			-- Hide by default
			frame:SetAlpha(0)
			frame:EnableMouse(false)

			-- Show on focus
			frame:HookScript("OnEditFocusGained", function(self)
				if C.db.profile.edit.autohide then
					self:SetAlpha(1)
					self:EnableMouse(true)
				end
			end)

			-- Hide on focus lost
			frame:HookScript("OnEditFocusLost", function(self)
				if C.db.profile.edit.autohide then
					self:SetAlpha(0)
					self:EnableMouse(false)
				end
			end)
		end

		handledEditBoxes[frame] = true
	end

	-- Always recreate backdrop to apply new style with glass effect
	if frame.Backdrop then
		frame.Backdrop:Hide()
		frame.Backdrop = nil
	end
	frame.Backdrop = E:CreateGlassBackdrop(frame, C.db.profile.edit.alpha, true)

	for _, texture in next, EDIT_BOX_TEXTURES do
		_G[frame:GetName() .. texture]:SetTexture(0)
	end

	frame:SetMultiLine(C.db.profile.edit.multiline)
	frame:SetAltArrowKeyMode(C.db.profile.edit.alt)
	frame:SetHeight(38)
	frame:ClearAllPoints()

	if C.db.profile.edit.position == "top" then
		frame:SetPoint("TOPLEFT", frame.chatFrame, "TOPLEFT", 0, C.db.profile.edit.offset)
		frame:SetPoint("TOPRIGHT", frame.chatFrame, "TOPRIGHT", 0, C.db.profile.edit.offset)
	else
		frame:SetPoint("BOTTOMLEFT", frame.chatFrame, "BOTTOMLEFT", 0, -C.db.profile.edit.offset)
		frame:SetPoint("BOTTOMRIGHT", frame.chatFrame, "BOTTOMRIGHT", 0, -C.db.profile.edit.offset)
	end

	frame:SetFontObject("NihuiChatEditBoxFont")
	frame.header:SetFontObject("NihuiChatEditBoxFont")
	frame.headerSuffix:SetFontObject("NihuiChatEditBoxFont")
	frame.NewcomerHint:SetFontObject("NihuiChatEditBoxFont")
	frame.prompt:SetFontObject("NihuiChatEditBoxFont")
end

function E:UpdateEditBoxPosition()
	local isOnTop = C.db.profile.edit.position == "top"
	local offset = C.db.profile.edit.offset

	for editBox in next, handledEditBoxes do
		editBox:ClearAllPoints()

		if isOnTop then
			editBox:SetPoint("TOPLEFT", editBox.chatFrame, "TOPLEFT", 0, offset)
			editBox:SetPoint("TOPRIGHT", editBox.chatFrame, "TOPRIGHT", 0, offset)
		else
			editBox:SetPoint("BOTTOMLEFT", editBox.chatFrame, "BOTTOMLEFT", 0, -offset)
			editBox:SetPoint("BOTTOMRIGHT", editBox.chatFrame, "BOTTOMRIGHT", 0, -offset)
		end
	end
end

function E:UpdateEditBoxMultiLine()
	local isMultiline = C.db.profile.edit.multiline

	for editBox in next, handledEditBoxes do
		editBox:SetMultiLine(isMultiline)
		editBox:SetHeight(38)
	end
end

function E:UpdateEditBoxAltArrowKeyMode()
	local altMode = C.db.profile.edit.alt

	for editBox in next, handledEditBoxes do
		editBox:SetAltArrowKeyMode(altMode)
	end
end

function E:UpdateEditBoxAlpha()
	local alpha = C.db.profile.edit.alpha

	for editBox in next, handledEditBoxes do
		editBox.Backdrop:UpdateAlpha(alpha)
	end
end
