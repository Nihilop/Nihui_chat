-- modules/styling.lua - Clean styling for chat frames
local addonName, ns = ...

ns.Styling = {}

-- Apply clean background styling
local function StyleBackground(chatFrame)
    local config = ns.Config.style
    local frameName = chatFrame:GetName()

    -- Hide ALL default background textures more aggressively
    for i = 1, chatFrame:GetNumRegions() do
        local region = select(i, chatFrame:GetRegions())
        if region and region:GetObjectType() == "Texture" then
            -- Hide all textures except icons
            if region:GetDrawLayer() == "BACKGROUND" or region:GetDrawLayer() == "BORDER" then
                region:SetTexture(nil)
                region:Hide()
            end
        end
    end

    -- Hide specific Blizzard frames
    local buttonFrame = _G[frameName .. "ButtonFrame"]
    if buttonFrame then
        buttonFrame:Hide()
        buttonFrame:SetAlpha(0)

        -- Hide all textures in button frame
        for i = 1, buttonFrame:GetNumRegions() do
            local region = select(i, buttonFrame:GetRegions())
            if region and region:GetObjectType() == "Texture" then
                region:SetTexture(nil)
                region:Hide()
            end
        end
    end

    -- Hide resize button
    local resizeButton = _G[frameName .. "ResizeButton"]
    if resizeButton then
        resizeButton:Hide()
    end

    -- Hide background textures in the main frame
    local bg = _G[frameName .. "Background"]
    if bg then
        bg:SetTexture(nil)
        bg:Hide()
    end

    -- Create custom background
    if config.background.enabled then
        if not chatFrame.nihuiBackground then
            chatFrame.nihuiBackground = chatFrame:CreateTexture(nil, "BACKGROUND")
            chatFrame.nihuiBackground:SetAllPoints(chatFrame)
        end

        if config.background.useAtlas then
            -- Use atlas texture
            chatFrame.nihuiBackground:SetAtlas(config.background.atlas, true)
            local c = config.background.color
            chatFrame.nihuiBackground:SetVertexColor(c.r, c.g, c.b, config.background.alpha)
        else
            -- Use solid color
            local c = config.background.color
            chatFrame.nihuiBackground:SetColorTexture(c.r, c.g, c.b, c.a)
        end

        chatFrame.nihuiBackground:Show()
    else
        if chatFrame.nihuiBackground then
            chatFrame.nihuiBackground:Hide()
        end
    end

    -- Hide gradient (using atlas instead)
    if chatFrame.nihuiGradient then
        chatFrame.nihuiGradient:Hide()
    end

    -- Hide borders (disabled for clean look)
    if chatFrame.nihuiBorder then
        for _, border in pairs(chatFrame.nihuiBorder) do
            border:Hide()
        end
    end
end

-- Style chat tabs
local function StyleTabs(chatFrame)
    local config = ns.Config.style.tabs
    local tab = _G[chatFrame:GetName() .. "Tab"]

    if not tab then return end

    -- Hide default tab textures
    if config.hideBackground then
        local tabLeft = _G[tab:GetName() .. "Left"]
        local tabMiddle = _G[tab:GetName() .. "Middle"]
        local tabRight = _G[tab:GetName() .. "Right"]

        if tabLeft then tabLeft:SetTexture(nil) end
        if tabMiddle then tabMiddle:SetTexture(nil) end
        if tabRight then tabRight:SetTexture(nil) end

        -- Also hide selected/highlight textures
        local tabHighlightLeft = _G[tab:GetName() .. "HighlightLeft"]
        local tabHighlightMiddle = _G[tab:GetName() .. "HighlightMiddle"]
        local tabHighlightRight = _G[tab:GetName() .. "HighlightRight"]

        if tabHighlightLeft then tabHighlightLeft:SetTexture(nil) end
        if tabHighlightMiddle then tabHighlightMiddle:SetTexture(nil) end
        if tabHighlightRight then tabHighlightRight:SetTexture(nil) end
    end

    -- Style tab text
    local tabText = _G[tab:GetName() .. "Text"]
    if tabText then
        tabText:SetFont(ns.Config.style.font.face, config.fontSize, ns.Config.style.font.flags)
        tabText:SetShadowOffset(0, 0)
    end

    -- Add glow on hover
    tab:HookScript("OnEnter", function(self)
        local text = _G[self:GetName() .. "Text"]
        if text then
            text:SetTextColor(1, 1, 1, 1)
        end
    end)

    tab:HookScript("OnLeave", function(self)
        local text = _G[self:GetName() .. "Text"]
        if text and self ~= SELECTED_CHAT_FRAME.Tab then
            text:SetTextColor(0.7, 0.7, 0.7, 1)
        end
    end)
