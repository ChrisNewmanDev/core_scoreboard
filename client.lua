local display = false
local QBCore = exports['qb-core']:GetCoreObject()

local function GetPlayers()
    local players = {}
    local active = GetActivePlayers()
    for _, ply in ipairs(active) do
        local serverId = GetPlayerServerId(ply)
        table.insert(players, {
            id = serverId,
            name = GetPlayerName(ply) or ('Player ' .. tostring(serverId)),
            job = ''
        })
    end
    return players
end

local function UpdateScoreboard()
    if display then
        QBCore.Functions.TriggerCallback('core-scoreboard:getServerData', function(data)
            local players = data.players or GetPlayers()

            SendNUIMessage({
                type = 'update',
                players = players,
                serverName = Config.ServerName,
                jobs = data.jobs,
                jobOrder = Config.JobOrder,
                jobColors = Config.JobColors,
                jobDisplayNames = data.jobDisplayNames,
                heists = data.heists
            })
        end)
    end
end

RegisterCommand('togglescoreboard', function()
    display = not display
    SendNUIMessage({ type = 'toggle', show = display })
    SetNuiFocus(display, display)
    if display then
        UpdateScoreboard()
    end
end)

RegisterKeyMapping('togglescoreboard', 'Toggle Scoreboard', 'keyboard', Config.Key)

RegisterNUICallback('closeScoreboard', function(data, cb)
    display = false
    SendNUIMessage({
        type = 'toggle',
        show = false
    })
    SetNuiFocus(false, false)
    cb('ok')
end)

Citizen.CreateThread(function()
    while true do
        if display then
            UpdateScoreboard()
        end
        Citizen.Wait(1000)
    end
end)