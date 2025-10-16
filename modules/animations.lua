-- modules/animations.lua - Per-message fade in/out animations (ls_Glass style)
local addonName, ns = ...

ns.Animations = {}

local messageFrames = {}  -- Store custom message frames per chat frame
local MAX_MESSAGES = 100  -- Maximum messages to keep

-- Create a custom message line (FontString with animation)
local function CreateMessageLine(chatFrame)
    local container = chatFrame.nihuiMessageContainer

    local line = container:CreateFontString(nil, "ARTWORK")
    line:SetJustifyH("LEFT")
    line:SetJustifyV("TOP")
    line:SetNonSpaceWrap(false)
    line:SetWordWrap(true)
    line:SetMaxLines(0)

    -- Apply chat font
    local fontFace = ns.Config.style.font.face
    local fontSize = ns.Config.style.font.size
    local fontFlags = ns.Config.style.font.flags
    line:SetFont(fontFace, fontSize, fontFlags)
    line:SetShadowOffset(1, -1)
    line:SetShadowColor(0, 0, 0, 0.5)

    -- Set width to match container
    line:SetWidth(container:GetWidth())

    -- Create animation group
    local animGroup = line:CreateAnimationGroup()
    line.animGroup = animGroup

    -- Fade in animation
    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(ns.Config.animations.fadeInDuration)
    fadeIn:SetSmoothing("OUT")
    fadeIn:SetOrder(1)

    -- Slide up animation
    local slideUp = animGroup:CreateAnimation("Translation")
    slideUp:SetOffset(0, ns.Config.animations.slideDistance)
    slideUp:SetDuration(ns.Config.animations.fadeInDuration)
    slideUp:SetSmoothing("OUT")
    slideUp:SetOrder(1)

    -- Fade out animation (separate group)
    local fadeOutGroup = line:CreateAnimationGroup()
    line.fadeOutGroup = fadeOutGroup

    local fadeOut = fadeOutGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(ns.Config.animations.fadeOutDuration)
    fadeOut:SetSmoothing("IN")

    fadeOutGroup:SetScript("OnFinished", function()
        line:SetAlpha(0)
    end)

    line:SetAlpha(0)
    line:Hide()

    return line
end

-- Create message container for custom messages
local function CreateMessageContainer(chatFrame)
    if chatFrame.nihuiMessageContainer then
        return chatFrame.nihuiMessageContainer
    end

    local container = CreateFrame("Frame", nil, chatFrame)
    container:SetAllPoints(chatFrame)
    container:SetFrameLevel(chatFrame:GetFrameLevel() + 5)  -- Above chat frame

    chatFrame.nihuiMessageContainer = container
    messageFrames[chatFrame] = {}

    return container
end

-- Reposition all visible messages (stack them from bottom to top)
local function RepositionMessages(chatFrame)
    local messages = messageFrames[chatFrame]
    if not messages then return end

    local container = chatFrame.nihuiMessageContainer
    local yOffset = 5  -- Start from bottom with padding
    local spacing = 2  -- Space between messages

    -- Position from bottom to top
    for i = #messages, 1, -1 do
        local msg = messages[i]
        if msg:IsShown() then
            msg:ClearAllPoints()
            msg:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 5, yOffset)
            msg:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -5, yOffset)

            -- Calculate height after positioning
            local height = msg:GetHeight()
            yOffset = yOffset + height + spacing
        end
    end
end

-- Add a new message with animation
local function AddAnimatedMessage(chatFrame, text, r, g, b, a, hold)
    print("|cff1a9fc0DEBUG:|r AddAnimatedMessage called, enabled=" .. tostring(ns.Config.animations.enabled))

    if not ns.Config.animations.enabled then
        -- Fall back to default if animations disabled
        return
    end

    local messages = messageFrames[chatFrame]
    if not messages then
        print("|cffff0000DEBUG:|r No messages table for chat frame!")
        return
    end

    print("|cff1a9fc0DEBUG:|r Creating message line...")
    -- Get or create a message line
    local line = CreateMessageLine(chatFrame)
    print("|cff1a9fc0DEBUG:|r Message line created")

    -- Set message properties
    line:SetText(text)
    if r and g and b then
        line:SetTextColor(r, g, b, a or 1)
    else
        line:SetTextColor(1, 1, 1, 1)
    end

    -- Add to messages array
    table.insert(messages, line)

    -- Remove old messages if too many
    if #messages > MAX_MESSAGES then
        local oldMsg = table.remove(messages, 1)
        oldMsg:Hide()
        oldMsg:SetText("")
    end

    -- Show and position all messages
    line:Show()
    RepositionMessages(chatFrame)

    -- Start fade in animation from starting position (below final position)
    line:SetAlpha(0)

    -- Start animation
    if line.animGroup then
        line.animGroup:Stop()
        line.animGroup:Play()
    end

    -- Schedule fade out if configured
    if ns.Config.animations.fadeOutDelay > 0 and ns.Config.features.fadeOnInactive then
        if line.fadeOutTimer then
            line.fadeOutTimer:Cancel()
        end

        line.fadeOutTimer = C_Timer.NewTimer(ns.Config.animations.fadeOutDelay, function()
            if line.fadeOutGroup then
                line.fadeOutGroup:Play()
            end
        end)
    end
