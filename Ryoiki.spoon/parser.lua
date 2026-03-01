-- parser.lua
-- KDL subset parser for Ryoiki.spoon

local M = {}

-- Strip // line comments
local function stripComments(text)
    return text:gsub("//[^\n]*", "")
end

-- Tokenizer
-- Token types: IDENT, STRING, NUMBER, PERCENT, BOOL, LBRACE, RBRACE, NEWLINE
local function tokenize(text)
    local tokens = {}
    local i = 1
    local len = #text

    while i <= len do
        local c = text:sub(i, i)

        -- Skip whitespace (not newline)
        if c == " " or c == "\t" or c == "\r" then
            i = i + 1

        -- Newline
        elseif c == "\n" then
            tokens[#tokens + 1] = { type = "NEWLINE" }
            i = i + 1

        -- Left brace
        elseif c == "{" then
            tokens[#tokens + 1] = { type = "LBRACE" }
            i = i + 1

        -- Right brace
        elseif c == "}" then
            tokens[#tokens + 1] = { type = "RBRACE" }
            i = i + 1

        -- Quoted string
        elseif c == '"' then
            local j = i + 1
            while j <= len and text:sub(j, j) ~= '"' do
                if text:sub(j, j) == "\\" then j = j + 1 end
                j = j + 1
            end
            local raw = text:sub(i + 1, j - 1)
            -- Check if it's a percentage string like "70%"
            local numPart = raw:match("^(%d+%.?%d*)%%$")
            if numPart then
                tokens[#tokens + 1] = { type = "PERCENT", value = tonumber(numPart) / 100 }
            else
                tokens[#tokens + 1] = { type = "STRING", value = raw }
            end
            i = j + 1

        -- Number or bare percent (e.g. 70%)
        elseif c:match("%d") or (c == "-" and text:sub(i+1,i+1):match("%d")) then
            local j = i
            if c == "-" then j = j + 1 end
            while j <= len and text:sub(j, j):match("[%d%.]") do
                j = j + 1
            end
            local numStr = text:sub(i, j - 1)
            if text:sub(j, j) == "%" then
                tokens[#tokens + 1] = { type = "PERCENT", value = tonumber(numStr) / 100 }
                i = j + 1
            else
                tokens[#tokens + 1] = { type = "NUMBER", value = tonumber(numStr) }
                i = j
            end

        -- Identifier / bool / bare word
        elseif c:match("[%a_]") then
            local j = i
            while j <= len and text:sub(j, j):match("[%w_%-%.]") do
                j = j + 1
            end
            local word = text:sub(i, j - 1)
            if word == "true" then
                tokens[#tokens + 1] = { type = "BOOL", value = true }
            elseif word == "false" then
                tokens[#tokens + 1] = { type = "BOOL", value = false }
            else
                tokens[#tokens + 1] = { type = "IDENT", value = word }
            end
            i = j

        else
            -- Skip unknown characters
            i = i + 1
        end
    end

    return tokens
end

-- Parse a flat KDL file (no layout{} wrapper).
-- Returns a single layout table with name set to the provided name argument.
local function parseFlat(text, name)
    local clean = stripComments(text)
    local tokens = tokenize(clean)
    local pos = 1

    local function peek()
        return tokens[pos]
    end

    local function advance()
        local t = tokens[pos]
        pos = pos + 1
        return t
    end

    local function skipNewlines()
        while peek() and peek().type == "NEWLINE" do
            advance()
        end
    end

    local function parseValue()
        local t = peek()
        if not t then return nil end
        if t.type == "STRING" or t.type == "NUMBER" or t.type == "PERCENT" or t.type == "BOOL" then
            advance()
            return t.value
        elseif t.type == "IDENT" then
            advance()
            return t.value
        end
        return nil
    end

    local function parseWindowBlock()
        local win = {
            app = nil,
            screen = 0,
            x = 0,
            y = 0,
            w = 1,
            h = 1,
            reuse = true,
            focus = false,
        }

        skipNewlines()
        if not (peek() and peek().type == "LBRACE") then return win end
        advance() -- consume {

        while peek() do
            skipNewlines()
            local t = peek()
            if not t then break end
            if t.type == "RBRACE" then
                advance()
                break
            end
            if t.type == "IDENT" then
                local key = advance().value
                local val = parseValue()
                if key == "app" then win.app = val
                elseif key == "screen" then win.screen = val
                elseif key == "x" then win.x = val
                elseif key == "y" then win.y = val
                elseif key == "w" then win.w = val
                elseif key == "h" then win.h = val
                elseif key == "reuse" then win.reuse = val
                elseif key == "focus" then win.focus = val
                end
            else
                advance()
            end
        end

        return win
    end

    local layout = {
        name = name,
        keybind = nil,
        description = nil,
        hide_others = false,
        windows = {},
    }

    while peek() do
        skipNewlines()
        local t = peek()
        if not t then break end

        if t.type == "IDENT" then
            local key = advance().value
            if key == "window" then
                local win = parseWindowBlock()
                layout.windows[#layout.windows + 1] = win
            else
                local val = parseValue()
                if key == "keybind" then layout.keybind = val
                elseif key == "description" then layout.description = val
                elseif key == "hide_others" then layout.hide_others = val
                end
            end
        else
            advance()
        end
    end

    return layout
end

-- Public API

-- Load a single layout from a flat KDL file.
-- name: the layout name (typically the filename stem)
function M.loadFile(path, name)
    local f, err = io.open(path, "r")
    if not f then
        error("Ryoiki parser: cannot open file: " .. tostring(path) .. " (" .. tostring(err) .. ")")
    end
    local text = f:read("*a")
    f:close()
    return parseFlat(text, name)
end

-- Load all *.kdl files in a directory. Returns an array of layout tables.
function M.loadDir(dir)
    local layouts = {}
    local files = {}
    for entry in hs.fs.dir(dir) do
        if entry:match("%.kdl$") then
            files[#files + 1] = entry
        end
    end
    table.sort(files)
    for _, filename in ipairs(files) do
        local stem = filename:match("^(.+)%.kdl$")
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
