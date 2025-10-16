-- modules/position.lua - Position management and saving for chat frames
local addonName, ns = ...

ns.Position = {}

-- Save frame position to saved variables
local function SavePosition(chatFrame)
    if not ns.Config.position.savePosition then
        return
    end

    local frameName = chatFrame:GetName()
    local frameID = chatFrame:GetID()

    -- Get current position
    local point, relativeTo, relativePoint, x, y = chatFrame:GetPoint(1)
    local width = chatFrame:GetWidth()
    local height = chatFrame:GetHeight()

    -- Initialize saved positions if needed
    if not NihuiChatDB then
        NihuiChatDB = {}
    end

    if not NihuiChatDB.positions then
        NihuiChatDB.positions = {}
    end

    -- Save position data
    NihuiChatDB.positions[frameID] = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
        width = width,
        height = height,
    }
end

-- Load saved position for a frame
local function LoadPosition(chatFrame)
    if not ns.Config.position.savePosition or not NihuiChatDB or not NihuiChatDB.positions then
        return false
    end

    local frameID = chatFrame:GetID()
    local savedPos = NihuiChatDB.positions[frameID]

    if not savedPos then
        return false
    end

    -- Apply saved position
    chatFrame:ClearAllPoints()
    chatFrame:SetPoint(
        savedPos.point or "BOTTOMLEFT",
        UIParent,
        savedPos.relativePoint or "BOTTOMLEFT",
        savedPos.x or 0,
        savedPos.y or 0
    )

    -- Apply saved size
    if savedPos.width and savedPos.height then
        chatFrame:SetSize(savedPos.width, savedPos.height)
    end

    return true
end

-- Lock/unlock chat frame position
function ns.Position.SetLocked(locked)
    ns.Config.position.locked = locked

    -- Update all frames
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            local tab = _G[chatFrame:GetName() .. "Tab"]
            if tab then
                if locked then
                    tab:SetScript("OnDragStart", nil)
                    tab:SetScript("OnDragStop", nil)
                else
                    tab:SetScript("OnDragStart", function(self)
                        FCF_StartDragging(chatFrame)
                    end)
                    tab:SetScript("OnDragStop", function(self)
                        FCF_StopDragging(chatFrame)
                        SavePosition(chatFrame)
                    end)
                end
            end

            -- Also update resize handle
            if chatFrame.nihuiResizeHandle then
                if locked then
                    chatFrame.nihuiResizeHandle:Hide()
                else
                    chatFrame.nihuiResizeHandle:Show()
                end
            end
        end
    end

    print("|cff1a9fc0Nihui Chat:|r Frame positions " .. (locked and "locked" or "unlocked"))
end

-- Reset frame to default position
function ns.Position.ResetFrame(chatFrame)
    local frameID = chatFrame:GetID()

    -- Clear saved position
    if NihuiChatDB and NihuiChatDB.positions then
        NihuiChatDB.positions[frameID] = nil
    end

    -- Use Blizzard's reset
    FCF_ResetChatWindows()

    -- Reapply our styling
    if ns.Styling then
        C_Timer.After(0.1, function()
            ns.Styling.ApplyToFrame(chatFrame)
        end)
    end
end

-- Reset all frames to default positions
function ns.Position.ResetAll()
    if NihuiChatDB then
        NihuiChatDB.positions = {}
    end

    FCF_ResetChatWindows()

    -- Reapply styling to all frames
    if ns.Styling then
        C_Timer.After(0.1, function()
            for i = 1, NUM_CHAT_WINDOWS do
                local chatFrame = _G["ChatFrame" .. i]
                if chatFrame then
                    ns.Styling.ApplyToFrame(chatFrame)
                end
            end
        end)
    end

    print("|cff1a9fc0Nihui Chat:|r All chat frames reset to default positions")
end

-- Hook into Blizzard's position saving
function ns.Position.Initialize()
    -- Hook frame resizing
    hooksecurefunc("FCF_SavePositionAndDimensions", function(chatFrame)
        if chatFrame and chatFrame.nihuiStyled then
            SavePosition(chatFrame)
        end
    end)

    -- Hook EditMode to save position when it's closed
    if EditModeManagerFrame then
        EditModeManagerFrame:HookScript("OnHide", function()
            -- Save all chat frame positions after EditMode is closed
            for i = 1, NUM_CHAT_WINDOWS do
                local chatFrame = _G["ChatFrame" .. i]
                if chatFrame and chatFrame:IsShown() then
                    C_Timer.After(0.1, function()
                        SavePosition(chatFrame)
                    end)
                end
            end
        end)
    end

    -- Load saved positions
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame:IsShown() then
            -- Try to load saved position
            if not LoadPosition(chatFrame) then
                -- If no saved position, save current position
                SavePosition(chatFrame)
            end
        end
    end

    -- Apply lock state
    if ns.Config.position.locked then
        ns.Position.SetLocked(true)
    end
end
