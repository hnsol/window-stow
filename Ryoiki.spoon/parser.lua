-- parser.lua
-- Lua table loader for Ryoiki.spoon

local M = {}

-- Load a single layout from a Lua file.
-- name: the layout name (typically the filename stem)
-- Returns: layout table
function M.loadFile(path, name)
    local ok, result = pcall(dofile, path)
    if not ok then
        error("Ryoiki loader: cannot load file: " .. tostring(path) .. " (" .. tostring(result) .. ")")
    end
    if type(result) ~= "table" then
        error("Ryoiki loader: " .. tostring(path) .. " must return a table, got " .. type(result))
    end
    if type(result.windows) ~= "table" then
        error("Ryoiki loader: " .. tostring(path) .. " missing required field 'windows'")
    end
    result.name = name
    return result
end

-- Load all *.lua files in a directory. Returns an array of layout tables.
-- Shows an hs.notify if any file fails to load.
function M.loadDir(dir)
    local layouts = {}
    local files = {}
    for entry in hs.fs.dir(dir) do
        if entry:match("%.lua$") then
            files[#files + 1] = entry
        end
    end
    table.sort(files)
    for _, filename in ipairs(files) do
        local stem = filename:match("^(.+)%.lua$")
        local path = dir .. "/" .. filename
        local ok, result = pcall(M.loadFile, path, stem)
        if ok then
            layouts[#layouts + 1] = result
        else
            hs.notify.show("Ryoiki", "", "Failed to load " .. filename .. ": " .. tostring(result))
        end
    end
    return layouts
end

return M
