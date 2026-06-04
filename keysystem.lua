--[[
    Cora • Loader
    Execute this. It pulls every module from your repo and boots the UI.
    Repo: github.com/2in6/cora
--]]

local USER     = "2in6"
local REPO     = "cora"
local BRANCHES = { "main", "master" } -- tries each in order

local BASE
local function rawUrl(branch, path)
    return ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(USER, REPO, branch, path)
end

local function looksLike404(s)
    -- GitHub raw returns the literal text "404: Not Found" for missing files
    return type(s) ~= "string" or #s == 0 or s:match("^404") ~= nil or s == "Not Found"
end

do
    for _, branch in ipairs(BRANCHES) do
        local ok, body = pcall(function()
            return game:HttpGet(rawUrl(branch, "loader.lua") .. "?t=" .. tostring(tick()))
        end)
        if ok and not looksLike404(body) then
            BASE = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(USER, REPO, branch)
            break
        end
    end
    if not BASE then
        error("[Cora] Could not find the repo on branches: " .. table.concat(BRANCHES, ", ")
            .. ". Check that the files are pushed to github.com/" .. USER .. "/" .. REPO)
    end
end

local function fetch(path)
    local ok, src = pcall(function()
        return game:HttpGet(BASE .. path .. "?t=" .. tostring(tick()))
    end)
    if not ok then
        error("[Cora] Network error fetching " .. path .. ": " .. tostring(src))
    end
    if looksLike404(src) then
        error("[Cora] File not found in repo: " .. path
            .. " (got a 404). Make sure it exists at that exact path.")
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
