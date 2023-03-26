-- Copyright 2023 <omicron.me@protonmail.com>
-- Distributed under the MIT License
local cmdr = select(2, ...)
local lexer = cmdr.GetModule("lexer")
local parser = cmdr.GetModule("parser")

--[[

Grammar:
--------
    <script>    ::= <pipeline> | <script> <semicolon> <pipeline>
    <pipeline>  ::= <command> | <pipeline> <pipe> <command>
    <command>   ::= <text> | <command> <text>

Lexer tokens:
-------------
    <text>      ::= it's complicated
    <pipe>      ::= "|"   
    <semicolon> ::= ";"

--]]

function parser.ParseInput(input)
    local tokens = lexer.Reduce(lexer.Lex(input))
    return parser.ParseScript(tokens)
end

function parser.ParseScript(tokens)
    local script = {kind="SCRIPT", pipelines={}}
    local pipelines = script.pipelines
    local i = 1
    while true do
        -- Parse the next pipeline
        local pipeline, err
        pipeline, err, i = parser.ParsePipeline(tokens, i)
        if err then
            return nil, err
        end
        table.insert(pipelines, pipeline)
    
        -- If a semicolon appears, continue, otherwise we end
        if tokens[i].kind == "SEMICOLON" then
            i = i + 1
        else
            break
        end
    end

    -- Script done, expecting EOF
    if tokens[i].kind ~= "EOF" then
        return nil, "Expected EOF"
    end
    return script
end


function parser.ParsePipeline(tokens, i)
    local pipeline = {kind="PIPELINE", commands={}}

    local commands = pipeline.commands
    while true do
        -- Parse the next command
        local command, err
        command, err, i = parser.ParseCommand(tokens, i)
        if err then
            return nil, err, i
        end
        table.insert(commands, command)
        
        -- If a pipe appears, continue, otherwise we end
        if tokens[i].kind == "PIPE" then
            i = i + 1
        else
            break
        end
    end
    return pipeline, nil, i
end

function parser.UnexpectedTokenError(unexpected, expected)
    if expected then
        return string.format("Expected %s but got unexpected %s (%s) instead", expected, unexpected.value, unexpected.kind)
    else
        return string.format("Unexpected %s (%s)", unexpected.value, unexpected.kind)
    end
end

function parser.ParseCommand(tokens, i)
    local command = {kind="COMMAND", arguments={}}
    local arguments = command.arguments
    if tokens[i].kind ~= "TEXT" then
        return nil, parser.UnexpectedTokenError(tokens[i], "command"), i
    end
    command.command = tokens[i].value
    i = i + 1
    while tokens[i].kind == "TEXT" do
        table.insert(arguments, tokens[i].value)
        i = i + 1
    end
    return command, nil, i
end
