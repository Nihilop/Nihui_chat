# Nihui Chat

Clean chat frames with smooth fade in/out animations for World of Warcraft.

## Features

### Smooth Animations (ls_Glass style)
- **Fade In**: New messages smoothly fade in with a subtle slide-up animation
- **Fade Out**: Chat fades out after 30 seconds of inactivity (configurable)
- **Auto Restore**: Hovering over chat or new messages instantly restore full opacity
- **Configurable**: Adjust fade duration, delay, and slide distance

### Clean Styling
- **Minimal Design**: Clean backgrounds with subtle borders
- **Hidden Clutter**: Default Blizzard textures and buttons removed
- **Custom Fonts**: Modern font styling throughout
- **Tab Styling**: Clean tabs without background textures
- **Padding**: Generous padding for better readability

### Position Management
- **Movable Frames**: Drag tabs to move chat windows
- **Resizable**: Custom resize handle in bottom-right corner
- **Position Saving**: Positions saved between sessions
- **Lock/Unlock**: Lock frames in place when configured
- **Reset Option**: Reset to default Blizzard positions

### Blizzard Integration
- **Preserves Functionality**: All Blizzard features work normally (clicking, editing, etc.)
- **Edit Mode Compatible**: Works with WoW's Edit Mode
- **No Taint**: Secure implementation that doesn't break game functionality

## Commands

- `/nihuichat lock` - Lock chat frame positions
- `/nihuichat unlock` - Unlock chat frame positions
- `/nihuichat reset` - Reset all chat frames to default positions
- `/nihuichat fade on` - Enable fade animations
- `/nihuichat fade off` - Disable fade animations
- `/nihuichat refresh` - Refresh styling after config changes
- `/nihuichat help` - Show help

## Configuration

Edit `core/config.lua` to customize:

### Animation Settings
```lua
animations = {
    fadeInDuration = 0.25,      -- Fade in time (seconds)
    fadeOutDuration = 0.5,      -- Fade out time (seconds)
    fadeOutDelay = 30,          -- Time before fade out (0 = never)
    slideDistance = 8,          -- Slide distance (pixels)
    enabled = true,             -- Enable/disable animations
}
```

### Style Settings
```lua
style = {
    background = {
        enabled = true,
        color = { r = 0, g = 0, b = 0, a = 0.4 },
    },
    border = {
        enabled = true,
        color = { r = 0, g = 0, b = 0, a = 0.8 },
        thickness = 1,
    },
    font = {
        face = "Fonts\\FRIZQT__.TTF",
        size = 13,
        flags = "",
    },
}
```

## Installation

1. Extract to `World of Warcraft\_retail_\Interface\AddOns\`
2. Restart WoW or type `/reload`
3. Type `/nihuichat` for options

## Credits

- Inspired by [ls_Glass](https://github.com/ls-/ls_Glass) by ls-
- Part of the Nihui addon suite

## Version

1.0.0 - Initial release
