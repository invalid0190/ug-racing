local RESOURCE_NAME = GetCurrentResourceName()
local LOG_PREFIX = '[racing-system]'

local RaceLobbies = {}
local ActiveRaces = {}
local PlayerLobby = {}
local PlayerReputation = {}
local PlayerStats = {}
local RouteRecords = {}
local PlayerCooldowns = {}
local RaceRadioMembers = {}
local UsedRaceRadioChannels = {}
local ReputationLoaded = false
local StatsLoaded = false

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

local function LoadStats()
    if StatsLoaded then return end
    StatsLoaded = true

    local raw = LoadResourceFile(RESOURCE_NAME, Config.StatsFile or 'racing_stats.json')
    if not raw or raw == '' then
        PlayerStats = {}
        RouteRecords = {}
        return
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        LogError(('Failed to decode %s; starting with empty stats table'):format(Config.StatsFile or 'racing_stats.json'))
        PlayerStats = {}
        RouteRecords = {}
        return
    end

    PlayerStats = type(decoded.players) == 'table' and decoded.players or {}
    RouteRecords = type(decoded.routeRecords) == 'table' and decoded.routeRecords or {}
end

local function SaveStats()
    local payload = {
        players = PlayerStats,
        routeRecords = RouteRecords
    }

    local ok, encoded = pcall(json.encode, payload)
    if not ok then
        LogError('Failed to encode race stats data')
        return false
    end

    local saved = SaveResourceFile(RESOURCE_NAME, Config.StatsFile or 'racing_stats.json', encoded, -1)
    if not saved then
        LogError(('Failed to save %s'):format(Config.StatsFile or 'racing_stats.json'))
    end

    return saved == true
end

local function DefaultPlayerStats()
    return {
        totalRaces = 0,
        wins = 0,
        topThree = 0,
        finishPositionSum = 0,
        bestTime = nil,
        bestTimeRoute = nil,
        totalPrizeMoney = 0,
        currentStreak = 0,
        bestStreak = 0,
        repHistory = {},
        history = {},
        personalRecords = {}
    }
end

local function GetStatsRecord(identifier)
    if not identifier then return DefaultPlayerStats() end

    local stats = type(PlayerStats[identifier]) == 'table' and PlayerStats[identifier] or DefaultPlayerStats()
    stats.totalRaces = tonumber(stats.totalRaces) or 0
    stats.wins = tonumber(stats.wins) or 0
    stats.topThree = tonumber(stats.topThree) or 0
    stats.finishPositionSum = tonumber(stats.finishPositionSum) or 0
    stats.totalPrizeMoney = tonumber(stats.totalPrizeMoney) or 0
    stats.currentStreak = tonumber(stats.currentStreak) or 0
    stats.bestStreak = tonumber(stats.bestStreak) or 0
    stats.repHistory = type(stats.repHistory) == 'table' and stats.repHistory or {}
    stats.history = type(stats.history) == 'table' and stats.history or {}
    stats.personalRecords = type(stats.personalRecords) == 'table' and stats.personalRecords or {}
    PlayerStats[identifier] = stats
    return stats
end

