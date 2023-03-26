-- Copyright 2023 <omicron.me@protonmail.com>
-- Distributed under the MIT License
local cmdr = select(2, ...)
local data = cmdr.GetModule("data")

-- Create a new DB
function data.CreateDB()
    return {version = 1, options={}}
end

-- Apply data updates
function data.UpdateDB()
    if cmdr.db.options == nil then
        cmdr.db.options = {}
    end
end

function data.SetOption(name, value)
    cmdr.db.options[name] = value
end

function data.GetOption(name, default)
    return cmdr.db.options[name] or default
end
