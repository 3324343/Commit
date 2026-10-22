
-- Automatically create, delete, commit, and push every 60 seconds
-- Designed for Linux and macOS

local repo_path = "."       -- Path to your Git repository
local interval = 60          -- Run every 60 seconds
local counter = 0

-- Only delete files created by this script
local prefix = "auto_generated_"

local function run(cmd)
    local a, b, c = os.execute(cmd)
    return a == true or (a == 0) or c == 0
end

local function update_repository()
    counter = counter + 1

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local new_name = string.format(
        "%s%03d.txt", prefix, counter
    )

    local new_path = repo_path .. "/" .. new_name

    -- 1. Create a new file
    local f = io.open(new_path, "w")
    if not f then
        print("Could not create file: " .. new_path)
        return
    end

    f:write("Generated automatically at " .. timestamp .. "\n")
    f:close()
    print("Created: " .. new_name)

    -- 2. Find and delete the oldest previously generated file
    local pipe = io.popen(
        'find "' .. repo_path ..
        '" -maxdepth 1 -type f -name "' ..
        prefix .. '*.txt" -print | sort'
    )

    local files = {}
    if pipe then
        for path in pipe:lines() do
            files[#files + 1] = path
        end
        pipe:close()
    end

    -- Keep the newly created file and remove one older file
    if #files > 1 then
        local oldest = files[1]
        if oldest ~= new_path then
            if os.remove(oldest) then
                print("Deleted: " .. oldest)
            end
        end
    end

    -- 3. Stage changes
    if not run('git -C "' .. repo_path .. '" add -A') then
        print("ERROR: git add failed")
        return
    end

    -- 4. Commit changes
    local message = "Automated file update: " .. timestamp
    local cmd = 'git -C "' .. repo_path ..
        '" commit -m "' .. message .. '"'

    if not run(cmd) then
        print("ERROR: commit failed")
        return
    end

    -- 5. Push to GitHub
    if run('git -C "' .. repo_path .. '" push') then
        print("Successfully pushed at " .. timestamp)
    else
        print("ERROR: push failed; check authentication and branch")
    end
end

-- Verify that the folder is a Git repository
if not run('git -C "' .. repo_path .. '" rev-parse --is-inside-work-tree') then
    error("Please set repo_path to a valid Git repository.")
end

print("Automatic GitHub updates started. Press Ctrl+C to stop.")

while true do
    update_repository()
    os.execute("sleep " .. interval)
end