end

-- Style edit box (detached like Nihui_cb)
local function StyleEditBox(chatFrame)
    local config = ns.Config.style.editBox
    local editBox = _G[chatFrame:GetName() .. "EditBox"]

    if not editBox then return end

    -- Hide default textures
    for i = 1, editBox:GetNumRegions() do
        local region = select(i, editBox:GetRegions())
        if region and region:GetObjectType() == "Texture" then
            region:SetTexture(nil)
            region:Hide()
        end
    end

    -- Create custom background
    if config.background.enabled then
        if not editBox.nihuiBackground then
            editBox.nihuiBackground = editBox:CreateTexture(nil, "BACKGROUND")
            editBox.nihuiBackground:SetAllPoints(editBox)
        end

        local bg = config.background.color
        editBox.nihuiBackground:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
        editBox.nihuiBackground:Show()
    else
        if editBox.nihuiBackground then
            editBox.nihuiBackground:Hide()
        end
    end

    -- Position edit box (detached with offset)
    local offset = config.offset or 4
    editBox:ClearAllPoints()
    if config.position == "TOP" then
        editBox:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", 0, offset)
        editBox:SetPoint("BOTTOMRIGHT", chatFrame, "TOPRIGHT", 0, offset)
    elseif config.position == "BOTTOM" then
        editBox:SetPoint("TOPLEFT", chatFrame, "BOTTOMLEFT", 0, -offset)
        editBox:SetPoint("TOPRIGHT", chatFrame, "BOTTOMRIGHT", 0, -offset)
    elseif config.position == "HIDE" then
        editBox:Hide()
        return
    end

    editBox:SetHeight(config.height)

    -- Style font
    editBox:SetFont(ns.Config.style.font.face, ns.Config.style.font.size, ns.Config.style.font.flags)
    editBox:SetShadowOffset(1, -1)
    editBox:SetShadowColor(0, 0, 0, 0.8)

    -- Text color
    editBox:SetTextColor(1, 1, 1, 1)
end

-- Apply font styling
local function StyleFont(chatFrame)
    local config = ns.Config.style.font

    -- Style the main chat font
    local fontFile, _, fontFlags = chatFrame:GetFont()
    chatFrame:SetFont(config.face, config.size, config.flags ~= "" and config.flags or fontFlags)
    chatFrame:SetShadowOffset(1, -1)
    chatFrame:SetShadowColor(0, 0, 0, 0.5)
end

-- Apply all styling to a chat frame
function ns.Styling.ApplyToFrame(chatFrame)
    StyleBackground(chatFrame)
    StyleTabs(chatFrame)
    StyleEditBox(chatFrame)
    StyleFont(chatFrame)

    -- Apply insets for padding
    local padding = ns.Config.style.padding
    chatFrame:SetClampRectInsets(-padding.left, -padding.right, -padding.top, -padding.bottom)
end

-- Initialize styling for all chat frames
function ns.Styling.Initialize()
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            ns.Styling.ApplyToFrame(chatFrame)
        end
    end
end

-- Refresh styling (useful after config changes)
function ns.Styling.Refresh()
    ns.Styling.Initialize()
end
