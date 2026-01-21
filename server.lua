local QBCore = exports['qb-core']:GetCoreObject()
local heistStates = {}

local CURRENT_VERSION = "1.0.0"
local RESOURCE_NAME = "core_scoreboard"
local VERSION_CHECK_URL = "https://raw.githubusercontent.com/ChrisNewmanDev/core_scoreboard/main/version.json"

local function ParseVersion(version)
    local major, minor, patch = version:match('(%d+)%.(%d+)%.(%d+)')
    return {
        major = tonumber(major) or 0,
        minor = tonumber(minor) or 0,
        patch = tonumber(patch) or 0
    }
end

local function CompareVersions(current, latest)
    local currentVer = ParseVersion(current)
    local latestVer = ParseVersion(latest)
    
    if latestVer.major > currentVer.major then return 'outdated'
    elseif latestVer.major < currentVer.major then return 'ahead' end
    
    if latestVer.minor > currentVer.minor then return 'outdated'
    elseif latestVer.minor < currentVer.minor then return 'ahead' end
    
    if latestVer.patch > currentVer.patch then return 'outdated'
    elseif latestVer.patch < currentVer.patch then return 'ahead' end
    
    return 'current'
end

local function CheckVersion()
    PerformHttpRequest(VERSION_CHECK_URL, function(statusCode, response, headers)
        if statusCode ~= 200 then
            print('^3[' .. RESOURCE_NAME .. '] ^1Failed to check for updates (HTTP ' .. statusCode .. ')^7')
            print('^3[' .. RESOURCE_NAME .. '] ^3Please verify the version.json URL is correct^7')
            return
        end
        
        local success, versionData = pcall(function() return json.decode(response) end)
        
        if not success or not versionData or not versionData.version then
            print('^3[' .. RESOURCE_NAME .. '] ^1Failed to parse version data^7')
            return
        end
        
        local latestVersion = versionData.version
        local versionStatus = CompareVersions(CURRENT_VERSION, latestVersion)
        
        print('^3========================================^7')
        print('^5[' .. RESOURCE_NAME .. '] Version Checker^7')
        print('^3========================================^7')
        print('^2Current Version: ^7' .. CURRENT_VERSION)
        print('^2Latest Version:  ^7' .. latestVersion)
        print('')
        
        if versionStatus == 'current' then
            print('^2✓ You are running the latest version!^7')
        elseif versionStatus == 'ahead' then
            print('^3⚠ You are running a NEWER version than released!^7')
            print('^3This may be a development version.^7')
        elseif versionStatus == 'outdated' then
            print('^1⚠ UPDATE AVAILABLE!^7')
            print('')
            
            if versionData.changelog and versionData.changelog[latestVersion] then
                local changelog = versionData.changelog[latestVersion]
                
                if changelog.date then
                    print('^6Release Date: ^7' .. changelog.date)
                    print('')
                end
                
                if changelog.changes and #changelog.changes > 0 then
                    print('^5Changes:^7')
                    for _, change in ipairs(changelog.changes) do
                        print('  ^2✓^7 ' .. change)
                    end
                    print('')
                end
                
                if changelog.files_to_update and #changelog.files_to_update > 0 then
                    print('^1Files that need to be updated:^7')
                    for _, file in ipairs(changelog.files_to_update) do
                        print('  ^3➤^7 ' .. file)
                    end
                    print('')
                end
            end
            
            print('^2Download: ^7https://github.com/ChrisNewmanDev/core_scoreboard/releases/latest')
        end
        
        print('^3========================================^7')
    end, 'GET')
end

CreateThread(function()
    Wait(2000)
    CheckVersion()
end)

print('^2[' .. RESOURCE_NAME .. '] ^7Server initialized - v' .. CURRENT_VERSION)

Citizen.CreateThread(function()
    for _, heist in ipairs(Config.Heists) do
        heistStates[heist.id] = {
            inProgress = false,
            cooldownRemaining = 0
        }
    end
end)

Citizen.CreateThread(function()
    while true do
        for heistId, state in pairs(heistStates) do
            if state.cooldownRemaining > 0 then
                state.cooldownRemaining = state.cooldownRemaining - 1
            end
        end
        Citizen.Wait(1000)
    end
end)

local function GetJobCounts()
    local jobs = {}
    local Players = QBCore.Functions.GetPlayers()

    for job, _ in pairs(Config.ShowJobs) do
        jobs[job] = 0
    end

    for _, playerId in ipairs(Players) do
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        if Player and Player.PlayerData and Player.PlayerData.job then
            local jobName = Player.PlayerData.job.name
            local onduty = Player.PlayerData.job.onduty
            if Config.ShowJobs[jobName] and (onduty == nil or onduty == true) then
                jobs[jobName] = (jobs[jobName] or 0) + 1
            end
        end
    end

    return jobs
