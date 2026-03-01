-- coding.lua
return {
    keybind = "ctrl+alt+1",
    description = "Dev: Safari left, Terminal split right",
    windows = {
        { app = "Safari",   screen = 0, x = 0,   y = 0,   w = 0.7, h = 1   },
        { app = "Terminal", screen = 0, x = 0.7, y = 0,   w = 0.3, h = 0.5, focus = true },
        { app = "Terminal", screen = 0, x = 0.7, y = 0.5, w = 0.3, h = 0.5 },
    },
}
