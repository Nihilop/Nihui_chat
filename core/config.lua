-- core/config.lua - Configuration for Nihui_chat
local addonName, ns = ...

ns.Config = {
    -- Animation settings
    animations = {
        fadeInDuration = 2.0,          -- Duration of fade in animation (seconds) -- TEMP: 2.0 for testing
        fadeOutDuration = 0.6,          -- Duration of fade out animation (seconds)
        fadeOutDelay = 30,              -- Delay before fading out (seconds, 0 = never fade out)
        slideDistance = 8,              -- Distance to slide up during fade in (pixels)
        enabled = true,                 -- Enable/disable animations
    },

    -- Styling settings
    style = {
        -- Background atlas
        background = {
            enabled = true,
            useAtlas = true,
            atlas = "Adventures-Missions-Shadow",
            alpha = 0.8,
            color = { r = 1, g = 1, b = 1, a = 1 },  -- Color tint (white = no tint)
        },

        -- Gradient background (disabled - using atlas instead)
        gradient = {
            enabled = false,
            colorStart = { r = 0, g = 0, b = 0, a = 0.6 },
            colorEnd = { r = 0, g = 0, b = 0, a = 0 },
        },

        -- Border (disabled for clean look)
        border = {
            enabled = false,
            color = { r = 0, g = 0, b = 0, a = 0.8 },
            texture = "Interface\\Buttons\\WHITE8X8",
            thickness = 1,
        },

        -- Font
        font = {
            face = "Fonts\\FRIZQT__.TTF",
            size = 13,
            flags = "",  -- "OUTLINE", "THICKOUTLINE", "MONOCHROME", or ""
        },

        -- Padding (for individual message lines)
        padding = {
            left = 8,
            right = 8,
            top = 2,     -- Reduced for tighter message spacing
            bottom = 2,  -- Reduced for tighter message spacing
        },

        -- Tab styling
        tabs = {
            hideBackground = true,
            fontSize = 12,
        },

        -- Edit box (detached like Nihui_cb style)
        editBox = {
            position = "BOTTOM",  -- "TOP", "BOTTOM", "HIDE"
            height = 28,
            offset = 4,           -- Distance from chat frame
            background = {
                enabled = true,
                color = { r = 0, g = 0, b = 0, a = 0.7 },
            },
            border = {
                enabled = false,
            },
        },
    },

    -- Positioning settings
    position = {
        locked = false,                 -- Lock chat frame position
        savePosition = true,            -- Save position between sessions
    },

    -- Chat features
    features = {
        urlCopy = true,                 -- Enable URL copying
        mouseScroll = true,             -- Enable mouse wheel scrolling
        timestamps = true,              -- Show timestamps
        timestampFormat = "[%H:%M]",    -- Timestamp format
        fadeOnInactive = true,          -- Fade out when inactive
    },
}

-- Default saved variables (will be merged with saved data)
ns.DefaultDB = {
    version = 1,
    profiles = {
        Default = {
            animations = ns.Config.animations,
            style = ns.Config.style,
            position = ns.Config.position,
            features = ns.Config.features,
        },
    },
    currentProfile = "Default",
}
