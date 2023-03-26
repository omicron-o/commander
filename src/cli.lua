-- Copyright 2023 <omicron.me@protonmail.com>
-- Distributed under the MIT License
local cmdr = select(2, ...)
local cli = cmdr.GetModule("cli")
local parser = cmdr.GetModule("parser")
local data = cmdr.data
local Strip = cmdr.util.string.Strip
local HasPrefix = cmdr.util.string.HasPrefix

-- Holds all commands that can be executed. Index is the command (string) and
-- the data is a table that contains the command. The table has the following:
--[[
{
    description="Short command description",
    command=function(...) end,      -- Function that takes command arguments
}

-- TODO: 
--  * Commands should have some way to assist in tab completing
--  * Some kind of piping of data from one command to another
--  * Some way for commands that have longer runtimes to lock cli until they are
--    done running
]]--

cli.commands = {}
local commands = cli.commands

cli.history = {}
cli.historyIndex = 0

cli.fontFiles = {
    ["inconsolata"] = {
        ["bold"]     = "Interface\\AddOns\\Commander\\media\\fonts\\inconsolata\\Inconsolata-Bold.ttf",
        ["semibold"] = "Interface\\AddOns\\Commander\\media\\fonts\\inconsolata\\Inconsolata-SemiBold.ttf",
        ["regular"]  = "Interface\\AddOns\\Commander\\media\\fonts\\inconsolata\\Inconsolata-Regular.ttf"
    },
    ["freefont"] = {
        ["mono-bold"] = "Interface\\AddOns\\Commander\\media\\fonts\\freefont\\FreeMonoBold.otf",
        ["mono"]      = "Interface\\AddOns\\Commander\\media\\fonts\\freefont\\FreeMono.otf",
    }
}

function cli.RegisterCommand(name, command)
    if commands[name] ~= nil then
        error("Command already registered")
    end
    commands[name] = command
end
cmdr.public.RegisterCommand = cli.RegisterCommand

function cli.SetFont(font, variant, size)
    local file = cli.fontFiles[font][variant]

    local inRet = cli.inText:SetFont(file, size, "OUTLINE")
    local outRet = cli.outText:SetFont(file, size, "OUTLINE")
    return inRet and outRet
end

