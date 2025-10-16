-- core/init.lua - Main initialization for Nihui_chat
local addonName, ns = ...

-- Create addon object
local NihuiChat = CreateFrame("Frame")
NihuiChat:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        self[event](self, ...)
    end
end)

-- Register events
NihuiChat:RegisterEvent("ADDON_LOADED")
NihuiChat:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Initialize saved variables
function NihuiChat:ADDON_LOADED(loadedAddon)
    if loadedAddon ~= addonName then
        return
    end

    -- Initialize saved variables
    if not NihuiChatDB then
        NihuiChatDB = CopyTable(ns.DefaultDB)
    else
        -- Merge with defaults (in case new settings were added)
        for key, value in pairs(ns.DefaultDB) do
            if NihuiChatDB[key] == nil then
                NihuiChatDB[key] = value
            end
        end
    end

    -- Load current profile settings
    -- TEMP: Disabled for testing - saved variables overwrite config.lua changes
    --[[
    local profile = NihuiChatDB.profiles[NihuiChatDB.currentProfile]
    if profile then
        if profile.animations then
            for k, v in pairs(profile.animations) do
                ns.Config.animations[k] = v
            end
        end
        if profile.style then
            for k, v in pairs(profile.style) do
                if type(v) == "table" then
                    ns.Config.style[k] = ns.Config.style[k] or {}
                    for sk, sv in pairs(v) do
                        ns.Config.style[k][sk] = sv
                    end
                else
                    ns.Config.style[k] = v
                end
            end
        end
        if profile.position then
            for k, v in pairs(profile.position) do
                ns.Config.position[k] = v
            end
        end
        if profile.features then
            for k, v in pairs(profile.features) do
                ns.Config.features[k] = v
            end
        end
    end
    --]]

    print("|cff1a9fc0Nihui Chat|r loaded. Type /nihuichat for options.")

    self:UnregisterEvent("ADDON_LOADED")
end

-- Initialize addon after entering world
function NihuiChat:PLAYER_ENTERING_WORLD(isLogin, isReload)
    print("|cff1a9fc0DEBUG:|r PLAYER_ENTERING_WORLD fired")

    -- Wait a bit for chat system to be fully loaded
    C_Timer.After(0.5, function()
        print("|cff1a9fc0DEBUG:|r Starting module initialization...")

        -- Initialize all modules in order with error handling
        if ns.Styling then
            print("|cff1a9fc0DEBUG:|r Initializing Styling...")
            local success, err = pcall(ns.Styling.Initialize)
            if not success then
                print("|cffff0000ERROR:|r Styling.Initialize failed: " .. tostring(err))
            else
                print("|cff00ff00SUCCESS:|r Styling initialized")
            end
        else
            print("|cffff0000ERROR:|r ns.Styling is nil!")
        end

        if ns.Position then
            print("|cff1a9fc0DEBUG:|r Initializing Position...")
            local success, err = pcall(ns.Position.Initialize)
            if not success then
                print("|cffff0000ERROR:|r Position.Initialize failed: " .. tostring(err))
            else
                print("|cff00ff00SUCCESS:|r Position initialized")
            end
        else
            print("|cffff0000ERROR:|r ns.Position is nil!")
        end

        -- Initialize animations (frame fade for background)
        if ns.Animations then
            print("|cff1a9fc0DEBUG:|r Initializing Frame Animations...")
            local success, err = pcall(ns.Animations.Initialize)
            if not success then
                print("|cffff0000ERROR:|r Animations.Initialize failed: " .. tostring(err))
            else
                print("|cff00ff00SUCCESS:|r Frame Animations initialized")
            end
        else
            print("|cffff0000ERROR:|r ns.Animations is nil!")
        end

        -- Initialize message handler (per-message animations)
        if ns.MessageHandler then
            print("|cff1a9fc0DEBUG:|r Initializing Message Handler...")
            local success, err = pcall(ns.MessageHandler.Initialize)
            if not success then
                print("|cffff0000ERROR:|r MessageHandler.Initialize failed: " .. tostring(err))
            else
                print("|cff00ff00SUCCESS:|r Message Handler initialized")
            end
        else
            print("|cffff0000ERROR:|r ns.MessageHandler is nil!")
        end

        print("|cff1a9fc0Nihui Chat|r initialized successfully!")
    end)

    -- Only do this once
    if isLogin or isReload then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end

-- Slash commands
SLASH_NIHUICHAT1 = "/nihuichat"
SLASH_NIHUICHAT2 = "/nchat"
SlashCmdList["NIHUICHAT"] = function(msg)
    local command, arg = strsplit(" ", msg:lower(), 2)

    if command == "lock" then
        ns.Position.SetLocked(true)
    elseif command == "unlock" then
        ns.Position.SetLocked(false)
    elseif command == "reset" then
        ns.Position.ResetAll()
    elseif command == "fade" then
        if arg == "on" then
            ns.Config.animations.enabled = true
            ns.Config.features.fadeOnInactive = true
            print("|cff1a9fc0Nihui Chat:|r Fade animations enabled")
        elseif arg == "off" then
            ns.Config.animations.enabled = false
            ns.Config.features.fadeOnInactive = false
            print("|cff1a9fc0Nihui Chat:|r Fade animations disabled")
            -- Reset all frames to full opacity
            for i = 1, NUM_CHAT_WINDOWS do
                local chatFrame = _G["ChatFrame" .. i]
                if chatFrame then
                    chatFrame:SetAlpha(1)
                end
            end
        else
            print("|cff1a9fc0Nihui Chat:|r Usage: /nihuichat fade [on|off]")
        end
    elseif command == "style" or command == "refresh" then
        if ns.Styling then
            ns.Styling.Refresh()
            print("|cff1a9fc0Nihui Chat:|r Style refreshed")
        end
    elseif command == "help" or command == "" then
        print("|cff1a9fc0Nihui Chat|r commands:")
        print("  |cff1a9fc0/nihuichat lock|r - Lock chat frame positions")
        print("  |cff1a9fc0/nihuichat unlock|r - Unlock chat frame positions")
        print("  |cff1a9fc0/nihuichat reset|r - Reset all chat frames to default")
        print("  |cff1a9fc0/nihuichat fade [on|off]|r - Toggle fade animations")
        print("  |cff1a9fc0/nihuichat refresh|r - Refresh styling")
        print("  |cff1a9fc0/nihuichat help|r - Show this help")
    else
        print("|cff1a9fc0Nihui Chat:|r Unknown command. Type /nihuichat help for options.")
    end
end

-- Export addon object
ns.NihuiChat = NihuiChat
