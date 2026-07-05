local RESOURCE_NAME = GetCurrentResourceName()
local LOG_PREFIX = '[racing-system]'

local SpikeStrips = {}
local SpikeCooldowns = {}

local function LogError(message)
    print(('%s ERROR: %s'):format(LOG_PREFIX, message))
end

local function Notify(src, data)
    if not src or src == 0 then return end
    TriggerClientEvent('ox_lib:notify', src, LocalizeNotification(data))
end

local function NormalizeSource(value)
    local src = tonumber(value)
    if not src or src <= 0 or not GetPlayerName(src) then return nil end
    return src
end

local function GetPlayerCoords(src)
    src = NormalizeSource(src)
    if not src then return nil end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    if type(DoesEntityExist) == 'function' then
        local existsOk, exists = pcall(DoesEntityExist, ped)
        if existsOk and not exists then return nil end
    end

    return GetEntityCoords(ped), ped
end

-- Counts nearby officers/placeholders using normalized server ids for native calls.
local function CheckPoliceInArea(coords, radius)
    if not coords or not radius then return 0, {} end

    local policeCount = 0
    local policeList = {}

    for _, playerId in ipairs(GetPlayers()) do
        local src = NormalizeSource(playerId)
        local playerCoords = src and GetPlayerCoords(src)

        if playerCoords then
            local distance = #(playerCoords - coords)
            if distance <= radius then
                table.insert(policeList, {
                    src = src,
                    distance = distance
                })
                policeCount = policeCount + 1
            end
        end
    end

    return policeCount, policeList
end

-- Deploys one timed spike strip per cooldown window.
RegisterCommand('spike', function(source)
    local src = NormalizeSource(source)
    if not src then return end

    local now = GetGameTimer()
    if SpikeCooldowns[src] and now - SpikeCooldowns[src] < Config.SpikeStripCooldown then
        local remaining = math.ceil((Config.SpikeStripCooldown - (now - SpikeCooldowns[src])) / 1000)
        Notify(src, {
            title = 'Cooldown',
            description = ('Wait %d seconds before deploying another spike strip'):format(remaining),
            type = 'error'
        })
        return
    end

    local coords, ped = GetPlayerCoords(src)
    if not coords or not ped then
        Notify(src, { title = 'Error', description = 'Could not read your position', type = 'error' })
        return
    end

    local heading = GetEntityHeading(ped)
    local spikeId = ('spike_%d_%d'):format(src, now)
    SpikeStrips[spikeId] = {
        id = spikeId,
        owner = src,
        coords = coords,
        heading = heading,
        createdAt = now,
        hitBy = {}
    }

    for _, playerId in ipairs(GetPlayers()) do
        local targetSrc = NormalizeSource(playerId)
        local targetCoords = targetSrc and GetPlayerCoords(targetSrc)

        if targetSrc and targetCoords and #(targetCoords - coords) < 100.0 then
            TriggerClientEvent('streetracing:client:createSpikeStrip', targetSrc, {
                id = spikeId,
                coords = coords,
                heading = heading
            })
        end
    end

    SpikeCooldowns[src] = now
    Notify(src, {
        title = 'Spike Strip Deployed',
        description = 'Spike strip will expire in 30 seconds',
        type = 'success'
    })

    SetTimeout(Config.SpikeStripDuration, function()
        if SpikeStrips[spikeId] then
            TriggerClientEvent('streetracing:client:removeSpikeStrip', -1, spikeId)
            SpikeStrips[spikeId] = nil
        end
    end)
end, false)

-- Removes the caller's active spike strip.
RegisterCommand('removespike', function(source)
    local src = NormalizeSource(source)
    if not src then return end

    local removed = false
    for spikeId, spike in pairs(SpikeStrips) do
        if spike.owner == src then
            TriggerClientEvent('streetracing:client:removeSpikeStrip', -1, spikeId)
            SpikeStrips[spikeId] = nil
            removed = true
            break
        end
    end

    if removed then
        Notify(src, { title = 'Spike Removed', description = 'Your spike strip has been removed', type = 'success' })
    else
        Notify(src, { title = 'No Spike', description = 'You have no active spike strips', type = 'error' })
    end
end, false)

-- Validates spike hits server-side so clients cannot spoof distant tire bursts.
RegisterNetEvent('streetracing:server:hitSpikeStrip', function(spikeId)
    local src = NormalizeSource(source)
    if not src or type(spikeId) ~= 'string' then return end

    local spike = SpikeStrips[spikeId]
    if not spike or spike.hitBy[src] then return end

    local coords = GetPlayerCoords(src)
    if not coords or #(coords - spike.coords) > Config.InteractionDistances.spikeStrip then
        LogError(('Rejected spoofed spike hit from source %s for %s'):format(src, spikeId))
        return
    end

    spike.hitBy[src] = true
    TriggerClientEvent('streetracing:client:burstTires', src)
    Notify(src, {
        title = 'SPIKED!',
        description = 'You hit a spike strip! Your tires are blown!',
        type = 'error'
    })
end)

-- Scans both waiting and active races using the current resource export name.
RegisterCommand('scanraces', function(source)
    local src = NormalizeSource(source)
    if not src then return end

    local races = exports[RESOURCE_NAME]:GetLobbies()
    local activeRaces = exports[RESOURCE_NAME]:GetActiveRaces()
    local activeCount = 0

    local function reportRace(lobby)
        if not lobby or not lobby.route or not lobby.route.checkpoints then return end

        activeCount = activeCount + 1
        local startCoords = lobby.route.checkpoints[1]
        Notify(src, {
            title = 'Street Race Detected',
            description = ('Route: %s | Players: %d'):format(lobby.route.name, #lobby.players),
            type = 'warning'
        })
        TriggerClientEvent('streetracing:client:setRaceGPS', src, startCoords)
    end

    for _, lobby in pairs(races) do
        if lobby.status == 'starting' then reportRace(lobby) end
    end

    for _, lobby in pairs(activeRaces) do
        if lobby.status == 'racing' then reportRace(lobby) end
    end

    if activeCount == 0 then
        Notify(src, { title = 'No Active Races', description = 'No street races detected in the area', type = 'inform' })
    end
end, false)

exports('GetPoliceInArea', CheckPoliceInArea)

exports('GetSpikeStrips', function()
    return SpikeStrips
end)
