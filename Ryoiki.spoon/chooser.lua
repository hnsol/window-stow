-- chooser.lua
-- hs.chooser wrapper for Ryoiki.spoon

local M = {}

-- Create a new chooser instance.
-- getLayouts: function() → array of layout tables (with .name, .keybind, .description)
-- applyFn: function(layoutName)
function M.new(getLayouts, applyFn)
    local self = {}
    local chooser = nil

    local function buildSubText(lay)
        local parts = {}
        if lay.keybind then parts[#parts + 1] = lay.keybind end
        if lay.description and lay.description ~= "" then parts[#parts + 1] = lay.description end
        return table.concat(parts, " | ")
    end

    local function buildChoices()
        local withKey = {}
        local noKey   = {}
        for _, lay in ipairs(getLayouts()) do
            local choice = {
                text    = lay.name,
                subText = buildSubText(lay),
            }
            if lay.keybind then
                withKey[#withKey + 1] = choice
            else
                noKey[#noKey + 1] = choice
            end
        end
        table.sort(withKey, function(a, b) return a.text < b.text end)
        table.sort(noKey,   function(a, b) return a.text < b.text end)
        local choices = {}
        for _, c in ipairs(withKey) do choices[#choices + 1] = c end
        for _, c in ipairs(noKey)   do choices[#choices + 1] = c end
        return choices
    end

    local function onCreate()
        chooser = hs.chooser.new(function(choice)
            if choice then
                applyFn(choice.text)
            end
        end)
        chooser:searchSubText(true)
        chooser:placeholderText("Select layout…")
    end

    function self.show()
        if not chooser then onCreate() end
        chooser:choices(buildChoices())
        chooser:show()
    end

    function self.destroy()
        if chooser then
            chooser:delete()
            chooser = nil
        end
    end

    return self
end

return M
