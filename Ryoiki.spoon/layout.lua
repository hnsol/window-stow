-- layout.lua
-- Layout engine for WindowLayout.spoon

local M = {}

-- Resolve a value to absolute pixels given a dimension (width or height).
-- Accepts:
--   number 0.0..1.0  → treated as fraction of dimension
--   number > 1       → treated as absolute pixels
--   string "70%"     → fraction (but parser already converts these to 0-1 floats)
local function resolveValue(value, dimension)
    if type(value) == "string" then
        local pct = value:match("^(%d+%.?%d*)%%$")
        if pct then
            return math.floor(tonumber(pct) / 100 * dimension + 0.5)
        end
        return tonumber(value) or 0
    elseif type(value) == "number" then
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

-- Poll until a standard window for appName appears, or timeout (seconds) is reached.
-- Returns the window or nil.
local function waitForWindow(appName, claimedIds, timeout)
    timeout = timeout or 3
    local interval = 0.05
    local elapsed = 0

    while elapsed < timeout do
        local win = findUnclaimedWindow(appName, claimedIds)
        if win then return win end
        hs.timer.usleep(math.floor(interval * 1e6))
        elapsed = elapsed + interval
    end
    return nil
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

    -- Track claimed window IDs to handle multiple windows from the same app
    local claimedIds = {}
    local focusWin = nil

    for _, winDef in ipairs(layoutDef.windows or {}) do
        if not winDef.app then goto continue end

        local win = nil

        if winDef.reuse ~= false then
            -- Try to find an existing unclaimed window
            win = findUnclaimedWindow(winDef.app, claimedIds)
        end

        if not win then
            -- Launch or focus the app, then wait for a new window
            hs.application.launchOrFocus(winDef.app)
            win = waitForWindow(winDef.app, claimedIds)
        end

        if not win then
            print("WindowLayout: could not get window for app: " .. tostring(winDef.app))
            goto continue
        end

        claimedIds[win:id()] = true

        -- Calculate frame
        local screen = getScreen(winDef.screen or 0)
        local sf = screen:frame() -- uses available area (excludes menu bar / Dock)

        local ax = sf.x + resolveValue(winDef.x or 0, sf.w)
        local ay = sf.y + resolveValue(winDef.y or 0, sf.h)
        local aw = resolveValue(winDef.w or 1, sf.w)
        local ah = resolveValue(winDef.h or 1, sf.h)

        -- Move window (0 = no animation)
        win:setFrame({ x = ax, y = ay, w = aw, h = ah }, 0)

        if winDef.focus then
            focusWin = win
        end

        ::continue::
    end

    -- Focus the designated window last
    if focusWin then
        focusWin:focus()
    end
end

return M