end

local function GetHeistStates()
    local heists = {}
    for _, heist in ipairs(Config.Heists) do
        local state = heistStates[heist.id]
        table.insert(heists, {
            name = heist.name,
            id = heist.id,
            minPD = heist.minPD,
            inProgress = state.inProgress,
            cooldownRemaining = state.cooldownRemaining
        })
    end
    return heists
end

QBCore.Functions.CreateCallback('core-scoreboard:getServerData', function(source, cb)
    local jobDisplay = {}
    for job,_ in pairs(Config.ShowJobs) do
        local displayName = nil
        if Config.JobDisplayNames and Config.JobDisplayNames[job] then
            displayName = Config.JobDisplayNames[job]
        elseif QBCore.Shared and QBCore.Shared.Jobs and QBCore.Shared.Jobs[job] and QBCore.Shared.Jobs[job].label then
            displayName = QBCore.Shared.Jobs[job].label
        end
        if not displayName then
            displayName = job:gsub('^%l', string.upper)
        end
        jobDisplay[job] = displayName
    end

    if Config.TestPopulate then
        local fakeJobs = {}
        for job in pairs(Config.ShowJobs) do
            fakeJobs[job] = math.random(1, 20)
        end
        -- Also generate fake player entries for testing
        local fakePlayers = {}
        for i=1,100 do
            -- pick a random job from the configured jobs
            local jobKeys = {}
            for k,_ in pairs(Config.ShowJobs) do table.insert(jobKeys, k) end
            local randJob = jobKeys[math.random(1, #jobKeys)]
            table.insert(fakePlayers, { id = i, name = ('TestPlayer%d'):format(i), job = jobDisplay[randJob] or randJob })
        end
        cb({
            players = fakePlayers,
            jobs = fakeJobs,
            jobDisplayNames = jobDisplay,
            heists = GetHeistStates()
        })
    else
        -- Build a players table (id, name, job label) to send to clients
        local players = {}
        local allPlayers = QBCore.Functions.GetPlayers()
        for _, pid in ipairs(allPlayers) do
            local ply = QBCore.Functions.GetPlayer(tonumber(pid))
            local name = GetPlayerName(tonumber(pid)) or ('Player ' .. tostring(pid))
            local jobLabel = 'Unemployed'
            if ply and ply.PlayerData and ply.PlayerData.job then
                local jobName = ply.PlayerData.job.name
                -- Prefer config override, then QBCore job label, then the player's job label/name
                if Config.JobDisplayNames and Config.JobDisplayNames[jobName] then
                    jobLabel = Config.JobDisplayNames[jobName]
                elseif QBCore.Shared and QBCore.Shared.Jobs and QBCore.Shared.Jobs[jobName] and QBCore.Shared.Jobs[jobName].label then
                    jobLabel = QBCore.Shared.Jobs[jobName].label
                else
                    jobLabel = ply.PlayerData.job.label or ply.PlayerData.job.name or jobLabel
                end
            end
            table.insert(players, {
                id = tonumber(pid),
                name = name,
                job = jobLabel
            })
        end

        cb({
            players = players,
            jobs = GetJobCounts(),
            jobDisplayNames = jobDisplay,
            heists = GetHeistStates()
        })
    end
end)

-- Export functions for other resources to use
exports('startHeist', function(heistId)
    if heistStates[heistId] and not heistStates[heistId].inProgress and heistStates[heistId].cooldownRemaining <= 0 then
        heistStates[heistId].inProgress = true
        return true
    end
    return false
end)

exports('endHeist', function(heistId)
    if heistStates[heistId] then
        heistStates[heistId].inProgress = false
        -- Find the heist config to get the cooldown time
        for _, heist in ipairs(Config.Heists) do
            if heist.id == heistId then
                heistStates[heistId].cooldownRemaining = heist.cooldown
                break
            end
        end
        return true
    end
    return false
end)

-- Add command to reset heist states (for admins)
RegisterCommand('resetheists', function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player and Player.PlayerData.permission == 'admin' then
        for heistId, _ in pairs(heistStates) do
            heistStates[heistId] = {
                inProgress = false,
                cooldownRemaining = 0
            }
        end
        TriggerClientEvent('QBCore:Notify', source, 'All heist states have been reset.', 'success')
    end
end)