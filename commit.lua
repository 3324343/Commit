
-- Automatic File Creator, Deleter, and GitHub Committer
-- Runs every 60 seconds

local repo_path = "." -- Your Git repository folder
local interval = 60
local file_counter = 0

-- Change these to control which files get deleted.
local delete_prefix = "temp_auto_"

local function run(cmd)
    local result = os.execute(cmd)
    return result == true or result == 0
end

local function auto_update()
    file_counter = file_counter + 1

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local filename = string.format(
        "auto_file_%03d.txt", file_counter
    )

    local full_path = repo_path .. "/" .. filename

    -- 1. Create a new file
    local file = io.open(full_path, "w")

    if not file then
        print("Failed to create " .. filename)
        return
    end

    file:write("Automatically generated file\n")
    file:write("Created at: " .. timestamp .. "\n")
    file:close()

    print("Created: " .. filename)

    -- 2. Delete one previously generated temporary file
    local delete_cmd = 'find "' .. repo_path ..
        '" -maxdepth 1 -type f -name "' ..
        delete_prefix .. '*.txt" -print -quit'

    local pipe = io.popen(delete_cmd)
    local old_file = pipe and pipe:read("*l")
    if pipe then pipe:close() end

    if old_file and old_file ~= "" then
        os.remove(old_file)
        print("Deleted: " .. old_file)
    end

    -- 3. Stage all repository changes
    if not run('git -C "' .. repo_path .. '" add -A') then
        print("Git add failed")
        return
    end

    -- 4. Commit changes
    local message = "Automated update: " .. timestamp
    local commit_cmd = 'git -C "' .. repo_path ..
        '" commit -m "' .. message .. '"'

    if not run(commit_cmd) then
        print("Commit failed")
        return
    end

    -- 5. Push to GitHub
    if run('git -C "' .. repo_path .. '" push') then
        print("Successfully pushed to GitHub!")
    else
        print("Push failed; check Git authentication and branch.")
    end
end

print("Auto GitHub updater started.")

while true do
    auto_update()
    os.execute("sleep " .. interval)
end
