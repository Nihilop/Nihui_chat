-- modules/messageline.lua - Custom message lines with fade animations
-- Adapted from ls_Glass: https://github.com/ls-/ls_Glass
local addonName, ns = ...

ns.MessageLine = {}

-- MessageLine prototype
local messageLineProto = {}

function messageLineProto:GetText()
    return self.Text:GetText() or ""
end

function messageLineProto:SetText(text, r, g, b, a)
    self.Text:SetText(text)
    self.Text:SetTextColor(r or 1, g or 1, b or 1, a or 1)
    self:AdjustHeight()
end

function messageLineProto:SetMessage(id, text, r, g, b, a)
    self:SetID(id)
    self:SetText(text, r, g, b, a)
    self:Show()
end

function messageLineProto:ClearMessage()
    if self:IsShown() then
        self:Hide()
        self:SetID(0)
        self:SetText("")
    end
end

function messageLineProto:FadeIn()
    -- Use Nihui_chat's fade system
    if ns.Animations and ns.Animations.FadeIn then
        local duration = ns.Config.animations.fadeInDuration
        ns.Animations.FadeIn(self, duration)
    else
        self:SetAlpha(1)
    end
end

function messageLineProto:FadeOut(delay, duration, callback)
    if ns.Animations and ns.Animations.FadeOut then
        ns.Animations.FadeOut(self, delay or 0, duration or 0.6, callback)
    else
        if callback then callback(self) end
    end
end

function messageLineProto:StopFading(finalAlpha)
    if ns.Animations and ns.Animations.StopFading then
        ns.Animations.StopFading(self, finalAlpha)
    else
        self:SetAlpha(finalAlpha or 1)
    end
end

function messageLineProto:AdjustHeight()
    local height = self.Text:GetStringHeight()
    if height < 1 then
        height = self.Text:GetLineHeight()
    end

    local padding = ns.Config.style.padding
    self:SetHeight(height + padding.top + padding.bottom)
end

function messageLineProto:AdjustWidth(width)
    self:SetWidth(width)

    local padding = ns.Config.style.padding
    self.Text:SetWidth(width - padding.left - padding.right)
end

-- Create a MessageLine
local function CreateMessageLine(pool, parent)
    local frame = CreateFrame("Frame", nil, parent)

    -- Apply prototype methods
    for k, v in pairs(messageLineProto) do
        frame[k] = v
    end

    -- Get config
    local padding = ns.Config.style.padding
    local fontSize = ns.Config.style.font.size

    frame:SetSize(parent:GetWidth(), fontSize + padding.top + padding.bottom)
    frame:SetID(0)
    frame:Hide()

    -- Create text
    frame.Text = frame:CreateFontString(nil, "OVERLAY")
    frame.Text:SetPoint("TOPLEFT", padding.left, -padding.top)
    frame.Text:SetPoint("TOPRIGHT", -padding.right, -padding.top)
    frame.Text:SetJustifyH("LEFT")
    frame.Text:SetJustifyV("TOP")
    frame.Text:SetWordWrap(true)
    frame.Text:SetNonSpaceWrap(true)

    -- Set font
    frame.Text:SetFont(
        ns.Config.style.font.face,
        ns.Config.style.font.size,
        ns.Config.style.font.flags
    )
    frame.Text:SetShadowOffset(1, -1)
    frame.Text:SetShadowColor(0, 0, 0, 0.8)

    -- Cache fade out callback
    frame.fadeOutCallback = function()
        frame:ClearMessage()
    end

    return frame
end

-- Reset a MessageLine
local function ResetMessageLine(pool, messageLine)
    messageLine:ClearMessage()
    messageLine:ClearAllPoints()
    messageLine:StopFading(1)
end

-- MessageLine pool prototype
local messagePoolProto = {}

function messagePoolProto:UpdateWidth()
    local width = self:GetParent():GetWidth()

    for messageLine in self:EnumerateActive() do
        messageLine:AdjustWidth(width)
    end
end

function messagePoolProto:UpdateHeight()
    for messageLine in self:EnumerateActive() do
        messageLine:AdjustHeight()
    end
end

-- Create pool for a chat frame
function ns.MessageLine.CreatePool(parent)
    local pool = CreateObjectPool(
        function(pool)
            return CreateMessageLine(pool, parent)
        end,
        ResetMessageLine
    )

    -- Add custom methods
    for k, v in pairs(messagePoolProto) do
        pool[k] = v
    end

    function pool:GetParent()
        return parent
    end

    return pool
end
