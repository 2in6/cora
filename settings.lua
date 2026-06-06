--[[
    Cora • Loader
    Execute this. Pulls every module from your repo and boots the UI.
    Repo: github.com/2in6/cora
    Layout-agnostic: finds each module whether it's at root, src/, or src/tabs/.
--]]

local USER     = "2in6"
local REPO     = "cora"
local BRANCHES = { "main", "master" }

local function raw(branch, path)
    return ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(USER, REPO, branch, path)
end

local function looksLike404(s)
    return type(s) ~= "string" or #s == 0 or s:match("^404") ~= nil or s == "Not Found"
end

local function get(url)
    local ok, body = pcall(function()
        return game:HttpGet(url .. "?t=" .. tostring(tick()))
    end)
    if ok and not looksLike404(body) then return body end
    return nil
end

-- Find the branch that actually has the repo
local BRANCH
for _, b in ipairs(BRANCHES) do
    if get(raw(b, "loader.lua")) then BRANCH = b break end
end
if not BRANCH then
    error("[Cora] Repo not found on branches " .. table.concat(BRANCHES, "/")
        .. ". Check files are pushed to github.com/" .. USER .. "/" .. REPO)
end

-- Build candidate paths for a module name so layout doesn't matter
local function candidates(path)
    local file = path:match("([^/]+)$")
    local list, seen = {}, {}
    for _, c in ipairs({ path, file, "src/" .. file, "src/tabs/" .. file }) do
        if not seen[c] then seen[c] = true; list[#list + 1] = c end
    end
    return list
end

local function fetch(path)
    local src, found
    for _, c in ipairs(candidates(path)) do
        src = get(raw(BRANCH, c))
        if src then found = c break end
    end
    if not src then
        error("[Cora] Could not find '" .. path .. "' anywhere in the repo "
            .. "(tried: " .. table.concat(candidates(path), ", ") .. ")")
    end
    local chunk, err = loadstring(src)
    if not chunk then
        error("[Cora] Failed to compile " .. found .. ": " .. tostring(err))
    end
    return chunk
end

local Cora = {
    Version = "v1.2.0",
    Base    = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(USER, REPO, BRANCH),
    fetch   = fetch,
    MoonURL = "https://i.ibb.co/DDF8bL5Q/bedtime-1000dp-E3-E3-E3-FILL0-wght400-GRAD0-opsz48.png",
}

-- 1) Key system — blocks until verified
local keyOk = fetch("keysystem.lua")()(Cora)
if not keyOk then
    warn("[Cora] Key not verified. Aborting.")
    return
end

-- 2) Main — loads Obsidian, builds the window + tabs
fetch("main.lua")()(Cora)
