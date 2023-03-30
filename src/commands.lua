-- Copyright 2023 <omicron.me@protonmail.com>
-- Distributed under the MIT License
local cmdr = select(2, ...)
local cli = cmdr.cli
local data = cmdr.data

cli.RegisterCommand("reload", {
    description="reloads the ui",
    command=(function(...)
        ReloadUI()
    end)
})

cli.RegisterCommand("clear", {
    description="clears the output window",
    command=(function(...)
        cli.outText:SetText("")
    end)
})

cli.RegisterCommand("exit", {
    description="exit the cli",
    command=(function(...)
        cli.Hide()
    end)
})

cli.RegisterCommand("font", {
    description="change the cli font",
    completion=(function(word, args)
        if #args == 0 then
            local t = {}
            for k, _ in pairs(cli.fontFiles) do
                table.insert(t, k)
            end
            return t
        elseif #args == 1 and cli.fontFiles[args[1]] then
            local t = {}
            for k, _ in pairs(cli.fontFiles[args[1]]) do
                table.insert(t, k)
            end
            return t
        else
            return ""
        end
    end),
    command=(function(font, variant, size)
        if font == nil then
            cli.PrintLn("The following fonts and variants are available:")
            for font, variants in pairs(cli.fontFiles) do
                for variant, _ in pairs(variants) do
                    cli.Printf(" - %s %s\n", font, variant)
                end
            end
            cli.PrintLn("to set a font run: font <font> <variant> [size]")
            return
        end

        if variant == nil then
            cli.PrintLn("|cFFFF0000Error:|r font variant missing")
            cli.PrintLn("to set a font run: font <font> <variant> [size]")
            return
        end

        local fontVars = cli.fontFiles[font]
        if fontVars == nil then
            cli.PrintLn("|cFFFF0000Error:|r Unknown font")
            cli.PrintLn("To see a list of fonts run: font")
            return
        end
        local fontFile = fontVars[variant]
        if fontFile == nil then
            cli.PrintLn("|cFFFF0000Error:|r Unknown variant")
            cli.PrintLn("To see a list of fonts run: font")
            return
        end

        if size ~= nil and tonumber(size) == nil then
            cli.PrintLn("|cFFFF0000Error:|r size must be a number")
            return
        end

        local size = tonumber(size) or data.GetOption("cli.font.size", 14)
        local rval = cli.SetFont(font, variant, size)
        data.SetOption("cli.font.name", font)
        data.SetOption("cli.font.variant", variant)
        data.SetOption("cli.font.size", size)
        if not rval then
            cli.PrintLn("|cFFFF0000Error:|r invalid font file. This is likely bug in the addon.")
        end
    end)
})

cli.RegisterCommand("commands", {
    description="lists all commands",
    command=(function(...)
        for name, command in pairs(cli.commands) do
            cli.Printf("%-15s %s\n", name, command.description)
        end
    end)
})

cli.RegisterCommand("history", {
    description="print the command history",
    command = (function()
        for i=#cli.history, 1, -1 do
            cli.Printf("%2i: %s\n", i, cli.history[i])
        end
    end)
})
