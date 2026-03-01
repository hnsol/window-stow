-- hotkeys.lua
-- Hotkey utility for Ryoiki.spoon

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
    if not key or key == "" then return nil end
    local mods = {}
    local seen = {}
    for i = 1, #parts - 1 do
        local mod = parts[i]
        if not seen[mod] then
            seen[mod] = true
            mods[#mods + 1] = mod
        end
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
                hs.notify.show("Ryoiki", "", "Failed to bind hotkey: " .. tostring(binding.combo))
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
