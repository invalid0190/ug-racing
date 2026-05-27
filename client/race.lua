local IsRacing = false
local CurrentCheckpoint = 0
local TotalCheckpoints = 0
local Checkpoints = {}
local RaceStartTime = 0
local RaceData = {}
local PoliceNearby = false
local RaceCancelled = false
local FinishedSent = false
local ActiveCheckpointBlip = nil
local LastWrongWayWarning = 0
local LastVehicleWarning = 0
local LastPoliceWarning = 0

local function Notify(data)
    lib.notify(data)
end

local function IsAllowedRaceVehicle(vehicle)
    if not vehicle or vehicle == 0 then return false end
    return Config.AllowedVehicleClasses[GetVehicleClass(vehicle)] == true
end

-- Removes the current checkpoint blip and clears GPS guidance.
local function ClearCheckpointBlip()
    if ActiveCheckpointBlip and DoesBlipExist(ActiveCheckpointBlip) then
        RemoveBlip(ActiveCheckpointBlip)
    end

    ActiveCheckpointBlip = nil
end

-- Keeps only one checkpoint blip alive and points GPS at the next target.
local function SetCheckpointBlip(coords, isFinish)
    ClearCheckpointBlip()
    if not coords then return end

    ActiveCheckpointBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(ActiveCheckpointBlip, isFinish and 38 or 1)
    SetBlipColour(ActiveCheckpointBlip, isFinish and 2 or 5)
    SetBlipScale(ActiveCheckpointBlip, 0.9)
    SetBlipRoute(ActiveCheckpointBlip, true)
    SetBlipRouteColour(ActiveCheckpointBlip, isFinish and 2 or 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(isFinish and 'Race Finish' or 'Race Checkpoint')
    EndTextCommandSetBlipName(ActiveCheckpointBlip)
end

local function ResetRaceState(hideHud)
    IsRacing = false
    RaceCancelled = true
    FinishedSent = false
    CurrentCheckpoint = 0
    TotalCheckpoints = 0
    Checkpoints = {}
    RaceData = {}
    PoliceNearby = false
    LastPoliceWarning = 0
    ClearCheckpointBlip()

    if hideHud then
        NUI.SendMessage('hideRaceHUD')
    end
end

local function AdvanceCheckpoint()
    CurrentCheckpoint = CurrentCheckpoint + 1
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)

    if CurrentCheckpoint >= TotalCheckpoints then
        if FinishedSent then return end

        FinishedSent = true
        local finishTime = GetGameTimer() - RaceStartTime
        TriggerServerEvent('streetracing:server:playerFinished', finishTime)
        ClearCheckpointBlip()
        Notify({ title = 'Finished', description = 'Waiting for race results...', type = 'success' })
        return
    end

    local nextCheckpoint = Checkpoints[CurrentCheckpoint + 1]
    SetCheckpointBlip(nextCheckpoint, CurrentCheckpoint == TotalCheckpoints - 1)
    NUI.SendMessage('updateCheckpoint', {
        current = CurrentCheckpoint,
        total = TotalCheckpoints
    })
end

-- Starts the live checkpoint, HUD, timeout, and warning loops for a race.
RegisterNetEvent('streetracing:client:raceStart', function(data)
    data = data or {}
    if type(data.checkpoints) ~= 'table' or #data.checkpoints == 0 then
        Notify({ title = 'Race Error', description = 'Race checkpoints were missing', type = 'error' })
        return
    end

    IsRacing = true
    RaceCancelled = false
    FinishedSent = false
    CurrentCheckpoint = 0
    Checkpoints = data.checkpoints
    TotalCheckpoints = #Checkpoints
    RaceData = data.lobby or {}
    RaceStartTime = GetGameTimer()
    LastWrongWayWarning = 0
    LastVehicleWarning = 0
    LastPoliceWarning = 0

    if lib.hideContext then
        lib.hideContext(false)
    end

    NUI.SendMessage('showRaceHUD', {
        totalCheckpoints = TotalCheckpoints,
        players = RaceData.players or {}
    })

    SetCheckpointBlip(Checkpoints[1], TotalCheckpoints == 1)

    CreateThread(function()
        local timeoutAt = RaceStartTime + (Config.RaceTimeoutMinutes * 60 * 1000)

        while IsRacing and not RaceCancelled do
            if GetGameTimer() >= timeoutAt then
                Notify({ title = 'Race Timed Out', description = 'You did not finish before the race timer expired', type = 'error' })
                ResetRaceState(true)
                break
            end

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)

            if playerVehicle ~= 0 and IsAllowedRaceVehicle(playerVehicle) then
                if CurrentCheckpoint < TotalCheckpoints then
                    local nextCheckpoint = Checkpoints[CurrentCheckpoint + 1]
                    if nextCheckpoint then
                        local dist = #(playerCoords - nextCheckpoint)
                        if dist <= Config.CheckpointRadius then
                            AdvanceCheckpoint()
                        else
                            DrawCheckpointMarker(nextCheckpoint, CurrentCheckpoint == TotalCheckpoints - 1)
                        end
                    end
                end

                local speedMph = math.floor(GetEntitySpeed(playerVehicle) * 2.23694)
                NUI.SendMessage('updateSpeed', { speed = speedMph })
            else
                local now = GetGameTimer()
                if now - LastVehicleWarning > 5000 then
                    LastVehicleWarning = now
                    Notify({
                        title = 'Vehicle Required',
                        description = 'Stay in an allowed race vehicle during the race',
                        type = 'warning'
                    })
                end
            end

            Wait(0)
        end
    end)

    PoliceNearby = false