local function GetPlayerRank(identifier)
    if not identifier then return nil end

    local ranked = {}
    for id, rep in pairs(PlayerReputation) do
        ranked[#ranked + 1] = { identifier = id, rep = tonumber(rep) or 0 }
    end

    table.sort(ranked, function(a, b) return a.rep > b.rep end)

    for index, entry in ipairs(ranked) do
        if entry.identifier == identifier then
            return index
        end
    end

    return nil
end

local function BuildPlayerStats(src)
    local identifier = GetStableIdentifier(src)
    local stats = GetStatsRecord(identifier)
    local totalRaces = tonumber(stats.totalRaces) or 0
    local personalRecords = {}

    for _, record in pairs(stats.personalRecords or {}) do
        personalRecords[#personalRecords + 1] = record
    end

    table.sort(personalRecords, function(a, b)
        return (tonumber(a.time) or 999999999) < (tonumber(b.time) or 999999999)
    end)

    return {
        totalRaces = totalRaces,
        wins = tonumber(stats.wins) or 0,
        topThree = tonumber(stats.topThree) or 0,
        winRate = totalRaces > 0 and ((tonumber(stats.wins) or 0) / totalRaces) * 100 or 0,
        avgFinishPosition = totalRaces > 0 and ((tonumber(stats.finishPositionSum) or 0) / totalRaces) or 0,
        bestTime = tonumber(stats.bestTime),
        bestTimeRoute = stats.bestTimeRoute,
        totalPrizeMoney = tonumber(stats.totalPrizeMoney) or 0,
        currentStreak = tonumber(stats.currentStreak) or 0,
        bestStreak = tonumber(stats.bestStreak) or 0,
        repHistory = stats.repHistory or {},
        history = stats.history or {},
        personalRecords = personalRecords,
        rank = GetPlayerRank(identifier)
    }
end

local function BuildHistoryId(lobbyId, result, finishedAt)
    return ('%s:%s:%d:%d'):format(
        tostring(lobbyId or 'race'),
        tostring(result.sessionId or result.identifier or 'racer'),
        tonumber(finishedAt) or os.time(),
        tonumber(result.position) or 0
    )
end

local function TrimList(list, limit)
    limit = math.max(1, tonumber(limit) or 25)
    while #list > limit do
        table.remove(list)
    end
end

local function UpdateRaceStats(result, position, lobby, totalRep, reason)
    if not result or not result.identifier then return end

    local stats = GetStatsRecord(result.identifier)
    local route = lobby and lobby.route or {}
    local isWinner = position == 1 and not result.dnf
    local isPodium = position <= 3 and not result.dnf
    local prizeWon = tonumber(result.prizeWon) or 0

    stats.name = result.name
    stats.totalRaces = (tonumber(stats.totalRaces) or 0) + 1
    stats.finishPositionSum = (tonumber(stats.finishPositionSum) or 0) + position

    if isWinner then
        stats.wins = (tonumber(stats.wins) or 0) + 1
        stats.currentStreak = (tonumber(stats.currentStreak) or 0) + 1
    else
        stats.currentStreak = 0
    end

    if isPodium then
        stats.topThree = (tonumber(stats.topThree) or 0) + 1
    end

    stats.bestStreak = math.max(tonumber(stats.bestStreak) or 0, tonumber(stats.currentStreak) or 0)
    stats.totalPrizeMoney = (tonumber(stats.totalPrizeMoney) or 0) + prizeWon

    local finishTime = tonumber(result.time)
    local personalBest = false
    local globalRecord = false

    if finishTime and finishTime > 0 and (not stats.bestTime or finishTime < tonumber(stats.bestTime)) then
        stats.bestTime = finishTime
        stats.bestTimeRoute = route.name
    end

    if route.id and finishTime and finishTime > 0 then
        local personalRecord = stats.personalRecords[route.id]
        if type(personalRecord) ~= 'table' or not personalRecord.time or finishTime < tonumber(personalRecord.time) then
            personalBest = true
            stats.personalRecords[route.id] = {
                routeId = route.id,
                routeName = route.name,
                time = finishTime,
                position = position,
                prizeWon = prizeWon,
                repGained = tonumber(result.repGained) or 0,
                finishedAt = os.time()
            }
        end
    end

    if route.id and finishTime and finishTime > 0 then
        local currentRecord = RouteRecords[route.id]
        if type(currentRecord) ~= 'table' or not currentRecord.time or finishTime < tonumber(currentRecord.time) then
            globalRecord = true
            RouteRecords[route.id] = {
                routeId = route.id,
                routeName = route.name,
                time = finishTime,
                name = result.name,
                identifier = result.identifier,
                finishedAt = os.time()
            }
        end
    end

    local finishedAt = os.time()
    table.insert(stats.history, 1, {
        id = BuildHistoryId(lobby and lobby.id, result, finishedAt),
        raceId = lobby and lobby.id,
        routeId = route.id,
        routeName = route.name or 'Unknown Route',
        position = position,
        totalPlayers = lobby and #(lobby.players or {}) or 0,
        time = finishTime,
        dnf = result.dnf == true,
        prizeWon = prizeWon,
        prizePool = lobby and lobby.prizePool or 0,
        repGained = tonumber(result.repGained) or 0,
        totalRep = tonumber(totalRep) or 0,
        betAmount = lobby and lobby.betAmount or 0,
        reason = reason or 'complete',
        finishedAt = finishedAt,
        personalBest = personalBest,
        globalRecord = globalRecord,
        winnerName = lobby and lobby.finishOrder and lobby.finishOrder[1] and lobby.finishOrder[1].name or nil
    })
    TrimList(stats.history, Config.RaceHistoryLimit or 25)

    stats.repHistory[#stats.repHistory + 1] = tonumber(totalRep) or 0
    while #stats.repHistory > 10 do
        table.remove(stats.repHistory, 1)
    end
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

local function CountTableEntries(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function GetRacerRadioConfig()
    return Config.RacerRadio or {}
end

local function IsRacerRadioEnabled()
    local radioConfig = GetRacerRadioConfig()
    return radioConfig.enabled ~= false
end

local function GetRacerRadioVoiceResource()
    local radioConfig = GetRacerRadioConfig()
    return radioConfig.voiceResource or 'pma-voice'
end

local function IsRacerRadioAvailable()
    return IsRacerRadioEnabled() and GetResourceState(GetRacerRadioVoiceResource()) == 'started'
end

local function AllocateRaceRadioChannel()
    local radioConfig = GetRacerRadioConfig()
    local base = math.floor(tonumber(radioConfig.channelBase) or 700)
    local range = math.max(1, math.floor(tonumber(radioConfig.channelRange) or 200))

    for _ = 1, range do
        local channel = base + math.random(0, range - 1)
        if not UsedRaceRadioChannels[channel] then
            UsedRaceRadioChannels[channel] = true
            return channel
        end
    end

    local fallback = base + range + math.random(1, 999)
    UsedRaceRadioChannels[fallback] = true
    return fallback
end

local function ReleaseRaceRadioChannel(channel)
    channel = math.floor(tonumber(channel) or 0)
    if channel > 0 then
        UsedRaceRadioChannels[channel] = nil
    end
end

local function GetPlayerRaceLobby(src)
    local sessionId = GetLobbyKey(src)
    local lobbyId = sessionId and PlayerLobby[sessionId]
    if not lobbyId then return nil, nil end

    return RaceLobbies[lobbyId] or ActiveRaces[lobbyId], lobbyId
end

local function CountRaceRadioMembers(lobby)
    if not lobby or not lobby.radioChannel then return 0 end

    local count = 0
    for _, player in ipairs(lobby.players or {}) do
        if RaceRadioMembers[player.src] == lobby.radioChannel then
            count = count + 1
        end
    end

    return count
end

local function BuildRaceRadioData(src)
    local lobby = GetPlayerRaceLobby(src)
    local radioConfig = GetRacerRadioConfig()
    local channel = lobby and math.floor(tonumber(lobby.radioChannel) or 0) or 0

    return {
        enabled = IsRacerRadioEnabled(),
        available = IsRacerRadioAvailable(),
        voiceResource = GetRacerRadioVoiceResource(),
        channel = channel,
        joined = channel > 0 and RaceRadioMembers[src] == channel or false,
        crewCount = CountRaceRadioMembers(lobby),
        inLobby = lobby ~= nil,
        status = lobby and lobby.status or 'idle',
        autoJoinOnRaceStart = radioConfig.autoJoinOnRaceStart ~= false
    }
end

local function CountNearbyPoliceAcrossRaces()
    local total = 0
    for _, lobby in pairs(ActiveRaces) do
        total = total + CountNearbyPolice(lobby)
    end
    return total
end

local function GetPlayerRaceStatus(sessionId)
    local lobbyId = sessionId and PlayerLobby[sessionId]
    if not lobbyId then return 'idle' end
    if ActiveRaces[lobbyId] then return 'racing' end
    if RaceLobbies[lobbyId] then return 'lobby' end
    return 'idle'
end

local function BuildNetworkData(viewerSrc)
    local racers = {}

    for _, playerId in ipairs(GetPlayers()) do
        local src = NormalizeSource(playerId)
        if src then
            local identifier = GetStableIdentifier(src)
            local sessionId = GetLobbyKey(src)
            racers[#racers + 1] = {
                id = tostring(src),
                name = GetPlayerName(src) or ('Racer %d'):format(src),
                status = GetPlayerRaceStatus(sessionId),
                rep = identifier and (tonumber(PlayerReputation[identifier]) or 0) or 0,
                inVoice = RaceRadioMembers[src] ~= nil
            }
        end
    end

    table.sort(racers, function(a, b)
        if a.status ~= b.status then return a.status < b.status end
        return a.rep > b.rep
    end)

    return {
        onlineCount = #racers,
        lobbyCount = #BuildAvailableLobbies(),
        activeRaceCount = CountTableEntries(ActiveRaces),
        nearbyPoliceCount = CountNearbyPoliceAcrossRaces(),
        racers = racers,
        radio = BuildRaceRadioData(viewerSrc)
    }
end

local function SendRaceRadioData(src)
    TriggerClientEvent('streetracing:client:receiveNetwork', src, BuildNetworkData(src))
    TriggerClientEvent('streetracing:client:receiveRaceRadio', src, BuildRaceRadioData(src))
end

local function BroadcastRaceRadioData(lobby)
    if not lobby or type(lobby.players) ~= 'table' then return end

    for _, player in ipairs(lobby.players) do
        if player and player.src then
            SendRaceRadioData(player.src)
        end
    end
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
            RaceRadioMembers[player.src] = nil
            TriggerClientEvent('streetracing:client:leaveRaceRadio', player.src, { restorePrevious = true })
            PlayerLobby[player.sessionId or player.identifier] = nil
        end

        ReleaseRaceRadioChannel(lobby.radioChannel)
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
        if index == 1 and not result.dnf then
            result.prizeWon = lobby.prizePool
        end
        result.totalRep = AddPlayerRep(result.identifier, repGain)
        UpdateRaceStats(result, index, lobby, result.totalRep, reason or 'complete')
    end

    SaveStats()

    if results[1] and not results[1].dnf and not lobby.prizePaid then
        lobby.prizePaid = true
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
        RaceRadioMembers[player.src] = nil
        TriggerClientEvent('streetracing:client:leaveRaceRadio', player.src, { restorePrevious = true })
        TriggerClientEvent('streetracing:client:raceCancelled', player.src, description or 'Race cancelled')
        PlayerLobby[player.sessionId or player.identifier] = nil
    end

    ReleaseRaceRadioChannel(lobby.radioChannel)
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
        LoadStats()
    end
end)

CreateThread(function()
    LoadReputation()
    LoadStats()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == RESOURCE_NAME then
        SaveReputation()
        SaveStats()
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

exports('GetPlayerStats', function(src)
    return BuildPlayerStats(src)
end)

exports('GetRouteRecords', function()
    return RouteRecords
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
        radioChannel = AllocateRaceRadioChannel(),
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

    RaceRadioMembers[src] = nil
    TriggerClientEvent('streetracing:client:leaveRaceRadio', src, { restorePrevious = true })
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
        ReleaseRaceRadioChannel(lobby.radioChannel)
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
            countdown = Config.CountdownTime,
            radioChannel = lobby.radioChannel,
            radioAutoJoin = GetRacerRadioConfig().autoJoinOnRaceStart ~= false
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
                checkpoints = current.route.checkpoints,
                radioChannel = current.radioChannel,
                radioAutoJoin = GetRacerRadioConfig().autoJoinOnRaceStart ~= false
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
        RaceRadioMembers[player.src] = nil
        TriggerClientEvent('streetracing:client:leaveRaceRadio', player.src, { restorePrevious = true })
        PlayerLobby[player.sessionId or player.identifier] = nil
    end

    ReleaseRaceRadioChannel(lobby.radioChannel)
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
    for index, entry in ipairs(leaderboard) do
        local stats = GetStatsRecord(entry.identifier)
        entry.rank = index
        entry.name = stats.name or ('Racer_%s'):format(string.sub(entry.identifier or 'unknown', -6))
        entry.wins = tonumber(stats.wins) or 0
        entry.races = tonumber(stats.totalRaces) or 0
        entry.streak = tonumber(stats.currentStreak) or 0
    end

    TriggerClientEvent('streetracing:client:receiveLeaderboard', src, leaderboard)
end)

RegisterNetEvent('streetracing:server:getPlayerStats', function()
    local src = NormalizeSource(source)
    if not src then return end

    TriggerClientEvent('streetracing:client:receivePlayerStats', src, BuildPlayerStats(src))
end)

RegisterNetEvent('streetracing:server:getNetwork', function()
    local src = NormalizeSource(source)
    if not src then return end

    TriggerClientEvent('streetracing:client:receiveNetwork', src, BuildNetworkData(src))
end)

RegisterNetEvent('streetracing:server:getRaceRadio', function()
    local src = NormalizeSource(source)
    if not src then return end

    TriggerClientEvent('streetracing:client:receiveRaceRadio', src, BuildRaceRadioData(src))
end)

RegisterNetEvent('streetracing:server:joinRaceRadio', function()
    local src = NormalizeSource(source)
    if not src then return end

    local lobby = GetPlayerRaceLobby(src)
    if not lobby or not lobby.radioChannel then
        Notify(src, { title = 'Race Radio', description = 'Join or create a race lobby first', type = 'error' })
        return
    end

    if not IsRacerRadioAvailable() then
        Notify(src, { title = 'Race Radio', description = ('%s is not started'):format(GetRacerRadioVoiceResource()), type = 'error' })
        return
    end

    TriggerClientEvent('streetracing:client:joinRaceRadio', src, {
        channel = lobby.radioChannel,
        automatic = false
    })
end)

RegisterNetEvent('streetracing:server:raceRadioState', function(joined, channel)
    local src = NormalizeSource(source)
    if not src then return end

    channel = math.floor(tonumber(channel) or 0)
    local lobby = GetPlayerRaceLobby(src)

    if joined == true and channel > 0 then
        if not lobby or math.floor(tonumber(lobby.radioChannel) or 0) ~= channel then
            LogError(('Rejected invalid race radio state from source %s channel %s'):format(src, channel))
            RaceRadioMembers[src] = nil
            SendRaceRadioData(src)
            return
        end

        RaceRadioMembers[src] = channel
    else
        RaceRadioMembers[src] = nil
    end

    if lobby then
        BroadcastRaceRadioData(lobby)
    else
        SendRaceRadioData(src)
    end
end)

RegisterNetEvent('streetracing:server:getRouteRecords', function()
    local src = NormalizeSource(source)
    if not src then return end

    TriggerClientEvent('streetracing:client:receiveRouteRecords', src, RouteRecords)
end)

RegisterNetEvent('streetracing:server:networkInvite', function(targetId)
    local src = NormalizeSource(source)
    if not src then return end

    local targetSrc = NormalizeSource(targetId)
    if targetSrc and targetSrc ~= src then
        Notify(targetSrc, {
            title = 'Race Invite',
            description = ('%s invited you to check the racing tablet'):format(GetPlayerName(src) or 'A racer'),
            type = 'inform'
        })
        Notify(src, { title = 'Invite Sent', description = 'Race invite sent', type = 'success' })
    else
        Notify(src, { title = 'Network', description = 'Select an online racer to invite', type = 'inform' })
    end
end)

RegisterNetEvent('streetracing:server:networkMessage', function(targetId)
    local src = NormalizeSource(source)
    if not src then return end

    local targetSrc = NormalizeSource(targetId)
    if targetSrc and targetSrc ~= src then
        Notify(targetSrc, {
            title = 'Racing Network',
            description = ('%s pinged you from the racing tablet'):format(GetPlayerName(src) or 'A racer'),
            type = 'inform'
        })
        Notify(src, { title = 'Message Sent', description = 'Network ping sent', type = 'success' })
    else
        Notify(src, { title = 'Network', description = 'Select an online racer to message', type = 'inform' })
    end
end)

RegisterNetEvent('streetracing:server:networkBroadcast', function()
    local src = NormalizeSource(source)
    if not src then return end

    local senderName = GetPlayerName(src) or 'A racer'
    local delivered = 0

    for _, playerId in ipairs(GetPlayers()) do
        local targetSrc = NormalizeSource(playerId)
        if targetSrc and targetSrc ~= src then
            delivered = delivered + 1
            Notify(targetSrc, {
                title = 'Racing Network',
                description = ('%s is looking for street racers'):format(senderName),
                type = 'inform'
            })
        end
    end

    Notify(src, {
        title = 'Racing Network',
        description = ('Broadcast sent to %d racer%s'):format(delivered, delivered == 1 and '' or 's'),
        type = delivered > 0 and 'success' or 'inform'
    })
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

    RaceRadioMembers[src] = nil
    PlayerLobby[sessionId] = nil

    if (lobby.hostSessionId == sessionId or (not lobby.hostSessionId and lobby.hostIdentifier == identifier)) and #lobby.players > 0 then
        lobby.host = lobby.players[1].src
        lobby.hostIdentifier = lobby.players[1].identifier
        lobby.hostSessionId = lobby.players[1].sessionId
        lobby.players[1].isHost = true
    end

    if #lobby.players == 0 then
        ReleaseRaceRadioChannel(lobby.radioChannel)
        RaceLobbies[lobbyId] = nil
        ActiveRaces[lobbyId] = nil
    else
        BroadcastLobby(lobby)
        CheckRaceComplete(lobbyId)
    end
end)
