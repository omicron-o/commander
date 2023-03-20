-- Copyright 2023 <omicron.me@protonmail.com>
-- Distributed under the MIT License
local cmdr = select(2, ...)

-- Run all functions that start with Setup
function cmdr.RunSetupFunctions()
    for k, v in pairs(cmdr) do
        if string.sub(k, 1, 5) == "Setup" then
            v()
        end
    end
end

cmdr.RunSetupFunctions()
