-- modules/frames.lua - Override Blizzard chat frames while preserving functionality
local addonName, ns = ...

ns.Frames = {}

local hiddenElements = {}  -- Track what we've hidden

-- Hide Blizzard chat elements we don't want
local function HideBlizzardElements(chatFrame)
    local frameName = chatFrame:GetName()

    -- Hide button frame (minimize/scroll buttons)
    local buttonFrame = _G[frameName .. "ButtonFrame"]
    if buttonFrame then
        buttonFrame:Hide()
        buttonFrame:SetAlpha(0)
        hiddenElements[buttonFrame] = true
    end

    -- Hide resize buttons
    local resizeButton = _G[frameName .. "ResizeButton"]
    if resizeButton then
        resizeButton:Hide()
        hiddenElements[resizeButton] = true
    end

    -- Keep scroll bar but style it later
    -- We don't hide it because users need to scroll
end

-- Enable mouse interactions for the chat frame
local function EnableMouseInteraction(chatFrame)
    chatFrame:SetMovable(true)
    chatFrame:SetResizable(true)
    chatFrame:SetClampedToScreen(true)
    chatFrame:SetMinResize(200, 100)
    chatFrame:SetMaxResize(800, 600)

    -- Allow click-through when not hovering
    chatFrame:EnableMouse(true)
    chatFrame:SetMouseClickEnabled(true)
end

-- Add custom resize handle
local function AddResizeHandle(chatFrame)
    if chatFrame.nihuiResizeHandle then
        return
    end

    local handle = CreateFrame("Frame", nil, chatFrame)
    handle:SetSize(16, 16)
    handle:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 0, 0)
    handle:SetFrameLevel(chatFrame:GetFrameLevel() + 10)

    -- Visual indicator
    local texture = handle:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetColorTexture(1, 1, 1, 0.2)

    handle:EnableMouse(true)
    handle:SetScript("OnEnter", function(self)
        texture:SetColorTexture(1, 1, 1, 0.4)
        SetCursor("UI_RESIZE_CURSOR")
    end)

    handle:SetScript("OnLeave", function(self)
        texture:SetColorTexture(1, 1, 1, 0.2)
        ResetCursor()
    end)

    handle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            chatFrame:StartSizing("BOTTOMRIGHT")
        end
    end)

    handle:SetScript("OnMouseUp", function(self, button)
        chatFrame:StopMovingOrSizing()
        FCF_SavePositionAndDimensions(chatFrame)
    end)

    chatFrame.nihuiResizeHandle = handle
end

-- Make frame movable with proper Blizzard integration
local function MakeMovable(chatFrame)
    -- Use Blizzard's built-in moving system when possible
    chatFrame:SetMovable(true)
    chatFrame:SetClampedToScreen(true)

    -- Hook into Blizzard's drag functionality
    local tab = _G[chatFrame:GetName() .. "Tab"]
    if tab then
        tab:SetScript("OnDragStart", function(self)
            if not ns.Config.position.locked then
                FCF_StartDragging(chatFrame)
            end
        end)

        tab:SetScript("OnDragStop", function(self)
            FCF_StopDragging(chatFrame)
            FCF_SavePositionAndDimensions(chatFrame)
        end)
    end
end

-- Override Blizzard functions to prevent conflicts
local function OverrideBlizzardFunctions()
    -- Prevent Blizzard from resetting our styling
    hooksecurefunc("FCF_SetChatWindowFontSize", function(frame, size)
        if frame and frame.nihuiStyled then
            -- Reapply our font after Blizzard changes it
            C_Timer.After(0.1, function()
                if ns.Styling and ns.Styling.ApplyToFrame then
                    ns.Styling.ApplyToFrame(frame)
                end
            end)
        end
    end)

    -- Hook into window show/hide to maintain styling
    hooksecurefunc("FCF_Close", function(frame)
        if frame and frame.nihuiStyled then
            -- Cancel any fade animations when closing
            if ns.Animations then
                ns.Animations.CancelFadeOut(frame)
            end
        end
    end)

    hooksecurefunc("FCF_OpenTemporaryWindow", function()
        -- Apply styling to temporary windows
        C_Timer.After(0.1, function()
            ns.Frames.Initialize()
        end)
    end)
end

-- Setup a single chat frame
function ns.Frames.SetupFrame(chatFrame)
    if not chatFrame or chatFrame.nihuiSetup then
        return
    end

    -- Mark as setup to prevent duplicate work
    chatFrame.nihuiSetup = true
    chatFrame.nihuiStyled = true

    -- Hide Blizzard elements
    HideBlizzardElements(chatFrame)

    -- Enable mouse interactions
    EnableMouseInteraction(chatFrame)

    -- Add resize handle
    AddResizeHandle(chatFrame)

    -- Make movable
    MakeMovable(chatFrame)

    -- Apply initial styling
    if ns.Styling then
        ns.Styling.ApplyToFrame(chatFrame)
    end

    -- Apply animations
    if ns.Animations then
        ns.Animations.ApplyToFrame(chatFrame)
    end
end

-- Initialize all chat frames
function ns.Frames.Initialize()
    -- Override Blizzard functions first
    OverrideBlizzardFunctions()

    -- Setup all chat frames
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            ns.Frames.SetupFrame(chatFrame)
        end
    end

    -- Setup combat log
    if CombatLogQuickButtonFrame_Custom then
        CombatLogQuickButtonFrame_Custom:Hide()
    end

    -- Listen for new chat windows
    hooksecurefunc("FCF_OpenNewWindow", function(name)
        C_Timer.After(0.1, function()
            for i = 1, NUM_CHAT_WINDOWS do
                local chatFrame = _G["ChatFrame" .. i]
                if chatFrame and not chatFrame.nihuiSetup then
                    ns.Frames.SetupFrame(chatFrame)
                end
            end
        end)
    end)
end

-- Clean up and restore Blizzard defaults (for debugging/unloading)
function ns.Frames.Restore()
    for element in pairs(hiddenElements) do
        if element and element.Show then
            element:Show()
            element:SetAlpha(1)
        end
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame.nihuiSetup = nil
            chatFrame.nihuiStyled = nil

            if chatFrame.nihuiResizeHandle then
                chatFrame.nihuiResizeHandle:Hide()
            end
        end
    end
end
