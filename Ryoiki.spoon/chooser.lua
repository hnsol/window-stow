-- chooser.lua
-- hs.chooser wrapper for WindowLayout.spoon

local M = {}

-- Create a new chooser instance.
-- getLayouts: function() → array of layout tables (with .name and .description)
-- applyFn: function(layoutName)
function M.new(getLayouts, applyFn)
    local self = {}
    local chooser = nil

    local function buildChoices()
        local choices = {}
        for _, layout in ipairs(getLayouts()) do
            choices[#choices + 1] = {
                text = layout.name,
                subText = layout.description or "",
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
