
-- Auto GitHub Commit & Push
-- Requirements: Git installed and repository already configured

local function run(command)
    print("> " .. command)
    local success = os.execute(command)

    if success ~= true and success ~= 0 then
        error("Command failed: " .. command)
    end
end

-- Check if this directory is a Git repository
local check = os.execute("git rev-parse --is-inside-work-tree > /dev/null 2>&1")

if check ~= true and check ~= 0 then
    error("Not a Git repository! Run this script inside your project.")
end

-- Check for changes
local handle = io.popen("git status --porcelain")
local changes = handle:read("*a")
handle:close()

if changes == "" then
    print("No changes to commit.")
    return
end

-- Generate commit message
local date = os.date("%Y-%m-%d %H:%M:%S")
local message = "Auto commit: " .. date

-- Stage all changes
run("git add -A")

-- Commit changes
run('git commit -m "' .. message .. '"')

-- Push to the current branch's upstream
run("git push")

print("Successfully committed and pushed to GitHub!")
