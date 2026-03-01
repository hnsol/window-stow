# Ryoiki.spoon

Window layout manager for Hammerspoon.
Define layouts as individual Lua files and apply them via hotkeys or a chooser menu.

## Installation

### Via [SpoonInstall](https://www.hammerspoon.org/Spoons/SpoonInstall.html) (recommended)

```lua
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.repos.masaki39 = {
    url = "https://github.com/masaki39/ryoiki",
    desc = "masaki39's Hammerspoon Spoons",
    branch = "main",
}
spoon.SpoonInstall:andUse("Ryoiki", {
    repo = "masaki39",
    config = {
        layouts_dir = os.getenv("HOME") .. "/.hammerspoon/layouts",
    },
    start = true,
    hotkeys = { showChooser = { {"ctrl", "alt"}, "space" } },
})
```
 
### Manual 

```bash
git clone https://github.com/masaki39/ryoiki
```

Then open `Spoons/Ryoiki.spoon.zip`, and  add to `~/.hammerspoon/init.lua`:

```lua
-- Ryoiki: window layout manager
hs.loadSpoon("Ryoiki")
spoon.Ryoiki.layouts_dir = "/path/to/your/layouts"  -- optional, see below
spoon.Ryoiki:start()
spoon.Ryoiki:bindHotkeys({ showChooser = { {"ctrl", "alt"}, "space" } })
```

## Layout Files

Each `.lua` file in your layouts directory defines one layout.
The filename (without extension) is used as the layout name.

### Where to put layout files

The default `layouts_dir` is `~/.hammerspoon/layouts/`.
If you place your layout files there, no `layouts_dir` setting is needed.

To store layouts in a dotfiles repository, set `layouts_dir` to that path:

```lua
spoon.Ryoiki.layouts_dir = os.getenv("HOME") .. "/dotfiles/hammerspoon/layouts"
```

Symlinks and regular files both work.

### Layout Properties

| Property | Required | Default | Description |
|---|---|---|---|
| `keybind` | optional | — | hotkey string e.g. `"ctrl+alt+1"` |
| `description` | optional | — | shown in chooser subtext |

### Window Properties

| Property | Required | Default | Description |
|---|---|---|---|
| `app` | **required** | — | application name (as shown in Activity Monitor) |
| `screen` | optional | `0` | 0-based screen index |
| `x` | optional | `0` | left edge as fraction of screen width (e.g. `0.5`) |
| `y` | optional | `0` | top edge as fraction of screen height (e.g. `0.5`) |
| `w` | optional | `1` | width as fraction of screen width (e.g. `0.7`) |
| `h` | optional | `1` | height as fraction of screen height (e.g. `1`) |
| `focus` | optional | `false` | focus this window after layout is applied |

### Finding your screen index

Run this in the Hammerspoon console to list all screens with their indices:

```lua
for i, s in ipairs(hs.screen.allScreens()) do
    print(i-1, s:name(), s:frame())
end
```

Index `0` is typically the primary display. The order follows macOS display arrangement settings.
If a nonexistent index is specified, Ryoiki falls back to the primary screen.

### Example: `layouts/coding.lua`

```lua
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
```

## Usage

| Action | Description |
|--------|-------------|
| `ctrl+alt+space` | Open chooser menu |
| `ctrl+alt+1` | Apply layout directly (if keybind set) |
| `spoon.Ryoiki:applyLayout("coding")` | Apply from Hammerspoon console |
| `spoon.Ryoiki:reloadConfig()` | Reload after editing layout files |


## Version Management

1. Update `obj.version` in `Ryoiki.spoon/init.lua`
2. Sync `version` in `docs/docs.json`
3. Regenerate the zip: `zip -r Spoons/Ryoiki.spoon.zip Ryoiki.spoon/`
4. Commit and tag: `git add -A && git commit && git tag v1.x`
5. Push to GitHub — SpoonInstall fetches from `raw/main/Spoons/Ryoiki.spoon.zip`
