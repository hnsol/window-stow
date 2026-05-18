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

local parser = _require("parser")
local hotkeys = _require("hotkeys")
local layout = _require("layout")
local chooser = _require("chooser")

-- Spoon object
local obj = {}
obj.__index = obj

obj.name = "Ryoiki"
obj.version = "2.1.2"
obj.author = "masaki39"
obj.license = "MIT"

-- Directory containing *.lua layout files; caller can override before :start()
obj.layouts_dir = hs.configdir .. "/layouts"

-- Internal state
obj._layouts       = {} -- array of parsed layout tables
obj._layoutHotkeys = {} -- hs.hotkey objects for per-layout keybinds (rebuilt on reloadConfig)
obj._spoonHotkeys  = {} -- hs.hotkey objects for spoon-level bindings (showChooser etc.)
obj._chooser       = nil -- chooser instance

obj.centerCursor = false -- move cursor to center of focused window after layout apply

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

-- Bind per-layout hotkeys (stored in _layoutHotkeys)
function obj:_bindLayoutHotkeys()
	local bindings = {}
	for _, ld in ipairs(self._layouts) do
		if ld.keybind then
			local name = ld.name
			bindings[#bindings + 1] = {
				combo = ld.keybind,
				fn = function()
					self:applyLayout(name)
				end,
			}
		end
	end
	self._layoutHotkeys = hotkeys.bindAll(bindings)
end

-- Start the spoon: load config, bind hotkeys, create chooser
function obj:start()
	self:_loadLayouts()
	self:_bindLayoutHotkeys()

	local builtins = {
		{ name = "Tile All",     description = "Arrange visible windows in a grid on the main screen" },
		{ name = "Maximize All", description = "Maximize all visible windows" },
		{ name = "Unhide All",   description = "Restore all hidden application windows" },
	}

	self._chooser = chooser.new(function()
		return self._layouts
	end, function(name)
		self:applyLayout(name)
	end, builtins)

	return self
end

-- Stop: delete all hotkeys, destroy chooser, cancel pending layout timers
function obj:stop()
	layout.cancelPending()
	hotkeys.deleteAll(self._layoutHotkeys)
	hotkeys.deleteAll(self._spoonHotkeys)
	self._layoutHotkeys = {}
	self._spoonHotkeys  = {}

	if self._chooser then
		self._chooser.destroy()
		self._chooser = nil
	end

	return self
end

-- Bind additional hotkeys — stored in _spoonHotkeys
-- map: { showChooser = { mods, key }, tileAll = { mods, key }, maximizeAll = { mods, key }, unhideAll = { mods, key } }
function obj:bindHotkeys(map)
	local actions = {
		showChooser = function() if self._chooser then self._chooser.show() end end,
		tileAll     = function() self:tileAll() end,
		maximizeAll = function() self:maximizeAll() end,
		unhideAll   = function() self:unhideAll() end,
	}
	for action, fn in pairs(actions) do
		if map[action] then
			local mods, key = map[action][1], map[action][2]
			self._spoonHotkeys[#self._spoonHotkeys + 1] = hs.hotkey.bind(mods, key, fn)
		end
	end
	return self
end

-- Apply a layout by name, or a built-in action name
function obj:applyLayout(name)
	if name == "Tile All"     then return self:tileAll() end
	if name == "Maximize All" then return self:maximizeAll() end
	if name == "Unhide All"   then return self:unhideAll() end
	for _, ld in ipairs(self._layouts) do
		if ld.name == name then
			layout.apply(ld, { centerCursor = self.centerCursor })
			return
		end
	end
	hs.notify.show("Ryoiki", "", "Layout not found: " .. tostring(name))
end

-- Arrange all visible standard windows on the main screen in a grid
function obj:tileAll()
	local screen = hs.screen.find(hs.mouse.absolutePosition()) or hs.screen.mainScreen()
	local sf = screen:frame()
	local windows = {}
	for _, win in ipairs(hs.window.visibleWindows()) do
		if win:isStandard() and win:screen() == screen then
			windows[#windows + 1] = win
		end
	end
	local n = #windows
	if n == 0 then return self end
	local cols = math.ceil(math.sqrt(n))
	local rows = math.ceil(n / cols)
	local w = sf.w / cols
	local h = sf.h / rows
	for i, win in ipairs(windows) do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		win:setFrame({ x = sf.x + col * w, y = sf.y + row * h, w = w, h = h }, 0)
	end
	return self
end

-- Maximize all visible standard windows
function obj:maximizeAll()
	for _, win in ipairs(hs.window.visibleWindows()) do
		if win:isStandard() then win:maximize(0) end
	end
	return self
end

-- Unhide all running GUI applications
function obj:unhideAll()
	for _, app in ipairs(hs.application.runningApplications()) do
		if app:kind() == 1 then app:unhide() end
	end
	return self
end

-- Reload layouts and rebind layout hotkeys only (spoon hotkeys preserved)
function obj:reloadConfig()
	layout.cancelPending()
	hotkeys.deleteAll(self._layoutHotkeys)
	self._layoutHotkeys = {}
	self:_loadLayouts()
	self:_bindLayoutHotkeys()
	-- Keep chooser alive; it pulls layouts lazily via getLayouts()
end

return obj
