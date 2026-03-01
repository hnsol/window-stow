-- hotkeys.lua
-- Hotkey utility for WindowLayout.spoon

local M = {}

-- Parse a combo string like "ctrl+alt+1" into {mods={"ctrl","alt"}, key="1"}
function M.parseCombo(combo)
    if not combo or combo == "" then return nil end

    local parts = {}
    for part in combo:gmatch("[^+]+") do
        parts[#parts + 1] = part:lower():match("^%s*(.-)%s*$") -- trim
    end

    if #parts == 0 then return nil end

    local key = parts[#parts]
    local mods = {}
    for i = 1, #parts - 1 do
        mods[#mods + 1] = parts[i]
    end

    return { mods = mods, key = key }
end

-- Bind multiple {combo, fn} entries, return list of hs.hotkey objects
function M.bindAll(bindings)
    local hotkeys = {}
    for _, binding in ipairs(bindings) do
        local combo = M.parseCombo(binding.combo)
        if combo then
            local ok, hk = pcall(hs.hotkey.bind, combo.mods, combo.key, binding.fn)
            if ok and hk then
                hotkeys[#hotkeys + 1] = hk
            else
                print("WindowLayout hotkeys: failed to bind " .. tostring(binding.combo))
            end
        end
    end
    return hotkeys
end

-- Delete all hotkeys in list
function M.deleteAll(hotkeys)
    for _, hk in ipairs(hotkeys or {}) do
        pcall(function() hk:delete() end)
    end
end

return M
