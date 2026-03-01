-- layout.lua
-- Layout engine for Ryoiki.spoon

local M = {}

-- Resolve a value to absolute pixels given a dimension (width or height).
-- Accepts:
--   number 0.0..1.0  → treated as fraction of dimension
--   number > 1       → treated as absolute pixels
local function resolveValue(value, dimension)
    if type(value) == "number" then
        if value >= 0 and value <= 1 then
            return math.floor(value * dimension + 0.5)
        else
            return math.floor(value + 0.5)
        end
    end
    return 0
end

-- Get screen by 0-based index. Falls back to primary screen.
local function getScreen(index)
    local screens = hs.screen.allScreens()
    local screen = screens[index + 1] -- Lua 1-based
    return screen or hs.screen.primaryScreen()
end

-- Find a window for appName that is NOT in claimedIds.
-- Returns the window or nil.
local function findUnclaimedWindow(appName, claimedIds)
    local app = hs.application.get(appName)
    if not app then return nil end

    for _, win in ipairs(app:allWindows()) do
        -- Skip non-standard windows (sheets, drawers, etc.)
        if win:isStandard() and not claimedIds[win:id()] then
            return win
        end
    end
    return nil
end

-- Async: poll until a standard window for appName appears, or timeout (seconds) is reached.
-- Calls callback(win) with the window or nil.
local function waitForWindowAsync(appName, claimedIds, timeout, callback)
    local interval = 0.05
    local elapsed = 0
    local timer
    timer = hs.timer.new(interval, function()
        elapsed = elapsed + interval
        local win = findUnclaimedWindow(appName, claimedIds)
        if win then
            timer:stop()
            callback(win)
        elseif elapsed >= timeout then
            timer:stop()
            callback(nil)
        end
    end)
    timer:start()
end

-- Collect the set of app names referenced in a layout definition.
local function layoutAppNames(layoutDef)
    local names = {}
    for _, winDef in ipairs(layoutDef.windows or {}) do
        if winDef.app then names[winDef.app] = true end
    end
    return names
end

-- Apply a layout definition.
-- layoutDef: { name, hide_others, windows=[{app, screen, x, y, w, h, reuse, focus}] }
function M.apply(layoutDef)
    local layoutAppSet = layoutAppNames(layoutDef)

    -- Hide non-layout apps if requested
    if layoutDef.hide_others then
        for _, app in ipairs(hs.application.runningApplications()) do
            local name = app:name()
            if name and not layoutAppSet[name] then
                app:hide()
            end
        end
    end

    local claimedIds = {}
    local focusWin = nil
    local windows = layoutDef.windows or {}

    local function processWindow(index)
        if index > #windows then
            if focusWin then focusWin:focus() end
            return
        end

        local winDef = windows[index]
        if not winDef.app then
            processWindow(index + 1)
            return
        end

        local win = (winDef.reuse ~= false) and findUnclaimedWindow(winDef.app, claimedIds)

        local function onWin(w)
            if w then
                claimedIds[w:id()] = true
                local screen = getScreen(winDef.screen or 0)
                local sf = screen:frame()
                w:setFrame({
                    x = sf.x + resolveValue(winDef.x or 0, sf.w),
                    y = sf.y + resolveValue(winDef.y or 0, sf.h),
                    w = resolveValue(winDef.w or 1, sf.w),
                    h = resolveValue(winDef.h or 1, sf.h),
                }, 0)
                if winDef.focus then focusWin = w end
            else
                print("Ryoiki: could not get window for app: " .. tostring(winDef.app))
            end
            processWindow(index + 1)
        end

        if win then
            onWin(win)
        else
            waitForWindowAsync(winDef.app, claimedIds, 5, onWin)
        end
    end

    -- Pre-launch all apps in parallel before sequential window processing
    local launched = {}
    for _, winDef in ipairs(windows) do
        if winDef.app and not launched[winDef.app] and not hs.application.get(winDef.app) then
            hs.application.launchOrFocus(winDef.app)
            launched[winDef.app] = true
        end
    end
    processWindow(1)
end

return M
