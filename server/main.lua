local RESOURCE_NAME = GetCurrentResourceName()
local LOG_PREFIX = '[racing-system]'

local RaceLobbies = {}
local ActiveRaces = {}
local PlayerLobby = {}
local PlayerReputation = {}
local PlayerCooldowns = {}
local ReputationLoaded = false

local function LogError(message)
    print(('%s ERROR: %s'):format(LOG_PREFIX, message))
end

local function LogInfo(message)
    print(('%s %s'):format(LOG_PREFIX, message))
end

local function Notify(src, data)
    if not src or src == 0 then return end
    TriggerClientEvent('ox_lib:notify', src, data)
end

-- Normalizes FiveM string player ids before they are used with server natives.
local function NormalizeSource(value)
    local src = tonumber(value)
    if not src or src <= 0 or not GetPlayerName(src) then return nil end
    return src
end

-- Returns the most stable available identifier for JSON reputation persistence.
local function GetStableIdentifier(src)
    src = NormalizeSource(src)
    if not src then return nil end

    local identifier = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifierByType(src, 'steam')
    return identifier or ('src:%d'):format(src)
end

-- Uses the live server id for lobby membership so two local test clients with the same license can race together.
local function GetLobbyKey(src)
    src = NormalizeSource(src)
    if not src then return nil end

    return ('src:%d'):format(src)
end

local function LoadReputation()
    if ReputationLoaded then return end
    ReputationLoaded = true

    local raw = LoadResourceFile(RESOURCE_NAME, Config.ReputationFile)
    if not raw or raw == '' then
        PlayerReputation = {}
        return
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        LogError(('Failed to decode %s; starting with empty reputation table'):format(Config.ReputationFile))
        PlayerReputation = {}
        return
    end

    PlayerReputation = decoded

    local count = 0
    for _ in pairs(PlayerReputation) do count = count + 1 end
    LogInfo(('Loaded reputation for %d racers'):format(count))
end

local function OrganizerCoords()
    return vector3(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z)
end

local function SaveReputation()
    local ok, encoded = pcall(json.encode, PlayerReputation)
    if not ok then
        LogError('Failed to encode reputation data')
        return false
    end

    local saved = SaveResourceFile(RESOURCE_NAME, Config.ReputationFile, encoded, -1)
    if not saved then
        LogError(('Failed to save %s'):format(Config.ReputationFile))
    end

    return saved == true
end

-- Initializes a player's reputation record from JSON-backed storage.
local function InitPlayerRep(src)
    local identifier = GetStableIdentifier(src)
    if not identifier then return 0 end

    local rep = tonumber(PlayerReputation[identifier]) or 0
    PlayerReputation[identifier] = rep
    return rep
end

local function AddPlayerRep(identifier, amount)
    if not identifier then return 0 end

    local current = tonumber(PlayerReputation[identifier]) or 0
    PlayerReputation[identifier] = math.max(0, current + (tonumber(amount) or 0))
    SaveReputation()
    return PlayerReputation[identifier]
end

local function FindRoute(routeId)
    if type(routeId) ~= 'string' then return nil end

    for _, route in ipairs(Config.Routes) do
        if route.id == routeId then return route end
    end

    return nil
end

local function GenerateLobbyId()
    local id
    repeat
        id = ('race_%d_%d'):format(os.time(), math.random(1000, 9999))
    until not RaceLobbies[id] and not ActiveRaces[id]

    return id
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

-- Validates the server-side distance between a player and an interaction point.
local function ValidateDistance(src, coords, maxDistance, action)
    local playerCoords = GetPlayerCoords(src)
    if not playerCoords or not coords then
        LogError(('Missing coordinates while validating %s for source %s'):format(action or 'interaction', tostring(src)))
        return false
    end

    local distance = #(playerCoords - coords)
    if distance > maxDistance then
        LogError(('Rejected %s from source %s at %.2fm (allowed %.2fm)'):format(action or 'interaction', tostring(src), distance, maxDistance))
        return false
    end

    return true
end

local function NativeExists(name)
    return type(_G[name]) == 'function'
end

