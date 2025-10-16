-- modules/messagehandler.lua - Handle custom message display with animations
-- Adapted from ls_Glass: https://github.com/ls-/ls_Glass
local addonName, ns = ...

ns.MessageHandler = {}

local chatFrameHandlers = {}
local messageCounter = 0
local MAX_MESSAGES = 200

-- Get or create handler for a chat frame
local function GetHandler(chatFrame)
    return chatFrameHandlers[chatFrame]
end

-- Stack messages from top to bottom (like normal chat)
local function RepositionMessages(handler)
    local messages = {}

    -- Collect all active messages
    for messageLine in handler.pool:EnumerateActive() do
        table.insert(messages, messageLine)
    end

    -- Sort by ID (oldest first)
    table.sort(messages, function(a, b) return a:GetID() < b:GetID() end)

    -- Position from bottom to top (newest at bottom)
    local yOffset = 0
    local spacing = 2
    local maxHeight = handler.container:GetHeight()

    -- Start from newest (end of array) and work backwards
    for i = #messages, 1, -1 do
        local messageLine = messages[i]
        local messageHeight = messageLine:GetHeight()

        -- Check if we have room
        if yOffset + messageHeight > maxHeight then
            -- No room, hide this message
            messageLine:Hide()
        else
            messageLine:ClearAllPoints()
            messageLine:SetPoint("BOTTOMLEFT", handler.container, "BOTTOMLEFT", 0, yOffset)
            messageLine:SetPoint("BOTTOMRIGHT", handler.container, "BOTTOMRIGHT", 0, yOffset)
            messageLine:Show()

            yOffset = yOffset + messageHeight + spacing
        end
    end
end

-- Add a new message with animation
local function AddAnimatedMessage(handler, text, r, g, b, a)
    messageCounter = messageCounter + 1

    -- Get a message line from the pool
    local messageLine = handler.pool:Acquire()

    -- Set message content
    messageLine:SetMessage(messageCounter, text, r, g, b, a)

    -- Limit number of messages BEFORE repositioning
    local activeCount = 0
    for _ in handler.pool:EnumerateActive() do
        activeCount = activeCount + 1
    end

    if activeCount > MAX_MESSAGES then
        -- Release oldest messages
        local toRelease = {}
        local count = 0
        for ml in handler.pool:EnumerateActive() do
            count = count + 1
            if count <= activeCount - MAX_MESSAGES then
                table.insert(toRelease, ml)
            end
        end

        for _, ml in ipairs(toRelease) do
            handler.pool:Release(ml)
        end
    end

    -- Position all messages (newest at bottom)
    RepositionMessages(handler)

    -- Fade in animation
    if ns.Config.animations.enabled then
        messageLine:SetAlpha(0)
        C_Timer.After(0, function()
            if messageLine and messageLine:IsShown() then
                messageLine:FadeIn()
            end
        end)
    else
        messageLine:SetAlpha(1)
    end

    -- Schedule fade out if configured (20s for individual messages)
    if ns.Config.animations.enabled and ns.Config.features.fadeOnInactive then
        local messageDelay = 20  -- Individual messages fade at 20s
        messageLine:FadeOut(messageDelay, ns.Config.animations.fadeOutDuration, function()
            handler.pool:Release(messageLine)
            RepositionMessages(handler)
        end)
    end
end

-- Create handler for a chat frame
local function CreateHandler(chatFrame)
    local handler = {}

    -- IMPORTANT: Hide Blizzard's FontStringContainer completely (like ls_Glass does)
    if chatFrame.FontStringContainer then
        chatFrame.FontStringContainer:Hide()
        chatFrame.FontStringContainer:SetAlpha(0)
    end

    -- Create container for messages
    handler.container = CreateFrame("Frame", nil, chatFrame)
    handler.container:SetAllPoints(chatFrame)
    handler.container:SetFrameLevel(chatFrame:GetFrameLevel() + 10)

    -- Create message pool
    handler.pool = ns.MessageLine.CreatePool(handler.container)

    -- Store reference
    chatFrameHandlers[chatFrame] = handler

    return handler
end

-- Hook a chat frame to intercept messages
local function HookChatFrame(chatFrame)
    if chatFrame.nihuiMessageHooked then return end
    chatFrame.nihuiMessageHooked = true

    -- Create handler
    local handler = CreateHandler(chatFrame)

    -- Store original AddMessage
    local originalAddMessage = chatFrame.AddMessage

    -- Hook AddMessage
    chatFrame.AddMessage = function(self, text, r, g, b, messageID, hold)
        -- Add to our custom system
        if handler and text then
            AddAnimatedMessage(handler, text, r, g, b, 1)
        end

        -- Call original to preserve chat log, history, etc.
        -- FontStringContainer is hidden, so these won't show
        originalAddMessage(self, text, r, g, b, messageID, hold)
    end

    -- Handle resize
    chatFrame:HookScript("OnSizeChanged", function(self, width, height)
        if handler and handler.pool then
            handler.pool:UpdateWidth()
            RepositionMessages(handler)
        end
    end)

    -- Restore messages on hover (cancel fade out for messages AND frame)
    chatFrame:HookScript("OnEnter", function(self)
        if handler then
            -- Cancel fade on all messages
            for messageLine in handler.pool:EnumerateActive() do
                messageLine:StopFading(1)
            end

            -- Cancel frame fade
            if ns.Animations then
                ns.Animations.StopFading(self, 1)
            end
        end
    end)
end

-- Initialize
function ns.MessageHandler.Initialize()
    if not ns.Config.animations.enabled then
        print("|cff1a9fc0Nihui Chat:|r Message animations disabled in config")
        return
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            HookChatFrame(chatFrame)
        end
    end

    print("|cff1a9fc0Nihui Chat:|r Message animations enabled (per-message fade)")
end

-- Cleanup
function ns.MessageHandler.Disable()
    for chatFrame, handler in pairs(chatFrameHandlers) do
        if handler.pool then
            handler.pool:ReleaseAll()
        end
        if handler.container then
            handler.container:Hide()
        end

        -- Restore Blizzard's FontStringContainer
        if chatFrame.FontStringContainer then
            chatFrame.FontStringContainer:Show()
            chatFrame.FontStringContainer:SetAlpha(1)
        end
    end

    chatFrameHandlers = {}
end
