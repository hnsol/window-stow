-- layout.lua
-- Layout engine for Ryoiki.spoon

local M = {}

-- Active async timers; populated by waitForWindowAsync, cleared by cancelPending
M._activeTimers = {}

-- Stop all pending async window-wait timers
function M.cancelPending()
    for timer in pairs(M._activeTimers) do
        pcall(function() timer:stop() end)
    end
    M._activeTimers = {}
end

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

-- Apply a window def's position/size to an existing window object
local function applyWindowFrame(win, def, sf)
    win:setFrame({
        x = sf.x + resolveValue(def.x or 0, sf.w),
        y = sf.y + resolveValue(def.y or 0, sf.h),
        w = resolveValue(def.w or 1, sf.w),
        h = resolveValue(def.h or 1, sf.h),
    }, 0)
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
    local interval = 0.1
    local elapsed = 0
    local timer
    timer = hs.timer.new(interval, function()
        elapsed = elapsed + interval
        local win = findUnclaimedWindow(appName, claimedIds)
        if win then
            timer:stop()
            M._activeTimers[timer] = nil
            callback(win)
        elseif elapsed >= timeout then
            timer:stop()
            M._activeTimers[timer] = nil
            callback(nil)
        end
    end)
    M._activeTimers[timer] = true
    timer:start()
end

-- Apply a layout definition.
-- layoutDef: { name, windows=[{app, screen, x, y, w, h, focus}] }
function M.apply(layoutDef)
    local claimedIds = {}
    local focusWin   = nil
    local windows    = layoutDef.windows or {}

    -- Count window slots that have an app (for pending completion tracking)
    local pending = 0
    for _, winDef in ipairs(windows) do
        if winDef.app then pending = pending + 1 end
    end

    -- Apply focus once all slots are done (Promise.all equivalent)
    local function onDone()
        pending = pending - 1
        if pending == 0 then
            if focusWin then focusWin:focus() end
        end
    end

    -- Pass 1: launch/unhide each app (deduplicated by app name)
    local launched = {}
    for _, winDef in ipairs(windows) do
        if winDef.app and not launched[winDef.app] then
            local app = hs.application.get(winDef.app)
            if not app then
                hs.application.launchOrFocus(winDef.app)
            elseif app:isHidden() then
                app:unhide()
            end
            launched[winDef.app] = true
        end
    end

    if pending == 0 then return end

    -- Process all window slots in parallel (Lua is single-threaded; no lock needed)
    for _, winDef in ipairs(windows) do
        if winDef.app then
            local def = winDef  -- capture loop variable for closures

            local win = findUnclaimedWindow(def.app, claimedIds)

            if win then
                -- Fast path: window already exists
                claimedIds[win:id()] = true
                local screen = getScreen(def.screen or 0)
                local sf = screen:frame()
                applyWindowFrame(win, def, sf)
                if def.focus then focusWin = win end
                onDone()
            else
                -- Slow path: wait for window asynchronously (independent timer per slot)
                waitForWindowAsync(def.app, claimedIds, 5, function(w)
                    if w then
                        claimedIds[w:id()] = true
                        local screen = getScreen(def.screen or 0)
                        local sf = screen:frame()
                        applyWindowFrame(w, def, sf)
                        if def.focus then focusWin = w end
                    else
                        hs.notify.show("Ryoiki", "", "Could not get window for: " .. tostring(def.app))
                    end
                    onDone()
                end)
            end
        end
    end
end

return M
