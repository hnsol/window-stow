-- Ryoiki.spoon/init.lua
-- Spoon entry point for Ryoiki

-- Resolve the directory containing this file so we can dofile sibling modules
local _spoonDir = (function()
    local info = debug.getinfo(1, "S")
    local src = info.source:match("^@(.+)$") or info.source
    return src:match("^(.+)/[^/]+$") or "."
end)()

local function _require(name)
    return dofile(_spoonDir .. "/" .. name .. ".lua")
end

local parser  = _require("parser")
local hotkeys = _require("hotkeys")
local layout  = _require("layout")
local chooser = _require("chooser")

-- Spoon object
local obj = {}
obj.__index = obj

obj.name    = "Ryoiki"
obj.version = "1.0"
obj.author  = "masaki39"
obj.license = "MIT"

-- Directory containing *.kdl layout files; caller can override before :start()
obj.layouts_dir = hs.configdir .. "/layouts"

-- Internal state
obj._layouts  = {}   -- array of parsed layout tables
obj._hotkeys  = {}   -- hs.hotkey objects bound by this spoon
obj._chooser  = nil  -- chooser instance

-- Load (or reload) layouts from layouts_dir
function obj:_loadLayouts()
    local ok, result = pcall(parser.loadDir, self.layouts_dir)
    if ok then
        self._layouts = result
    else
        hs.notify.show("Ryoiki", "", "Failed to load layouts: " .. tostring(result))
        self._layouts = {}
    end
end

-- Bind per-layout hotkeys
function obj:_bindLayoutHotkeys()
    local bindings = {}
    for _, ld in ipairs(self._layouts) do
        if ld.keybind then
            local name = ld.name
            bindings[#bindings + 1] = {
                combo = ld.keybind,
                fn = function() self:applyLayout(name) end,
            }
        end
    end
    local newKeys = hotkeys.bindAll(bindings)
    for _, hk in ipairs(newKeys) do
        self._hotkeys[#self._hotkeys + 1] = hk
    end
end

-- Start the spoon: load config, bind hotkeys, create chooser
function obj:start()
    self:_loadLayouts()
    self:_bindLayoutHotkeys()

    self._chooser = chooser.new(
        function() return self._layouts end,
        function(name) self:applyLayout(name) end
    )

    return self
end

-- Stop: delete hotkeys, destroy chooser
function obj:stop()
    hotkeys.deleteAll(self._hotkeys)
    self._hotkeys = {}

    if self._chooser then
        self._chooser.destroy()
        self._chooser = nil
    end

    return self
end

-- Bind additional hotkeys (e.g. showChooser)
-- map: { showChooser = { mods, key } }
function obj:bindHotkeys(map)
    if map.showChooser then
        local mods, key = map.showChooser[1], map.showChooser[2]
        local hk = hs.hotkey.bind(mods, key, function()
            if self._chooser then self._chooser.show() end
        end)
        self._hotkeys[#self._hotkeys + 1] = hk
    end
    return self
end

-- Apply a layout by name
function obj:applyLayout(name)
    for _, ld in ipairs(self._layouts) do
        if ld.name == name then
            layout.apply(ld)
            return
        end
    end
    hs.notify.show("Ryoiki", "", "Layout not found: " .. tostring(name))
end

-- Reload layouts and rebind hotkeys
function obj:reloadConfig()
    hotkeys.deleteAll(self._hotkeys)
    self._hotkeys = {}
    self:_loadLayouts()
    self:_bindLayoutHotkeys()
    -- Keep chooser alive; it pulls layouts lazily via getLayouts()
end

return obj