local function SafeNative(name, ...)
    if not NativeExists(name) then return false, nil end

    local ok, result = pcall(_G[name], ...)
    if not ok then
        LogError(('%s failed: %s'):format(name, tostring(result)))
        return false, nil
    end

    return true, result
end

-- Ensures racers are driving an allowed vehicle before the race starts or finishes.
local function ValidateRaceVehicle(src)
    local _, ped = GetPlayerCoords(src)
    if not ped then return false, 'Player ped not found' end

    local vehicleOk, vehicle = SafeNative('GetVehiclePedIsIn', ped, false)
    if not vehicleOk then
        return true
    end

    local vehicleExists = true
    local existsOk, exists = SafeNative('DoesEntityExist', vehicle)
    if existsOk then vehicleExists = exists end

    if not vehicle or vehicle == 0 or not vehicleExists then
        return false, 'You must be in a vehicle to race'
    end

    local seatOk, driverPed = SafeNative('GetPedInVehicleSeat', vehicle, -1)
    if seatOk and driverPed ~= ped then
        return false, 'You must be the driver to race'
    end

    local classOk, class = SafeNative('GetVehicleClass', vehicle)
    if classOk and class ~= nil and not Config.AllowedVehicleClasses[class] then
        return false, 'This vehicle class is not allowed in races'
    end

    return true
end

local function EconomyEnabled()
    return Config.Economy and Config.Economy.enabled and Config.Economy.type == 'ox_inventory'
        and GetResourceState('ox_inventory') == 'started'
end

