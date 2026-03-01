-- chooser.lua
-- hs.chooser wrapper for Ryoiki.spoon

local M = {}

-- Create a new chooser instance.
-- getLayouts: function() → array of layout tables (with .name, .description, .menu_key)
-- applyFn: function(layoutName)
function M.new(getLayouts, applyFn)
    local self = {}
    local chooser = nil

    local function buildSubText(lay)
        local parts = {}
        if lay.menu_key then parts[#parts + 1] = "[" .. tostring(lay.menu_key) .. "]" end
        if lay.description and lay.description ~= "" then parts[#parts + 1] = lay.description end
        return table.concat(parts, " ")
    end

    local function buildChoices()
        local choices = {}
        for _, lay in ipairs(getLayouts()) do
            choices[#choices + 1] = {
                text = lay.name,
                subText = buildSubText(lay),
            }
        end
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
        chooser:queryChangedCallback(function(q)
            for _, lay in ipairs(getLayouts()) do
                if lay.menu_key and q == tostring(lay.menu_key) then
                    chooser:hide()
                    applyFn(lay.name)
                    return
                end
            end
        end)
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
