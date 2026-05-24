# WindowStow.spoon

Window layout manager for [Hammerspoon](https://www.hammerspoon.org/).  
Define multi-screen window layouts as Lua files, and apply them via hotkeys, a chooser menu, or URL scheme.

![chooser](./assets/chooser.png)

- Layout files are plain Lua — easy to edit and version-control
- Apply layouts by hotkey or from the chooser
- Address screens by name (`"primary"`, `"built-in"`, `"LG"`) or 0-based index
- Built-in actions for common window management tasks
- URL scheme support for launching actions from Alfred, Raycast, etc.

> Forked from [masaki39/ryoiki](https://github.com/masaki39/ryoiki)

---

## 📦 Installation

Install [Hammerspoon](https://www.hammerspoon.org/) first:

```bash
brew install --cask hammerspoon
```

Download [WindowStow.spoon.zip](https://github.com/hnsol/window-stow/raw/main/Spoons/WindowStow.spoon.zip), open it to install, then add to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("WindowStow")
spoon.WindowStow:start()
spoon.WindowStow:bindHotkeys({
    showChooser = { {"ctrl", "alt"}, "m" },
})
```

---

## 📁 Layout Files

Each `.lua` file in your layouts directory defines one layout.  
The filename (without extension) becomes the layout name shown in the chooser.  
Default directory: `~/.hammerspoon/layouts/`

```lua
spoon.WindowStow.layouts_dir = "/path/to/your/layouts"  -- override if needed
```

### Example: `layouts/coding.lua`

```lua
return {
    keybind = "ctrl+alt+1",
    description = "Dev: Safari left, Terminal split right",
    windows = {
        { app = "com.apple.Safari",   screen = "primary", x = 0,   y = 0,   w = 0.7, h = 1   },
        { app = "com.apple.Terminal", screen = "primary", x = 0.7, y = 0,   w = 0.3, h = 0.5, focus = true },
        { app = "com.apple.Terminal", screen = "primary", x = 0.7, y = 0.5, w = 0.3, h = 0.5 },
    },
}
```

### Window Properties

| Property | Required | Default | Description |
|---|---|---|---|
| `app` | **required** | — | Application bundle ID (e.g. `com.apple.Safari`) |
| `screen` | optional | `0` | `0`-based index, `"primary"`, `"built-in"`, or partial display name (e.g. `"LG"`) |
| `x` | optional | `0` | Left edge as fraction of screen width |
| `y` | optional | `0` | Top edge as fraction of screen height |
| `w` | optional | `1` | Width as fraction of screen width |
| `h` | optional | `1` | Height as fraction of screen height |
| `focus` | optional | `false` | Focus this window after layout is applied |

> [!TIP]
> Find an app's bundle ID:
> ```bash
> osascript -e 'id of app "Safari"'
> ```

> [!TIP]
> List screen indices and names in the Hammerspoon console:
> ```lua
> for i, s in ipairs(hs.screen.allScreens()) do print(i-1, s:name()) end
> ```

---

## ⚡ Built-in Actions

Always available from the chooser — no layout file needed.

| Action | Description |
|---|---|
| **Tile All** | Arrange all visible windows on the cursor screen in a grid |
| **Maximize All** | Maximize all visible windows |
| **Unhide All** | Restore all hidden application windows |
| **Cascade Windows** | Stagger visible windows diagonally on screen (see below) |
| **Save Current Layout** | Capture current window positions and save as a layout file |
| **Delete Layout** | Delete an existing layout file |

---

## 🌊 Cascade Windows

Arranges all visible non-Finder windows on the cursor screen in a diagonal cascade from top-left to bottom-right.

![tile-all](./assets/tile-all.gif)

**How it works:**

- Windows are sorted by position — the window closest to the top-left goes first
- Each window is offset slightly right and down from the previous one
- 5% margin on left, top, and right; no margin on the bottom
- Z-order matches position order: the top-left window is frontmost, the bottom-right window is furthest back
- Non-cascade windows (excluded by you or Finder) are placed behind all cascade windows

**Chooser UI:**

When you select Cascade Windows, a sub-chooser opens where you can control the order and inclusion of each window:

```
Apply Cascade (3 windows)    2 ordered + 1 auto
1 Safari — GitHub            Ordered — → to exclude  ← to remove order
2 Terminal — zsh
○ Slack — #general           Auto-included — → to order  ← to exclude
✗ Arc                        Excluded — → to include  ← to order
```

| State | Prefix | Meaning |
|---|---|---|
| Ordered | `1`, `2`, … | Cascaded first, in this order |
| Auto-included | `○` | Cascaded after ordered windows, in screen position order |
| Excluded | `✗` | Not cascaded |

**Controls in the chooser:**

| Key | Action |
|---|---|
| `→` or click | Advance state: auto → ordered → excluded → auto |
| `←` | Reverse state: auto → excluded → ordered → auto |
| `↑` / `↓` | Navigate the list |
| `Ctrl+P` / `Ctrl+N` | Navigate the list (Emacs-style) |
| `Enter` | Confirm selection / apply cascade |
| `Esc` | Cancel |

**Stagger amount:**

By default, the stagger is calculated automatically from screen width (20–60 px). Override:

```lua
spoon.WindowStow.cascadeStagger = 40  -- pixels
```

---

## ⌨️ Hotkeys

```lua
spoon.WindowStow:bindHotkeys({
    showChooser    = { {"ctrl", "alt"}, "m" },
    tileAll        = { {"ctrl", "alt"}, "t" },
    maximizeAll    = { {"ctrl", "alt"}, "f" },
    unhideAll      = { {"ctrl", "alt"}, "u" },
    cascadeWindows = { {"ctrl", "alt"}, "c" },
    saveLayout     = { {"ctrl", "alt"}, "s" },
    deleteLayout   = { {"ctrl", "alt"}, "d" },
})
```

---

## 🔗 URL Scheme

Trigger actions from Alfred, Raycast, scripts, or any app that can open URLs.

```lua
spoon.WindowStow:bindURLEvents({
    cascadeWindows = "cascadeWindows",  -- hammerspoon://cascadewindows
    showChooser    = "windowStow",      -- hammerspoon://windowstow
    tileAll        = "tileAll",         -- hammerspoon://tileall
})
```

> [!NOTE]
> Hammerspoon converts URL event names to lowercase, so `hammerspoon://cascadeWindows` and `hammerspoon://cascadewindows` both work.

**Alfred example:**

Create a Keyword workflow step with no argument, then add an Open URL action pointing to `hammerspoon://cascadewindows`.

---

## ⚙️ Configuration Reference

```lua
hs.loadSpoon("WindowStow")

spoon.WindowStow.layouts_dir    = os.getenv("HOME") .. "/.hammerspoon/layouts"
spoon.WindowStow.centerCursor   = true   -- move cursor to focused window after layout apply
spoon.WindowStow.cascadeStagger = nil    -- stagger in px; nil = auto (20–60 px based on screen width)

spoon.WindowStow:start()
spoon.WindowStow:bindHotkeys({ showChooser = { {"ctrl", "alt"}, "m" } })
spoon.WindowStow:bindURLEvents({ cascadeWindows = "cascadeWindows" })
```

---

## 🏷️ Version Management (for developers)

```bash
chmod +x version.sh   # first time only
./version.sh patch    # patch bump (default)
./version.sh minor    # minor bump
./version.sh major    # major bump
git push && git push --tags
```

---

## 📄 License

MIT — forked from [masaki39/ryoiki](https://github.com/masaki39/ryoiki)
