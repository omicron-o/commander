-- Copyright 2023 <omicron.me@protonmail.com>
-- Distributed under the MIT License
local AddonName, cmdr = ...
cmdr.events = {} -- event (str) to list of handlers
cmdr.db = nil

-- Gets existing or creates empty module
function cmdr.GetModule(name)
    if cmdr[name] == nil then
        cmdr[name] = {}
        -- module:Import(...) function to import individual symbols
        cmdr[name].Import = function(self, ...)
            local symols = {}
            local n = select('#', ...)
            for i=1,n do
                local name = select(i, ...)
                table.insert(symbols, self[name])
            end
            return unpack(symbols)
        end
    end
    return cmdr[name]
end
Commander = cmdr.GetModule("public")

-- Adds a given function to the event handler list for a given event
-- This will later in the addon 
function cmdr.SetEventHandler(event, fn)
    if cmdr.events[event] == nil then
        cmdr.events[event] = {}
    end
    table.insert(cmdr.events[event], fn)
end

-- The main handler receives basically every single event we want to listen to
-- and dispatches them to more appropriate handlers
function cmdr.MainEventHandler(frame, event, ...)
    local handlers = cmdr.events[event]
    if handlers ~= nil and next(handlers) ~= nil then
        for i, handler in ipairs(handlers) do
            handler(...)
        end
    end
end

-- Create the event frame and register all desired events
function cmdr.SetupEvents()
    local frame = CreateFrame("Frame")
    for name, _ in pairs(cmdr.events) do
        if string.sub(name, 1, string.len("COMMANDER")) ~= "COMMANDER" then
            frame:RegisterEvent(name)
        end
    end
    frame:SetScript("OnEvent", cmdr.MainEventHandler)
end

function cmdr.OnAddonLoaded(name)
    if name ~= AddonName then
        return
    end
    if CommanderDB == nil then
        CommanderDB = cmdr.data.CreateDB()
    end
    cmdr.db = CommanderDB
    cmdr.data.UpdateDB()
    cmdr.MainEventHandler(nil, "COMMANDER_LOADING")
    print("Loaded", AddonName)
end
cmdr.SetEventHandler("ADDON_LOADED", cmdr.OnAddonLoaded)

-- Fire custom event COMMANDER_FULLY_LOADED. This event is fired when the player
-- enters the world for the first time after logging in or reloading UI.
function cmdr.FireFullyLoadedEvent(initialLogin, reloadUI)
    if initialLogin or reloadUI then
        cmdr.MainEventHandler(nil, "COMMANDER_FULLY_LOADED")
    end
end
cmdr.SetEventHandler("PLAYER_ENTERING_WORLD", cmdr.FireFullyLoadedEvent)

function cmdr.SlashCommand(args)
    cmdr.cli.ToggleShow()
end

function cmdr.SetupSlashCommands()
    _G["SLASH_COMMANDER1"] = "/commander"
    _G["SLASH_COMMANDER2"] = "/cmdr"
    _G["SLASH_COMMANDER3"] = "/cmd"
    SlashCmdList["COMMANDER"] = cmdr.SlashCommand
end