end)

-- Shows countdown UI and positions/freeze the player's vehicle for launch.
RegisterNetEvent('streetracing:client:raceStarting', function(data)
    data = data or {}
    RaceData = data.lobby or {}
    local countdown = tonumber(data.countdown) or Config.CountdownTime or 5

    if lib.hideContext then
        lib.hideContext(false)
    end

    NUI.Close()
    NUI.SendMessage('showCountdown', {
        countdown = countdown,
        routeName = RaceData.route and RaceData.route.name or 'Race'
    })

    local checkpoints = RaceData.route and RaceData.route.checkpoints
    local startPos = checkpoints and checkpoints[1]
    local secondPos = checkpoints and checkpoints[2]
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle and vehicle ~= 0 and startPos then
        SetEntityCoords(vehicle, startPos.x, startPos.y, startPos.z + 1.0, false, false, false, false)

        if secondPos then
            local heading = GetHeadingFromVector_2d(secondPos.x - startPos.x, secondPos.y - startPos.y)
            SetEntityHeading(vehicle, heading)
        end

        FreezeEntityPosition(vehicle, true)
        CreateThread(function()
            Wait(countdown * 1000)
            if DoesEntityExist(vehicle) then
                FreezeEntityPosition(vehicle, false)
            end
        end)
    else
        Notify({ title = 'Vehicle Required', description = 'Get into your race vehicle before launch', type = 'error' })
    end
end)

RegisterNetEvent('streetracing:client:playerFinished', function(data)
    data = data or {}
    NUI.SendMessage('playerFinished', data)
    Notify({
        title = ('%s finished #%d!'):format(data.name or 'A racer', data.position or 0),
        type = 'inform'
    })
end)

RegisterNetEvent('streetracing:client:raceResults', function(data)
    data = data or {}
    IsRacing = false
    RaceCancelled = false
    ClearCheckpointBlip()

    NUI.SendFocusedMessage('showResults', {
        results = data.results or {},
        prizePool = data.prizePool or 0,
        reason = data.reason or 'complete'
    })

    CurrentCheckpoint = 0
    Checkpoints = {}
end)

RegisterNetEvent('streetracing:client:raceCancelled', function(reason)
    ResetRaceState(true)
    Notify({
        title = 'Race Cancelled',
        description = reason or 'The race has been cancelled',
        type = 'error'
    })
end)

RegisterNetEvent('streetracing:client:policeWarning', function(data)
    data = data or {}
    if data.scatter then
        ResetRaceState(true)
        Notify({
            title = 'POLICE RAID!',
            description = 'Scatter! The cops are busting the race!',
            type = 'error'
        })
        return
    end

    if not IsRacing or RaceCancelled then return end

    local now = GetGameTimer()
    local cooldown = Config.PoliceWarningCooldown or 30000
    if now - LastPoliceWarning < cooldown then return end

    LastPoliceWarning = now
    PoliceNearby = true
    Notify({
        title = 'Police Nearby!',
        description = 'A cop is near the race area. Be careful!',
        type = 'warning'
    })

    NUI.SendMessage('policeWarning')
end)

function DrawCheckpointMarker(coords, isFinish)
    if not coords then return end
    local color = isFinish and Config.Colors.finish or Config.Colors.checkpoint

    DrawMarker(1,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.CheckpointRadius * 2.0, Config.CheckpointRadius * 2.0, 3.0,
        color.r, color.g, color.b, 200,
        false, false, 2, false, nil, nil, false
    )

    DrawMarker(32,
        coords.x, coords.y, coords.z + 5.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        2.0, 2.0, 2.0,
        color.r, color.g, color.b, 255,
        false, false, 2, false, nil, nil, false
    )
end

CreateThread(function()
    while true do
        if IsRacing and not RaceCancelled and CurrentCheckpoint < TotalCheckpoints then
            local nextCp = Checkpoints[CurrentCheckpoint + 1]
            if nextCp then
                local dist = #(GetEntityCoords(PlayerPedId()) - nextCp)
                local now = GetGameTimer()

                if dist > Config.MaxDistanceFromRoute and now - LastWrongWayWarning > 5000 then
                    LastWrongWayWarning = now
                    Notify({
                        title = 'Wrong Way!',
                        description = 'You have strayed too far from the route',
                        type = 'error'
                    })
                    NUI.SendMessage('wrongWay')
                end
            end
        end

        Wait(2000)
    end
end)

RegisterCommand('leaverace', function()
    if CurrentLobby or IsRacing then
        TriggerServerEvent('streetracing:server:leaveLobby')
        ResetRaceState(true)
    else
        Notify({
            title = 'Not in Race',
            description = 'You are not currently in a race',
            type = 'error'
        })
    end
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ResetRaceState(true)
    end
end)