end

-- Cancel fade out and restore message opacity
local function RestoreMessageOpacity(chatFrame)
    local messages = messageFrames[chatFrame]
    if not messages then return end

    for _, msg in ipairs(messages) do
        -- Cancel fade out timer
        if msg.fadeOutTimer then
            msg.fadeOutTimer:Cancel()
            msg.fadeOutTimer = nil
        end

        -- Stop fade out animation
        if msg.fadeOutGroup then
            msg.fadeOutGroup:Stop()
        end

        -- Quick fade in to full opacity
        if msg:IsShown() then
            msg:SetAlpha(1)
        end
    end
end

-- Schedule fade out for all messages
local function ScheduleMessagesFadeOut(chatFrame)
    if not ns.Config.features.fadeOnInactive then
        return
    end

    local messages = messageFrames[chatFrame]
    if not messages then return end

    for _, msg in ipairs(messages) do
        if msg:IsShown() and msg:GetAlpha() > 0 then
            if msg.fadeOutTimer then
                msg.fadeOutTimer:Cancel()
            end

            msg.fadeOutTimer = C_Timer.NewTimer(ns.Config.animations.fadeOutDelay, function()
                if msg.fadeOutGroup then
                    msg.fadeOutGroup:Play()
                end
            end)
        end
    end
end

-- Hook into chat frame to intercept messages
local function HookChatFrame(chatFrame)
    -- Create message container
    CreateMessageContainer(chatFrame)

    -- Disable Blizzard's fading so we control it
    chatFrame:SetFading(false)

    -- Hook AddMessage using hooksecurefunc (safer than replacing)
    hooksecurefunc(chatFrame, "AddMessage", function(self, text, r, g, b, messageID, hold)
        -- Debug print
        print("|cff1a9fc0Nihui Chat:|r Message intercepted: " .. (text and string.sub(text, 1, 50) or "nil"))

        -- Add to our custom animated system
        AddAnimatedMessage(self, text, r, g, b, 1, hold)
    end)

    -- Hide the original chat text (make it very transparent)
    -- We'll show our custom animated version instead
    chatFrame:SetAlpha(0.01)

    -- Restore opacity on hover
    chatFrame:HookScript("OnEnter", function(self)
        RestoreMessageOpacity(self)
    end)

    -- Schedule fade out on leave
    chatFrame:HookScript("OnLeave", function(self)
        ScheduleMessagesFadeOut(self)
    end)

    -- Handle container resizing
    chatFrame:HookScript("OnSizeChanged", function(self, width, height)
        if self.nihuiMessageContainer then
            -- Update all message widths
            local messages = messageFrames[self]
            if messages then
                for _, msg in ipairs(messages) do
                    msg:SetWidth(self.nihuiMessageContainer:GetWidth() - 10)
                end
                RepositionMessages(self)
            end
        end
    end)
end

-- Apply animations to a chat frame
function ns.Animations.ApplyToFrame(chatFrame)
    HookChatFrame(chatFrame)
end

-- Initialize animations for all chat frames
function ns.Animations.Initialize()
    if not ns.Config.animations.enabled then
        return
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            ns.Animations.ApplyToFrame(chatFrame)
        end
    end

    print("|cff1a9fc0Nihui Chat:|r Per-message animations enabled")
end

-- Clear all messages (for refresh)
function ns.Animations.ClearMessages(chatFrame)
    local messages = messageFrames[chatFrame]
    if messages then
        for _, msg in ipairs(messages) do
            msg:Hide()
            msg:SetText("")
        end
        messageFrames[chatFrame] = {}
    end
end

-- Disable animations and restore Blizzard default
function ns.Animations.Disable()
    for chatFrame, messages in pairs(messageFrames) do
        -- Clear custom messages
        for _, msg in ipairs(messages) do
            msg:Hide()
        end

        -- Show original chat frame
        chatFrame:SetAlpha(1)

        -- Restore original fading
        chatFrame:SetFading(true)
    end

    messageFrames = {}
end