local function RemoveEntryFee(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    if not EconomyEnabled() then return true end

    local ok, removed = pcall(function()
        return exports.ox_inventory:RemoveItem(src, Config.Economy.cashItem, amount)
    end)

    if not ok then
        LogError(('ox_inventory RemoveItem failed for source %s'):format(tostring(src)))
        return false
    end

    return removed == true
end

local function AddPrizeMoney(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not EconomyEnabled() then return true end

    local ok, added = pcall(function()
        return exports.ox_inventory:AddItem(src, Config.Economy.cashItem, amount)
    end)

    if not ok then
        LogError(('ox_inventory AddItem failed for source %s'):format(tostring(src)))
        return false
    end

    return added == true
end

local function RefundEntry(player, amount)
    if player and player.paid and not player.refunded and EconomyEnabled() then
        AddPrizeMoney(player.src, amount)
        player.refunded = true
    end
end

local function FindLobbyPlayer(lobby, sessionId)
    if not lobby or not sessionId then return nil, nil end

    for index, player in ipairs(lobby.players) do
        if player.sessionId == sessionId or player.identifier == sessionId then
            return player, index
        end
    end

    return nil, nil
end

local function IsConfiguredPoliceJob(job)
    if type(job) ~= 'table' or job.onduty == false then return false end

    local policeJobs = Config.PoliceJobs or {}
    if job.name and policeJobs[job.name] then return true end
    if job.type and policeJobs[job.type] then return true end

    return job.name == Config.PoliceJobName
end

-- Detects real on-duty police through common frameworks or an optional ace permission.
local function IsPoliceSource(src)
    src = NormalizeSource(src)
    if not src then return false end

    if GetResourceState('qbx_core') == 'started' then
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(src)
        end)

        if ok and player and player.PlayerData and IsConfiguredPoliceJob(player.PlayerData.job) then
            return true
        end
    end

    if GetResourceState('qb-core') == 'started' then
        local ok, player = pcall(function()
            local core = exports['qb-core']:GetCoreObject()
            return core and core.Functions and core.Functions.GetPlayer(src)
        end)

        if ok and player and player.PlayerData and IsConfiguredPoliceJob(player.PlayerData.job) then
            return true
        end
    end

    return IsPlayerAceAllowed(src, 'racing.police') == true
end

local function CountNearbyPolice(lobby)
    if not lobby or type(lobby.players) ~= 'table' then return 0 end

    local radius = tonumber(Config.PoliceWarningRadius) or 150.0
    local racerCoords = {}
    for _, player in ipairs(lobby.players) do
        local coords = GetPlayerCoords(player.src)
        if coords then racerCoords[#racerCoords + 1] = coords end
    end

    if #racerCoords == 0 then return 0 end

    local nearby = 0
    for _, playerId in ipairs(GetPlayers()) do
        local policeSrc = NormalizeSource(playerId)
        local policeSessionId = policeSrc and GetLobbyKey(policeSrc)

        if policeSrc and not FindLobbyPlayer(lobby, policeSessionId) and IsPoliceSource(policeSrc) then
            local policeCoords = GetPlayerCoords(policeSrc)
            if policeCoords then
                for _, coords in ipairs(racerCoords) do
                    if #(policeCoords - coords) <= radius then
                        nearby = nearby + 1
                        break
                    end
                end
            end
        end
    end

    return nearby
end

local function StartPoliceWarningMonitor(lobbyId)
    CreateThread(function()
        while ActiveRaces[lobbyId] and not ActiveRaces[lobbyId].settled do
            local lobby = ActiveRaces[lobbyId]
            local policeCount = CountNearbyPolice(lobby)
            local now = GetGameTimer()
            local cooldown = tonumber(Config.PoliceWarningCooldown) or 30000

            if policeCount > 0 then
                if not lobby.policeNearby or now - (lobby.lastPoliceWarning or 0) >= cooldown then
                    lobby.policeNearby = true
                    lobby.lastPoliceWarning = now
                    for _, player in ipairs(lobby.players) do
                        TriggerClientEvent('streetracing:client:policeWarning', player.src, {
                            count = policeCount
                        })
                    end
                end
            else
                lobby.policeNearby = false
            end

            Wait(tonumber(Config.PoliceWarningCheckInterval) or 5000)
        end
    end)
end

local function BroadcastLobby(lobby)
    if not lobby then return end

    for _, player in ipairs(lobby.players) do
        TriggerClientEvent('streetracing:client:lobbyUpdate', player.src, lobby)
    end
end

-- Builds the public waiting-lobby list shown to racers who are not already in a lobby.
local function BuildAvailableLobbies()
    local availableLobbies = {}

    for _, lobby in pairs(RaceLobbies) do
        if lobby.status == 'waiting' then
            table.insert(availableLobbies, {
                id = lobby.id,
                routeName = lobby.route.name,
                routeId = lobby.route.id,
                hostName = GetPlayerName(lobby.host) or 'Unknown',
                playerCount = #lobby.players,
                maxPlayers = Config.MaxPlayers,
                betAmount = lobby.betAmount,
                prizePool = lobby.prizePool,
                minRep = lobby.route.minRep
            })
        end
    end

    return availableLobbies
end

local function BroadcastAvailableLobbies(target)
    TriggerClientEvent('streetracing:client:receiveLobbies', target or -1, BuildAvailableLobbies())
end

local callbackApi = lib and type(lib.callback) == 'table' and lib.callback or nil
if callbackApi and type(callbackApi.register) == 'function' then
    -- Provides a current lobby snapshot for ox_lib menus without relying on event timing.
    callbackApi.register('streetracing:server:getAvailableLobbies', function(source)
        local src = NormalizeSource(source)
        if not src then return {} end

        return BuildAvailableLobbies()
    end)
else
    LogError('ox_lib callback API is unavailable; lobby list will use event fallback')
end

local function CleanupRace(lobbyId)
    local lobby = ActiveRaces[lobbyId] or RaceLobbies[lobbyId]
    if lobby then
        for _, player in ipairs(lobby.players) do
            PlayerLobby[player.sessionId or player.identifier] = nil
        end
    end

    ActiveRaces[lobbyId] = nil
    RaceLobbies[lobbyId] = nil
end

-- Settles a race exactly once, awards reputation, and pays the winner if economy is enabled.
local function FinalizeRace(lobbyId, reason)
    local lobby = ActiveRaces[lobbyId]
    if not lobby or lobby.settled then return end
    lobby.settled = true

    local results = {}
    for _, finisher in ipairs(lobby.finishOrder or {}) do
        table.insert(results, finisher)
    end

    for _, player in ipairs(lobby.players) do
        if not lobby.finished[player.sessionId or player.identifier] then
            table.insert(results, {
                src = player.src,
                sessionId = player.sessionId,
                identifier = player.identifier,
                name = player.name,
                time = nil,
                dnf = true
            })
        end
    end

    if reason == 'timeout' and #(lobby.finishOrder or {}) == 0 then
        for _, player in ipairs(lobby.players) do
            RefundEntry(player, lobby.betAmount)
            TriggerClientEvent('streetracing:client:raceCancelled', player.src, 'Race timed out before anyone finished')
        end
        CleanupRace(lobbyId)
        return
    end

    for index, result in ipairs(results) do
        local repGain = Config.RepRewards.participate
        if not result.dnf then
            if index == 1 then repGain = Config.RepRewards.win
            elseif index == 2 then repGain = Config.RepRewards.second
            elseif index == 3 then repGain = Config.RepRewards.third
            end
        end

        result.position = index
        result.repGained = repGain
        result.totalRep = AddPlayerRep(result.identifier, repGain)
    end

    if results[1] and not results[1].dnf and not lobby.prizePaid then
        lobby.prizePaid = true
        results[1].prizeWon = lobby.prizePool
        if not AddPrizeMoney(results[1].src, lobby.prizePool) then
            LogError(('Prize payout failed for race %s winner %s'):format(lobbyId, tostring(results[1].src)))
        end
    end

    for _, player in ipairs(lobby.players) do
        TriggerClientEvent('streetracing:client:raceResults', player.src, {
            results = results,
            prizePool = lobby.prizePool,
            reason = reason or 'complete'
        })
    end

    CleanupRace(lobbyId)
end

local function CancelLobby(lobbyId, description, refund)
    local lobby = RaceLobbies[lobbyId] or ActiveRaces[lobbyId]
    if not lobby then return end

    for _, player in ipairs(lobby.players) do
        if refund then RefundEntry(player, lobby.betAmount) end
        TriggerClientEvent('streetracing:client:raceCancelled', player.src, description or 'Race cancelled')
        PlayerLobby[player.sessionId or player.identifier] = nil
    end

    RaceLobbies[lobbyId] = nil
    ActiveRaces[lobbyId] = nil
end

local function CheckRaceComplete(lobbyId)
    local lobby = ActiveRaces[lobbyId]
    if lobby and #(lobby.finishOrder or {}) >= #lobby.players then
        FinalizeRace(lobbyId, 'complete')
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == RESOURCE_NAME then
        LoadReputation()
    end
end)

CreateThread(function()
    LoadReputation()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == RESOURCE_NAME then
        SaveReputation()
    end
end)

exports('GetLobbies', function()
    return RaceLobbies
end)

exports('GetActiveRaces', function()
    return ActiveRaces
end)

exports('GetPlayerRep', function(src)
    local identifier = GetStableIdentifier(src)
    return identifier and (tonumber(PlayerReputation[identifier]) or 0) or 0
end)

exports('AddPlayerRep', function(src, amount)
    return AddPlayerRep(GetStableIdentifier(src), amount)
end)

exports('GetRepLeaderboard', function()
    local leaderboard = {}
    for identifier, rep in pairs(PlayerReputation) do
        table.insert(leaderboard, { identifier = identifier, rep = tonumber(rep) or 0 })
    end

    table.sort(leaderboard, function(a, b) return a.rep > b.rep end)
    return leaderboard
end)

-- Creates a lobby after validating route, rep, cooldown, distance, and entry payment.
RegisterNetEvent('streetracing:server:createLobby', function(routeId, betAmount)
    local src = NormalizeSource(source)
    if not src then return end

    local identifier = GetStableIdentifier(src)
    local sessionId = GetLobbyKey(src)
    if not identifier or not sessionId then return end

    local route = FindRoute(routeId)
    if not route then
        Notify(src, { title = 'Error', description = 'Invalid route selected', type = 'error' })
        return
    end

    if not ValidateDistance(src, OrganizerCoords(), Config.InteractionDistances.organizer, 'createLobby') then
        Notify(src, { title = 'Too Far Away', description = 'Talk to the race organizer to create a race', type = 'error' })
        return
    end

    local now = os.time()
    if PlayerCooldowns[identifier] and now - PlayerCooldowns[identifier] < Config.RaceCooldown then
        local remaining = Config.RaceCooldown - (now - PlayerCooldowns[identifier])
        Notify(src, { title = 'Cooldown', description = ('Wait %d seconds before creating another race'):format(remaining), type = 'error' })
        return
    end

    local playerRep = InitPlayerRep(src)
    if playerRep < route.minRep then
        Notify(src, {
            title = 'Access Denied',
            description = ('You need %d rep to access this route. Current: %d'):format(route.minRep, playerRep),
            type = 'error'
        })
        return
    end

    if PlayerLobby[sessionId] then
        Notify(src, { title = 'Error', description = 'You are already in a lobby', type = 'error' })
        return
    end

    local minimumBet = tonumber(route.entryFee) or 0
    local maximumBet = minimumBet * Config.MaxBetMultiplier
    local actualBet = math.floor(math.max(tonumber(betAmount) or minimumBet, minimumBet))
    actualBet = math.min(actualBet, maximumBet)

    if not RemoveEntryFee(src, actualBet) then
        Notify(src, { title = 'Not Enough Cash', description = ('You need $%d to enter this race'):format(actualBet), type = 'error' })
        return
    end

    local lobbyId = GenerateLobbyId()
    RaceLobbies[lobbyId] = {
        id = lobbyId,
        host = src,
        hostIdentifier = identifier,
        hostSessionId = sessionId,
        route = route,
        betAmount = actualBet,
        players = {
            {
                src = src,
                sessionId = sessionId,
                identifier = identifier,
                name = GetPlayerName(src) or ('Racer %d'):format(src),
                ready = false,
                isHost = true,
                paid = true
            }
        },
        prizePool = actualBet,
        status = 'waiting',
        createdAt = os.time(),
        economyEnabled = EconomyEnabled()
    }

    PlayerLobby[sessionId] = lobbyId
    PlayerCooldowns[identifier] = now

    Notify(src, {
        title = 'Lobby Created',
        description = ('Your race lobby is ready! Route: %s'):format(route.name),
        type = 'success'
    })

    TriggerClientEvent('streetracing:client:lobbyUpdate', src, RaceLobbies[lobbyId])
    BroadcastAvailableLobbies(-1)
end)

-- Adds a player to an existing lobby after server-side anti-cheat and payment checks.
RegisterNetEvent('streetracing:server:joinLobby', function(lobbyId)
    local src = NormalizeSource(source)
    if not src or type(lobbyId) ~= 'string' then return end

    local identifier = GetStableIdentifier(src)
    local sessionId = GetLobbyKey(src)
    if not identifier or not sessionId then return end

    local lobby = RaceLobbies[lobbyId]
    if not lobby then
        Notify(src, { title = 'Error', description = 'Lobby not found', type = 'error' })
        return
    end

    if not ValidateDistance(src, OrganizerCoords(), Config.InteractionDistances.organizer, 'joinLobby') then
        Notify(src, { title = 'Too Far Away', description = 'Talk to the race organizer to join a race', type = 'error' })
        return
    end

    if lobby.status ~= 'waiting' then
        Notify(src, { title = 'Error', description = 'This race has already started', type = 'error' })
        return
    end

    if #lobby.players >= Config.MaxPlayers then
        Notify(src, { title = 'Error', description = 'Lobby is full', type = 'error' })
        return
    end

    if PlayerLobby[sessionId] then
        Notify(src, { title = 'Error', description = 'You are already in a lobby', type = 'error' })
        return
    end

    local playerRep = InitPlayerRep(src)
    if playerRep < lobby.route.minRep then
        Notify(src, { title = 'Access Denied', description = ('You need %d rep for this race'):format(lobby.route.minRep), type = 'error' })
        return
    end

    if not RemoveEntryFee(src, lobby.betAmount) then
        Notify(src, { title = 'Not Enough Cash', description = ('You need $%d to enter this race'):format(lobby.betAmount), type = 'error' })
        return
    end

    table.insert(lobby.players, {
        src = src,
        sessionId = sessionId,
        identifier = identifier,
        name = GetPlayerName(src) or ('Racer %d'):format(src),
        ready = false,
        isHost = false,
        paid = true
    })

    lobby.prizePool = lobby.prizePool + lobby.betAmount
    PlayerLobby[sessionId] = lobbyId

    Notify(src, { title = 'Joined Race', description = ('Joined %s. Entry fee: $%d'):format(lobby.route.name, lobby.betAmount), type = 'success' })
    BroadcastLobby(lobby)
    BroadcastAvailableLobbies(-1)
end)

-- Leaves a waiting lobby with refund support, or marks the player out of an active race.
RegisterNetEvent('streetracing:server:leaveLobby', function()
    local src = NormalizeSource(source)
    if not src then return end

    local identifier = GetStableIdentifier(src)
    local sessionId = GetLobbyKey(src)
    if not identifier or not sessionId then return end

    local lobbyId = PlayerLobby[sessionId]
    if not lobbyId then
        Notify(src, { title = 'Error', description = 'You are not in a lobby', type = 'error' })
        return
    end

    local lobby = RaceLobbies[lobbyId] or ActiveRaces[lobbyId]
    if not lobby then
        PlayerLobby[sessionId] = nil
        return
    end

    local player, index = FindLobbyPlayer(lobby, sessionId)
    if not player then
        PlayerLobby[sessionId] = nil
        return
    end

    local wasHost = lobby.hostSessionId == sessionId or (not lobby.hostSessionId and lobby.hostIdentifier == identifier)
    if lobby.status == 'waiting' or lobby.status == 'starting' then
        RefundEntry(player, lobby.betAmount)
        lobby.prizePool = math.max(0, lobby.prizePool - lobby.betAmount)
    end

    table.remove(lobby.players, index)
    PlayerLobby[sessionId] = nil

    if wasHost and #lobby.players > 0 then
        lobby.host = lobby.players[1].src
        lobby.hostIdentifier = lobby.players[1].identifier
        lobby.hostSessionId = lobby.players[1].sessionId
        lobby.players[1].isHost = true
        Notify(lobby.host, { title = 'Host Transferred', description = 'You are now the host', type = 'inform' })
    end

    if #lobby.players == 0 then
        RaceLobbies[lobbyId] = nil
        ActiveRaces[lobbyId] = nil
    else
        BroadcastLobby(lobby)
        CheckRaceComplete(lobbyId)
    end

    TriggerClientEvent('streetracing:client:leftLobby', src)
    Notify(src, { title = 'Left Lobby', description = 'You left the race lobby', type = 'inform' })
    BroadcastAvailableLobbies(-1)
end)

RegisterNetEvent('streetracing:server:toggleReady', function()
    local src = NormalizeSource(source)
    if not src then return end

    local identifier = GetStableIdentifier(src)
    local sessionId = GetLobbyKey(src)
    if not identifier or not sessionId then return end

    local lobbyId = PlayerLobby[sessionId]
    local lobby = lobbyId and RaceLobbies[lobbyId]
    if not lobby or lobby.status ~= 'waiting' then return end

    if not ValidateDistance(src, OrganizerCoords(), Config.InteractionDistances.organizer, 'toggleReady') then return end

    local player = FindLobbyPlayer(lobby, sessionId)
    if not player then return end

    player.ready = not player.ready
    BroadcastLobby(lobby)
end)

-- Starts a race only after the host and all racers pass readiness, distance, and vehicle checks.
RegisterNetEvent('streetracing:server:startRace', function()
    local src = NormalizeSource(source)
    if not src then return end

    local identifier = GetStableIdentifier(src)
    local sessionId = GetLobbyKey(src)
    if not identifier or not sessionId then return end

    local lobbyId = PlayerLobby[sessionId]
    local lobby = lobbyId and RaceLobbies[lobbyId]
    if not lobby then
        Notify(src, { title = 'Error', description = 'You are not in a lobby', type = 'error' })
        return
    end

    if (lobby.hostSessionId and lobby.hostSessionId ~= sessionId) or (not lobby.hostSessionId and lobby.hostIdentifier ~= identifier) then
        Notify(src, { title = 'Error', description = 'Only the host can start the race', type = 'error' })
        return
    end

    if lobby.status ~= 'waiting' then return end

    if #lobby.players < Config.MinPlayers then
        Notify(src, { title = 'Error', description = ('Need at least %d players to start'):format(Config.MinPlayers), type = 'error' })
        return
    end

    for _, player in ipairs(lobby.players) do
        if not player.isHost and not player.ready then
            Notify(src, { title = 'Not Ready', description = 'All non-host racers must ready up first', type = 'error' })
            return
        end

        if not ValidateDistance(player.src, OrganizerCoords(), Config.InteractionDistances.organizer, 'startRace') then
            Notify(src, { title = 'Too Far Away', description = 'Every racer must be near the organizer before starting', type = 'error' })
            return
        end

        local vehicleOk, vehicleMessage = ValidateRaceVehicle(player.src)
        if not vehicleOk then
            Notify(src, { title = 'Vehicle Check Failed', description = ('%s: %s'):format(player.name, vehicleMessage), type = 'error' })
            return
        end
    end

    lobby.status = 'starting'
    BroadcastLobby(lobby)
    BroadcastAvailableLobbies(-1)

    for _, player in ipairs(lobby.players) do
        TriggerClientEvent('streetracing:client:raceStarting', player.src, {
            lobby = lobby,
            countdown = Config.CountdownTime
        })
    end

    SetTimeout(Config.CountdownTime * 1000, function()
        local current = RaceLobbies[lobbyId]
        if not current or current.status ~= 'starting' then return end

        current.status = 'racing'
        current.startedAt = GetGameTimer()
        current.finishOrder = {}
        current.finished = {}
        current.policeNearby = false
        current.lastPoliceWarning = 0
        ActiveRaces[lobbyId] = current

        for _, player in ipairs(current.players) do
            TriggerClientEvent('streetracing:client:raceStart', player.src, {
                lobby = current,
                checkpoints = current.route.checkpoints
            })
        end

        StartPoliceWarningMonitor(lobbyId)

        SetTimeout(Config.RaceTimeoutMinutes * 60 * 1000, function()
            if ActiveRaces[lobbyId] and not ActiveRaces[lobbyId].settled then
                FinalizeRace(lobbyId, 'timeout')
            end
        end)
    end)
end)

-- Accepts a finish only once per racer and validates time, vehicle, and finish-line distance.
RegisterNetEvent('streetracing:server:playerFinished', function(checkpointTime)
    local src = NormalizeSource(source)
    if not src then return end

    local identifier = GetStableIdentifier(src)
    local sessionId = GetLobbyKey(src)
    if not identifier or not sessionId then return end

    local lobbyId = PlayerLobby[sessionId]
    local lobby = lobbyId and ActiveRaces[lobbyId]
    if not lobby or lobby.settled then return end

    if lobby.finished[sessionId] then
        LogError(('Duplicate finish rejected for source %s race %s'):format(src, lobbyId))
        return
    end

    local finishTime = math.floor(tonumber(checkpointTime) or 0)
    local maxTime = Config.RaceTimeoutMinutes * 60 * 1000 + 30000
    if finishTime <= 0 or finishTime > maxTime then
        LogError(('Invalid finish time rejected for source %s race %s'):format(src, lobbyId))
        return
    end

    local checkpoints = lobby.route and lobby.route.checkpoints
    local finishCoords = checkpoints and checkpoints[#checkpoints]
    if not ValidateDistance(src, finishCoords, Config.InteractionDistances.finishLine, 'playerFinished') then
        Notify(src, { title = 'Finish Rejected', description = 'Finish line validation failed', type = 'error' })
        return
    end

    local vehicleOk, vehicleMessage = ValidateRaceVehicle(src)
    if not vehicleOk then
        Notify(src, { title = 'Finish Rejected', description = vehicleMessage, type = 'error' })
        return
    end

    lobby.finished[sessionId] = true
    table.insert(lobby.finishOrder, {
        src = src,
        sessionId = sessionId,
        identifier = identifier,
        name = GetPlayerName(src) or ('Racer %d'):format(src),
        time = finishTime
    })

    local position = #lobby.finishOrder
    for _, player in ipairs(lobby.players) do
        TriggerClientEvent('streetracing:client:playerFinished', player.src, {
            name = GetPlayerName(src) or ('Racer %d'):format(src),
            position = position
        })
    end

    CheckRaceComplete(lobbyId)
end)

RegisterNetEvent('streetracing:server:cancelRace', function()
    local src = NormalizeSource(source)
    if not src then return end

    local identifier = GetStableIdentifier(src)
    local sessionId = GetLobbyKey(src)
    if not identifier or not sessionId then return end

    local lobbyId = PlayerLobby[sessionId]
    local lobby = lobbyId and (RaceLobbies[lobbyId] or ActiveRaces[lobbyId])
    if not lobby then return end

    local isHost = lobby.hostSessionId == sessionId or (not lobby.hostSessionId and lobby.hostIdentifier == identifier)
    if not isHost and lobby.status ~= 'racing' then
        LogError(('Unauthorized cancelRace rejected for source %s race %s'):format(src, lobbyId))
        return
    end

    CancelLobby(lobbyId, 'The race has been cancelled', lobby.status ~= 'racing')
end)

RegisterNetEvent('streetracing:server:policeScatter', function(lobbyId)
    local src = NormalizeSource(source)
    if not src or type(lobbyId) ~= 'string' then return end

    local lobby = ActiveRaces[lobbyId] or RaceLobbies[lobbyId]
    if not lobby then return end

    local startCoords = lobby.route and lobby.route.checkpoints and lobby.route.checkpoints[1]
    if not ValidateDistance(src, startCoords, Config.PoliceWarningRadius, 'policeScatter') then return end

    for _, player in ipairs(lobby.players) do
        TriggerClientEvent('streetracing:client:policeWarning', player.src, { scatter = true })
        PlayerLobby[player.sessionId or player.identifier] = nil
    end

    RaceLobbies[lobbyId] = nil
    ActiveRaces[lobbyId] = nil
end)

RegisterNetEvent('streetracing:server:getLobbies', function()
    local src = NormalizeSource(source)
    if not src then return end

    BroadcastAvailableLobbies(src)
end)

RegisterNetEvent('streetracing:server:getPlayerData', function()
    local src = NormalizeSource(source)
    if not src then return end

    local sessionId = GetLobbyKey(src)
    TriggerClientEvent('streetracing:client:receivePlayerData', src, {
        rep = InitPlayerRep(src),
        currentLobby = sessionId and PlayerLobby[sessionId] or nil,
        serverId = src
    })
end)

RegisterNetEvent('streetracing:server:getLeaderboard', function()
    local src = NormalizeSource(source)
    if not src then return end

    local leaderboard = exports[RESOURCE_NAME]:GetRepLeaderboard()
    for _, entry in ipairs(leaderboard) do
        entry.name = ('Racer_%s'):format(string.sub(entry.identifier or 'unknown', -6))
    end

    TriggerClientEvent('streetracing:client:receiveLeaderboard', src, leaderboard)
end)

AddEventHandler('playerDropped', function()
    local src = tonumber(source)
    if not src or src <= 0 then return end

    local identifier = GetStableIdentifier(src)
    local sessionId = ('src:%d'):format(src)
    local lobbyId = PlayerLobby[sessionId]
    if not lobbyId then return end

    local lobby = RaceLobbies[lobbyId] or ActiveRaces[lobbyId]
    if not lobby then
        PlayerLobby[sessionId] = nil
        return
    end

    local player, index = FindLobbyPlayer(lobby, sessionId)
    if player and index then
        if lobby.status == 'waiting' or lobby.status == 'starting' then
            RefundEntry(player, lobby.betAmount)
            lobby.prizePool = math.max(0, lobby.prizePool - lobby.betAmount)
        end
        table.remove(lobby.players, index)
    end

    PlayerLobby[sessionId] = nil

    if (lobby.hostSessionId == sessionId or (not lobby.hostSessionId and lobby.hostIdentifier == identifier)) and #lobby.players > 0 then
        lobby.host = lobby.players[1].src
        lobby.hostIdentifier = lobby.players[1].identifier
        lobby.hostSessionId = lobby.players[1].sessionId
        lobby.players[1].isHost = true
    end

    if #lobby.players == 0 then
        RaceLobbies[lobbyId] = nil
        ActiveRaces[lobbyId] = nil
    else
        BroadcastLobby(lobby)
        CheckRaceComplete(lobbyId)
    end
end)
