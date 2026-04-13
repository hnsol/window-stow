-- reference.lua
return {
    keybind = "ctrl+alt+3",
    description = "Reference: Safari left, Notes right",
    windows = {
        { app = "com.apple.Safari", screen = 0, x = 0,   y = 0, w = 0.6, h = 1, focus = true },
        { app = "com.apple.Notes",  screen = 0, x = 0.6, y = 0, w = 0.4, h = 1 },
    },
}
