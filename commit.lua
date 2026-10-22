local repo_path = "."       
local interval = 60         
local counter = 0


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

   
    local f = io.open(new_path, "w")
    if not f then
        print("Could not create file: " .. new_path)
        return
    end

    f:write("Generated automatically at " .. timestamp .. "\n")
    f:close()
    print("Created: " .. new_name)

   
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

    
    if #files > 1 then
        local oldest = files[1]
        if oldest ~= new_path then
            if os.remove(oldest) then
                print("Deleted: " .. oldest)
            end
        end
    end

    
    if not run('git -C "' .. repo_path .. '" add -A') then
        print("ERROR: git add failed")
        return
    end

    
    local message = "Automated file update: " .. timestamp
    local cmd = 'git -C "' .. repo_path ..
        '" commit -m "' .. message .. '"'

    if not run(cmd) then
        print("ERROR: commit failed")
        return
    end

    
    if run('git -C "' .. repo_path .. '" push') then
        print("Successfully pushed at " .. timestamp)
    else
        print("ERROR: push failed; check authentication and branch")
    end
end


if not run('git -C "' .. repo_path .. '" rev-parse --is-inside-work-tree') then
    error("Please set repo_path to a valid Git repository.")
end

print("Automatic GitHub updates started. Press Ctrl+C to stop.")

while true do
    update_repository()
    os.execute("sleep " .. interval)
end
