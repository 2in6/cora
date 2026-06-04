--[[
    Cora • Loader
    Execute this. It pulls every module from your repo and boots the UI.
    Repo: github.com/2in6/cora
--]]

local USER   = "2in6"
local REPO   = "cora"
local BRANCH = "main"
local BASE   = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(USER, REPO, BRANCH)

local function fetch(path)
    local ok, src = pcall(function()
        return game:HttpGet(BASE .. path .. "?t=" .. tostring(tick()))
    end)
    if not ok or type(src) ~= "string" or #src == 0 then
        error("[Cora] Failed to fetch " .. path .. ": " .. tostring(src))
    end
    local chunk, err = loadstring(src)
    if not chunk then
        error("[Cora] Failed to compile " .. path .. ": " .. tostring(err))
    end
    return chunk
end

-- Shared context passed to every module
local Cora = {
    Version = "v1.0.1",
    Base    = BASE,
    fetch   = fetch,
    MoonURL = "https://i.ibb.co/DDF8bL5Q/bedtime-1000dp-E3-E3-E3-FILL0-wght400-GRAD0-opsz48.png",
}

-- 1) Key system — blocks until the key is verified
local keyOk = fetch("src/keysystem.lua")()(Cora)
if not keyOk then
    warn("[Cora] Key not verified. Aborting.")
    return
end

-- 2) Main — loads Obsidian, builds the window + tabs
fetch("src/main.lua")()(Cora)