function cli.CreateUI()
    cli.frame = CreateFrame("Frame", "CommanderCLI", UIParent, "BackdropTemplate")
    cli.frame.backdropInfo = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    }

    -- Output wrap
    cli.frame:ApplyBackdrop()
    cli.frame:SetBackdropColor(0, 0, 0, 1)
    cli.frame:SetSize(640, 480)
    cli.frame:SetPoint("TOPRIGHT")
    cli.frame:SetFrameStrata("DIALOG")
    cli.frame:Hide()
    cli.frame:SetScript("OnShow", function(self)
        cli.OnShow()
    end)

    -- TODO: place this here to make it visible to the keybind handler in
    -- Bindings.xml but we probably need a cleaner way for this
    cli.frame.ShowOrFocus = function()
        cli.ShowOrFocus()
    end

    local scrollFrame = CreateFrame("ScrollFrame", nil, cli.frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(640-16-20, 480-16)
    scrollFrame:SetPoint("TOPLEFT", cli.frame, "TOPLEFT", 8, -8)
    cli.scroll = scrollFrame
    
    cli.outText = CreateFrame("EditBox", nil, scrollFrame)
    cli.outText:SetFontObject(ChatFontNormal)
    cli.outText:SetWidth(640-16-20)
    cli.outText:SetMultiLine(true)
    cli.outText:SetAutoFocus(false)
    scrollFrame:SetScrollChild(cli.outText)


    -- Input Wrap
    local inputWrap = CreateFrame("Frame", nil, cli.frame, "BackdropTemplate")
    inputWrap.backdropInfo = cli.frame.backdropInfo
    inputWrap:ApplyBackdrop()
    inputWrap:SetBackdropColor(0, 0, 0, 1)
    inputWrap:SetPoint("TOPLEFT", cli.frame, "BOTTOMLEFT", 0, 0)
    inputWrap:SetPoint("TOPRIGHT", cli.frame, "BOTTOMRIGHT", 0, 0)
    inputWrap:SetHeight(24)

    -- input Text
    cli.inText = CreateFrame("EditBox", nil, inputWrap)
    cli.inText:SetFontObject(ChatFontNormal)
    cli.inText:SetPoint("TOPLEFT", inputWrap, "TOPLEFT", 8, -8)
    cli.inText:SetPoint("BOTTOMRIGHT", inputWrap, "BOTTOMRIGHT", -8, 8)
    cli.inText:SetMultiLine(false)
    cli.inText:SetAutoFocus(false)
    
    local font = data.GetOption("cli.font.name", "inconsolata")
    local variant = data.GetOption("cli.font.variant", "bold")
    local size = data.GetOption("cli.font.size", 14)
    cli.SetFont(font, variant, size)

    cli.inText:SetScript("OnEscapePressed", function(self) 
        cli.Hide()
    end)
    
    cli.inText:SetScript("OnEnterPressed", function(self)
        cli.HandleCLIEnter()
    end)

    cli.inText:SetScript("OnArrowPressed", function(self, key)
        cli.OnArrowPressed(key)
    end)
end
cmdr.SetEventHandler("COMMANDER_LOADING", cli.CreateUI)

function cli.HandleCLIEnter()
    local escaped = cli.inText:GetText()
    local input = escaped:gsub("||", "|")
    cli.PrintLn("|cFF009900>|r", escaped)
    cli.AddHistoryLine(escaped)
    cli.inText:SetText("") 

    local script, err = parser.ParseInput(input)
    if err ~= nil then
        cli.PrintLn("|cFFFF0000Error:|r", err)
        return
    end

    cli.ExecuteScript(script)

    -- Even next frame seems to not scroll it properly, this is hacky but it
    -- works for now 
    C_Timer.After(0.075, function()
        cli.scroll:SetVerticalScroll(cli.scroll:GetVerticalScrollRange())
    end)
end

function cli.ExecuteScript(script)
    for _, pipeline in ipairs(script.pipelines) do
        local err = cli.ExecutePipeline(pipeline)
        if err then
            return err
        end
    end
end

function cli.ExecutePipeline(pipeline)
    for _, command in ipairs(pipeline.commands) do
        local err = cli.ExecuteCommand(command)
        if err then
            cli.PrintLn("|cFFFF0000Error:|r", err)
            return
        end
    end
end

function cli.ExecuteCommand(commandNode)
    local name = commandNode.command
    local args = commandNode.arguments
    local command = commands[name]

    if command == nil then
        return string.format("command '%s' not found", name)
    end
    command.command(unpack(args))
end

function cli.PrintLn(...)
    local n = select('#', ...)
    if n > 0 then
        cli.outText:Insert(tostring(select(1, ...)))
        for i = 2, n do
            cli.outText:Insert(" ")
            cli.outText:Insert(tostring(select(i, ...)))
        end
    end
    cli.outText:Insert("\n")
end
cmdr.public.PrintLn = cli.PrintLn

function cli.DebugLn(...)
    cli.PrintLn("|cFFFFAC4ADebug:|r", ...)
end
cmdr.public.DebugLn = cli.DebugLn

function cli.Printf(fmt, ...)
    local s = string.format(fmt, ...)
    cli.outText:Insert(s)
end
cmdr.public.Printf = cli.Printf

function cli.Debugf(fmt, ...)
    cli.Printf("|cFFFFAC4ADebug:|r " .. fmt, ...)
end
cmdr.public.Debugf = cli.Debugf

function cli.AddLine(line)
    cli.outText(line)
end

function cli.RemoveHistoryDuplicate(line)
    -- We assume only 1 duplicate can exist
    local found = nil
    for i, historyLine in ipairs(cli.history) do
        if line == historyLine then
            found = i
            break
        end
    end
    if found then
        table.remove(cli.history, found)
    end
end

function cli.AddHistoryLine(line)
    cli.RemoveHistoryDuplicate(line)
    table.insert(cli.history, 1, line)
    cli.historyIndex = 0
    while #cli.history > 30 do
        table.remove(cli.history)
    end
end

function cli.OnArrowPressed(key)
    local direction
    if key == "UP" then
        direction = 1
    elseif key == "DOWN" then
        direction = -1
    else
        return
    end

    local newIndex = cli.historyIndex + direction
    if newIndex > 0 and newIndex <= #cli.history then
        cli.historyIndex = newIndex
        cli.inText:SetText(cli.history[newIndex])
    elseif newIndex == 0 then
        -- TODO: maybe remember current line? but have to consider how that works
        -- if you up arrow a few times, edit some text, then arrow again
        cli.historyIndex = newIndex
        cli.inText:SetText("")
    end
end

function cli.OnShow()
    cli.inText:SetFocus()
end

function cli.Hide()
    cli.frame:Hide()
end

function cli.Show()
    cli.frame:Show()
end

function cli.ShowOrFocus()
    if cli.frame:IsShown() then
        cli.inText:SetFocus()
    else
        cli.frame:Show()
    end
end

cmdr.public.ShowOrFocus = cli.ShowOrFocus

function cli.ToggleShow()
    cli.frame:SetShown(not cli.frame:IsShown())
end
