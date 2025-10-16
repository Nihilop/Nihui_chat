-- modules/animations_lsglass.lua - Fade system adapted from ls_Glass
-- Credit: https://github.com/ls-/ls_Glass
local addonName, ns = ...

ns.Animations = {}

-----------
-- FADER --
-----------

do
    local function clamp(v)
        if v > 1 then return 1
        elseif v < 0 then return 0
        end
        return v
    end

    -- Out cubic easing for smooth animation
    local function outCubic(t, b, c, d)
        t = t / d - 1
        return clamp(c * (t ^ 3 + 1) + b)
    end

    local FADE_IN = 1
    local FADE_OUT = -1

    local fadingObjects = {}
    local add, remove

    local faderFrame = CreateFrame("Frame", "NihuiChatFader")
    local debugCount = 0

    local function faderFrame_OnUpdate(_, elapsed)
        for object, data in pairs(fadingObjects) do
            data.fadeTimer = data.fadeTimer + elapsed
            if data.fadeTimer > 0 then
                data.initAlpha = data.initAlpha or object:GetAlpha()

                local newAlpha = outCubic(
                    data.fadeTimer,
                    data.initAlpha,
                    data.finalAlpha - data.initAlpha,
                    data.duration
                )

                object:SetAlpha(newAlpha)

                -- Debug first few updates
                if debugCount < 5 and data.mode == FADE_IN then
                    debugCount = debugCount + 1
                    print("|cff00ff00Fade:|r timer=" .. string.format("%.2f", data.fadeTimer) .. " alpha=" .. string.format("%.2f", newAlpha) .. " dur=" .. data.duration)
                end

                if data.fadeTimer >= data.duration then
                    remove(object)

                    if data.callback then
                        data.callback(object)
                        data.callback = nil
                    end

                    object:SetAlpha(data.finalAlpha)
                end
            end
        end
    end

    function add(mode, object, delay, duration, callback)
        local initAlpha = object:GetAlpha()
        local finalAlpha = mode == FADE_IN and 1 or 0

        -- Skip if no animation needed
        if delay == 0 and (duration == 0 or initAlpha == finalAlpha) then
            if callback then
                callback(object)
            end
            return
        end

        fadingObjects[object] = {
            mode = mode,
            fadeTimer = -delay,
            finalAlpha = finalAlpha,
            duration = duration,
            callback = callback
        }

        if not faderFrame:GetScript("OnUpdate") then
            faderFrame:SetScript("OnUpdate", faderFrame_OnUpdate)
        end
    end

    function remove(object)
        fadingObjects[object] = nil

        if not next(fadingObjects) then
            faderFrame:SetScript("OnUpdate", nil)
        end
    end

    -- Public API
    function ns.Animations.FadeIn(object, duration, callback, delay)
        if not object then return end
        duration = duration or ns.Config.animations.fadeInDuration
        add(FADE_IN, object, delay or 0, duration * (1 - object:GetAlpha()), callback)
    end

    function ns.Animations.FadeOut(object, delay, duration, callback)
        if not object then return end
        duration = duration or ns.Config.animations.fadeOutDuration
        add(FADE_OUT, object, delay or 0, duration, callback)
    end

    function ns.Animations.StopFading(object, alpha)
        if not object then return end
        remove(object)
        object:SetAlpha(alpha or object:GetAlpha())
    end

    function ns.Animations.IsFading(object)
        local data = fadingObjects[object]
        if data then
            return data.mode
        end
    end
end

----------------------
-- CHAT INTEGRATION --
----------------------

local chatFrameFaders = {}

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

    if not fader then
        fader = {}
        chatFrameFaders[chatFrame] = fader
    end

    -- Schedule fade out
    fader.timer = C_Timer.NewTimer(delay, function()
        ns.Animations.FadeOut(chatFrame, 0, ns.Config.animations.fadeOutDuration)
        fader.timer = nil
    end)
end

local function CancelFadeOut(chatFrame)
    local fader = chatFrameFaders[chatFrame]
    if fader and fader.timer then
        fader.timer:Cancel()
        fader.timer = nil
    end

    -- Quick fade in
    ns.Animations.FadeIn(chatFrame, 0.2)
end

-- Hook a chat frame
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
function ns.Animations.Initialize()
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

    print("|cff1a9fc0Nihui Chat:|r Fade animations enabled (ls_Glass style)")
end

-- Cleanup
function ns.Animations.Disable()
    for chatFrame, fader in pairs(chatFrameFaders) do
        if fader.timer then
            fader.timer:Cancel()
        end
        ns.Animations.StopFading(chatFrame, 1.0)
    end
    chatFrameFaders = {}
end
