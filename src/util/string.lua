local cmdr = select(2, ...)
if cmdr.util == nil then
    cmdr.util = {}
end
cmdr.util.string = {}
local str = cmdr.util.string

-- Given an integer value and a separator character (must be compatible with
-- third argument of string.gsub), format the integer with thousands separator
-- 
-- Courtesy of the lua-users wiki: http://lua-users.org/wiki/FormattingNumbers
function str.FormatInt(value, separator)
    if separator == nil then
        separator = " "
    end
    local formatted = tostring(value)
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1' .. separator .. '%2')
        if (k==0) then
            break
        end
    end
    return formatted
end

-- returns true if s has the given prefix, false otherwise
function str.HasPrefix(s, prefix)
    local n = prefix:len()
    return s:sub(1, n) == prefix
end

-- returns true if s has the given suffix, false otherwise
function str.HasSuffix(s, suffix)
    local n = suffix:len()
    return s:sub(-n, -1) == suffix
end

-- return the given string with the leading and trailing spaces stripped off
function str.Strip(s)
    return s:gsub("^%s+", ""):gsub("%s+$", "")
end

-- Parse a string into a list
-- all chunks will match the given pattern
-- if pattern is nil the pattern defaults "%S+", which will split along spaces
function str.Split(s, pattern)
    if pattern == nil then
        pattern = "%S+"
    end
    local t = {}
    for chunk in s:gmatch(pattern) do
        table.insert(t, chunk)
    end
    return t
end

-- Join a list with a given delimiter
function str.Join(delim, list)
    if #list == 0 then
        return ""
    end

    local output = tostring(list[1])
    for i = 2,#list do
        output = output .. delim .. tostring(list[i])
    end
    return output
end

-- Format money
-- copper: the integer number of copper to format.
-- width: the minimum number of characters to output. This may be omitted)
-- short: only format gold values and ignore silver/copper if set to true
-- color: make values red on green if the sign is positive or negative
function str.FormatMoney(copper, width, short, color)
    local sign = copper < 0 and -1 or 1
    local inCopper = copper
    copper = math.abs(copper)

    if color and sign == -1 then
        color = "|cFFAA0000" -- red
    elseif color and sign == 1 then
        color = "|cFF00AA00" -- green
    end

    local goldSep   = "|cFFFFD700G|r"
    local silverSep = "|cFFC9C0BBS|r"
    local copperSep = "|cFFDA8A67C|r"
    
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper - gold*10000)/100)
    local copper = copper - gold*10000 - silver*100
    
    gold = str.FormatInt(sign*gold)
    -- the length for everything behind the gold number
    -- full format:  3 letters + 2 spaces + 2 digits
    -- short format: 1 letter
    local extraLen = short and 1 or 9 -- shitty ternary operator
    local len = string.len(gold) + extraLen
    local pad = ""
    if len < width then
        pad = string.rep(" ", width - len)
    end

    local fmt = short and "%s%s%s" or "%s%s%s %02d%s %02d%s" -- shitty ternary operator
    local out = string.format(fmt, pad, gold, goldSep, silver, silverSep, copper, copperSep)

    if color and inCopper ~= 0 then
        return color .. out .. "|r"
    else
        return out
    end
end
