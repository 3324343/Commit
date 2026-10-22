
-- auto_commit.lua
-- Checks for changes every 60 seconds, commits, and pushes.
-- Requirements: Lua 5.3+ and Git installed and authenticated.

local INTERVAL = 60
local PREFIX = "Auto update"

-- Set to "main" or another branch if you want to enforce a branch.
-- Leave nil to use the current branch.
local TARGET_BRANCH = nil

local function run(command)
    local ok, why, code = os.execute(command)

    if ok == true or ok == 0 then
        return true
    end

    return false, tostring(why or "command failed")
        .. " (" .. tostring(code or ok) .. ")"
end

local function capture(command)
    local pipe, err = io.popen(command, "r")
    if not pipe then
        return nil, err or "Could not start command"
    end

    local output = pipe:read("*a")
    local ok = pipe:close()

    if not ok then
        return nil, "Command failed: " .. command
    end

    return output
end

local function shell_quote(s)
    -- Quote a string as a shell argument.
    if package.config:sub(1, 1) == "\\" then
        return '"' .. s:gsub('"', '\\"') .. '"'
    end

    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function git(args)
    return run("git " .. args)
end

local function check_repository()
    local output = capture("git rev-parse --is-inside-work-tree")
    return output and output:match("true") ~= nil
end

local function commit_and_push()
    if not check_repository() then
        print("[ERROR] Current directory is not a Git repository.")
        return
    end

    -- Prevent overlapping or accidental commits on another branch.
    local branch, err = capture("git branch --show-current")
    if not branch then
        print("[ERROR] Could not determine branch: " .. err)
        return
    end
    branch = branch:gsub("%s+$", "")

    if TARGET_BRANCH and branch ~= TARGET_BRANCH then
        print("[SKIP] Current branch is " .. branch
            .. "; expected " .. TARGET_BRANCH)
        return
    end

    -- Check for staged, unstaged, or untracked changes.
    local changes, status_err = capture("git status --porcelain")
    if not changes then
        print("[ERROR] " .. status_err)
        return
    end

    if changes == "" then
        print("[OK] No changes. Next check in 60 seconds.")
        return
    end

    -- Stage changes.
    local ok, err = git("add -A")
    if not ok then
        print("[ERROR] git add failed: " .. err)
        return
    end

    -- Recheck staged changes; do not create empty commits.
    local staged, staged_err =
        capture("git diff --cached --name-only")
    if not staged then
        print("[ERROR] " .. staged_err)
        return
    end

    if staged == "" then
        print("[OK] No staged changes to commit.")
        return
    end

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local message = PREFIX .. ": " .. timestamp

    ok, err = git("commit -m " .. shell_quote(message))
    if not ok then
        print("[ERROR] Commit failed: " .. err)
        return
    end

    print("[OK] Created commit: " .. message)

    -- Push only after a successful commit.
    ok, err = git("push")
    if not ok then
        print("[ERROR] Push failed: " .. err)
        print("[INFO] The commit remains local. Will retry on a future run.")
        return
    end

    print("[OK] Push completed.")
end

print("Auto GitHub Commit started.")
print("Checking every " .. INTERVAL .. " seconds.")
print("Press Ctrl+C to stop.")

while true do
    local ok, err = pcall(commit_and_push)

    if not ok then
        print("[ERROR] Unexpected error: " .. tostring(err))
    end

    os.execute("sleep " .. INTERVAL)
end
