# Ryoiki.spoon

Window layout manager for Hammerspoon.
Define layouts as individual KDL files and apply them via hotkeys or a chooser menu.

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

### Manual (symlink, for local development)

```bash
# Clone the repo
git clone https://github.com/masaki39/ryoiki ~/ghq/github.com/masaki39/ryoiki

# Symlink the spoon
ln -sf ~/ghq/github.com/masaki39/ryoiki/Ryoiki.spoon ~/.hammerspoon/Spoons/Ryoiki.spoon
```

Then add to `~/.hammerspoon/init.lua`:

```lua
-- Ryoiki: window layout manager
hs.loadSpoon("Ryoiki")
spoon.Ryoiki.layouts_dir = "/path/to/your/layouts"  -- optional, see below
spoon.Ryoiki:start()
spoon.Ryoiki:bindHotkeys({ showChooser = { {"ctrl", "alt"}, "space" } })
```

## Layout Files

Each `.kdl` file in your layouts directory defines one layout.
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
| `menu_key` | optional | — | single character; typing it in the chooser instantly applies the layout |
| `description` | optional | — | shown in chooser subtext |
| `hide_others` | optional | `false` | hide apps not in this layout |

### Window Properties

| Property | Required | Default | Description |
|---|---|---|---|
| `app` | **required** | — | application name (as shown in Activity Monitor) |
| `screen` | optional | `0` | 0-based screen index |
| `x` | optional | `0` | left edge (`"50%"` or `0.5`) |
| `y` | optional | `0` | top edge |
| `w` | optional | `1` | width |
| `h` | optional | `1` | height |
| `reuse` | optional | `true` | reuse an existing window of that app |
| `focus` | optional | `false` | focus this window after layout is applied |

> **Note**: `reuse false` requests a new window, but relies on the app creating one automatically after `launchOrFocus`. Apps that don't open a new window on re-launch (e.g. single-window apps) will have their existing window repositioned instead.

### Finding your screen index

Run this in the Hammerspoon console to list all screens with their indices:

```lua
for i, s in ipairs(hs.screen.allScreens()) do
    print(i-1, s:name(), s:frame())
end
```

Index `0` is typically the primary display. The order follows macOS display arrangement settings.
If a nonexistent index is specified, Ryoiki falls back to the primary screen.

### Example: `layouts/coding.kdl`

```kdl
// coding.kdl
keybind "ctrl+alt+1"
menu_key "1"
description "Dev: Chrome left, Ghostty split right"
hide_others false

window {
    app "Google Chrome"
    screen 0
    x "0%"
    y "0%"
    w "70%"
    h "100%"
    reuse true
    focus false
}
window {
    app "Ghostty"
    screen 0
    x "70%"
    y "0%"
    w "30%"
    h "50%"
    reuse true
    focus true
}
window {
    app "Ghostty"
    screen 0
    x "70%"
    y "50%"
    w "30%"
    h "50%"
    reuse false
}
```

## Usage

| Action | Description |
|--------|-------------|
| `ctrl+alt+space` | Open chooser menu |
| `ctrl+alt+1` | Apply layout directly (if keybind set) |
| Type `menu_key` in chooser | Instantly apply layout without pressing Enter |
| `spoon.Ryoiki:applyLayout("coding")` | Apply from Hammerspoon console |
| `spoon.Ryoiki:reloadConfig()` | Reload after editing layout files |
| `spoon.Ryoiki.verbose = true` | Show progress alerts while applying layouts |

## SpoonInstall Tips

After adding or changing the `masaki39` repo config, run the following in the Hammerspoon console to fetch the latest metadata:

```lua
spoon.SpoonInstall:asyncUpdateAllRepos()
```

To reload your Hammerspoon config after editing layout files or `init.lua`:

```lua
hs.reload()
-- or, to reload only Ryoiki layouts without a full restart:
spoon.Ryoiki:reloadConfig()
```

## Version Management

1. Update `obj.version` in `Ryoiki.spoon/init.lua`
2. Sync `version` in `docs/docs.json`
3. Regenerate the zip: `zip -r Spoons/Ryoiki.spoon.zip Ryoiki.spoon/`
4. Commit and tag: `git add -A && git commit && git tag v1.x`
5. Push to GitHub — SpoonInstall fetches from `raw/main/Spoons/Ryoiki.spoon.zip`
