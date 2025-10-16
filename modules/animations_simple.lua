-- modules/animations_simple.lua - Simple frame-based fade animations (stable)
local addonName, ns = ...

ns.AnimationsSimple = {}

local chatFrameFaders = {}

-- Fade out a chat frame
local function FadeOutFrame(chatFrame, duration)
    if not chatFrame or not chatFrame:IsVisible() then return end

    duration = duration or ns.Config.animations.fadeOutDuration

    if chatFrame.nihuiFadeAnim then
        chatFrame.nihuiFadeAnim:Stop()
    end

    if not chatFrame.nihuiFadeGroup then
        chatFrame.nihuiFadeGroup = chatFrame:CreateAnimationGroup()
        chatFrame.nihuiFadeAnim = chatFrame.nihuiFadeGroup:CreateAnimation("Alpha")
    end

    local anim = chatFrame.nihuiFadeAnim
    anim:SetFromAlpha(chatFrame:GetAlpha())
    anim:SetToAlpha(0.2)  -- Fade to 20% (not completely invisible)
    anim:SetDuration(duration)
    anim:SetSmoothing("IN")

    chatFrame.nihuiFadeGroup:Play()
end

-- Fade in a chat frame
local function FadeInFrame(chatFrame, duration)
    if not chatFrame then return end

    duration = duration or ns.Config.animations.fadeInDuration

    if chatFrame.nihuiFadeAnim then
        chatFrame.nihuiFadeAnim:Stop()
    end

    if not chatFrame.nihuiFadeGroup then
        chatFrame.nihuiFadeGroup = chatFrame:CreateAnimationGroup()
        chatFrame.nihuiFadeAnim = chatFrame.nihuiFadeGroup:CreateAnimation("Alpha")
    end

    local anim = chatFrame.nihuiFadeAnim
    anim:SetFromAlpha(chatFrame:GetAlpha())
    anim:SetToAlpha(1.0)
    anim:SetDuration(duration)
    anim:SetSmoothing("OUT")

    chatFrame.nihuiFadeGroup:Play()
end

-- Schedule fade out after delay
local function ScheduleFadeOut(chatFrame)
    local delay = ns.Config.animations.fadeOutDelay

    if delay <= 0 or not ns.Config.features.fadeOnInactive then
        return
    end

    -- Cancel existing timer
    local fader = chatFrameFaders[chatFrame]
    if fader and fader.timer then
        fader.timer:Cancel()
    end

    -- Create new timer
    if not fader then
        fader = {}
        chatFrameFaders[chatFrame] = fader
    end

    fader.timer = C_Timer.NewTimer(delay, function()
        FadeOutFrame(chatFrame)
        fader.timer = nil
    end)
end

-- Cancel fade out
local function CancelFadeOut(chatFrame)
    local fader = chatFrameFaders[chatFrame]
    if fader and fader.timer then
        fader.timer:Cancel()
        fader.timer = nil
    end

    FadeInFrame(chatFrame, 0.2)  -- Quick fade in
end

-- Hook a chat frame for fade behavior
local function HookChatFrame(chatFrame)
    if chatFrame.nihuiFadeHooked then return end
    chatFrame.nihuiFadeHooked = true

    -- Fade in on new message
    hooksecurefunc(chatFrame, "AddMessage", function(self)
        CancelFadeOut(self)
        ScheduleFadeOut(self)
    end)

    -- Fade in on mouse enter
    chatFrame:HookScript("OnEnter", function(self)
        CancelFadeOut(self)
    end)

    -- Schedule fade out on mouse leave
    chatFrame:HookScript("OnLeave", function(self)
        ScheduleFadeOut(self)
    end)

    -- Initial schedule
    ScheduleFadeOut(chatFrame)
end

-- Initialize
function ns.AnimationsSimple.Initialize()
    if not ns.Config.animations.enabled then
        print("|cff1a9fc0Nihui Chat:|r Animations disabled in config")
        return
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            HookChatFrame(chatFrame)
        end
    end

    print("|cff1a9fc0Nihui Chat:|r Simple fade animations enabled")
end

-- Cleanup
function ns.AnimationsSimple.Disable()
    for chatFrame, fader in pairs(chatFrameFaders) do
        if fader.timer then
            fader.timer:Cancel()
        end
        chatFrame:SetAlpha(1.0)
        if chatFrame.nihuiFadeGroup then
            chatFrame.nihuiFadeGroup:Stop()
        end
    end
    chatFrameFaders = {}
end
