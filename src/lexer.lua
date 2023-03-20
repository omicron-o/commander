-- Copyright 2023 <omicron.me@protonmail.com>
-- Distributed under the MIT License
local cmdr = select(2, ...)
cmdr.cli.lexer = {}
local lexer = cmdr.cli.lexer

local function lexToken(kind, pattern, input, init)
    local start, stop = string.find(input, pattern, init)
    if start == nil then
        return nil
    end
    return {
        kind = kind,
        value = string.sub(input, start, stop),
        start = start,
        stop = stop
    }
end

local function lexError(reason, input, init)
    local token = lexToken("ERROR", "^.+", input, init)
    token.reason = reason
    return token
end

-- Lex the input into a sequence of tokens. This does not yet strip whitespace
-- and comments.
-- 
-- token = {
--      kind = "WORD", "QUOTED", "SPACE", "COMMENT", "EOF" or "ERROR"
--      value = value of the token
--      start = start position of token
--      stop = end position of token
-- }
function lexer.Lex(input)
    local tokens = {}
    local pos = 1
    
    while string.len(string.sub(input, pos)) > 0 do
        local firstChar = string.sub(input, pos, pos)
        local token
        if firstChar == "#" then
            token = lexToken("COMMENT", "^#.+", input, pos)
        elseif firstChar == ";" then
            token = lexToken("SEMICOLON", "^;", input, pos)
        elseif firstChar == "|" then 
            token = lexToken("PIPE", "^|", input, pos)
        elseif firstChar == "'" then
            token = (
                lexToken("QUOTED", "^%b''", input, pos) or
                lexError("Unmatched ' symbol", input, pos)
            )
        elseif firstChar == '"' then
            token = (
                lexToken("QUOTED", '^%b""', input, pos) or
                lexError('Unmatched " symbol', input, pos)
            )
        elseif firstChar == " " then
            token = lexToken("SPACE", "^%s+", input, pos)
        else
            token = lexToken("WORD", "^[^ '\"#]+", input, pos)
        end
        pos = token.stop + 1
        table.insert(tokens, token)
    end
    table.insert(tokens, lexToken("EOF", "^", input, pos))
    return tokens
end

-- Create merged words, merged may be nil in which case a new token table will
-- be returned. If merged is not nil then it will be amended. token must be a
-- token of type WORD or QUOTED. The merged token must be of type TEXT
local function lexMerge(merged, token)
    if merged == nil then
        return {
            kind = "TEXT",
            value = token.value,
            start = token.start,
            stop = token.stop
        }
    end
    
    if token.kind == "WORD" then
        merged.value = merged.value .. token.value
    else
        merged.value = merged.value .. token.value:sub(2, -2)
    end
    merged.stop = token.stop
    return merged
end

-- Take the output of lexer.Lex and reduce it by removing whitespace and merging
-- words and quoted tokens
function lexer.Reduce(tokens)
    local reduced = {}
    local current = nil

    for _, token in ipairs(tokens) do
        -- Push completed merged token into the reduced list
        if token.kind ~= "WORD" and token.kind ~= "QUOTED" and current ~= nil then
            reduced = table.insert(reduced, token)
            current = nil
        end
        
        if token.kind == "WORD" or token.kind == "QUOTED" then
            current = lexMerge(current, token)
        elseif token.kind == "EOF" then
            table.insert(reduced, token)
        elseif token.kind == "SPACE" or token.kind == "COMMENT" then
            -- ignore
        else
            error("Unknown token kind in lexReduce: " .. tostring(token.kind))
        end
    end

    return reduced
end

