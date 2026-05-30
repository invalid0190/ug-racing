CurrentLobby = nil
local PlayerRep = 0
local AvailableLobbies = {}
local RaceOrganizerPed = nil
local LOG_PREFIX = '[racing-system]'

local function LogError(message)
    print(('%s ERROR: %s'):format(LOG_PREFIX, message))
end

local function Notify(data)
    lib.notify(data)
end

-- Fetches the latest lobby list synchronously for ox_lib menus, falling back to the event flow.
local function FetchAvailableLobbies()
    local callbackApi = lib and type(lib.callback) == 'table' and lib.callback or nil
    if callbackApi and type(callbackApi.await) == 'function' then
        local ok, lobbies = pcall(function()
            return callbackApi.await('streetracing:server:getAvailableLobbies', false)
        end)

        if ok and type(lobbies) == 'table' then
            AvailableLobbies = lobbies
            return AvailableLobbies
        end

        LogError(('Lobby callback failed, using event fallback: %s'):format(tostring(lobbies)))
    end

    TriggerServerEvent('streetracing:server:getLobbies')
    Wait(200)
    return AvailableLobbies
end

-- Closes ox_lib context menus and any focused React NUI surface.
function CloseRaceMenus()
    if lib.hideContext then
        lib.hideContext(false)
    end

    if NUI and NUI.IsOpen and NUI.IsOpen() then
        NUI.Close()
    end
end

-- Opens the React racing tablet with the freshest client-side snapshot available.
function OpenRacingTablet()
    TriggerServerEvent('streetracing:server:getPlayerData')
    TriggerServerEvent('streetracing:server:getLobbies')
    TriggerServerEvent('streetracing:server:getLeaderboard')
    TriggerServerEvent('streetracing:server:getPlayerStats')
    TriggerServerEvent('streetracing:server:getNetwork')
    TriggerServerEvent('streetracing:server:getRouteRecords')

    if lib.hideContext then
        lib.hideContext(false)
    end

    NUI.Open({
        rep = PlayerRep,
        lobby = CurrentLobby,
        lobbies = AvailableLobbies,
        routes = NUI.GetRouteSummaries and NUI.GetRouteSummaries() or {},
        settings = NUI.GetTabletSettings and NUI.GetTabletSettings() or {},
        serverId = GetPlayerServerId(PlayerId())
    })
end

RegisterCommand('racingtablet', function()
    if NUI and NUI.IsOpen and NUI.IsOpen() then
        NUI.Close()
        return
    end

    OpenRacingTablet()
end, false)

RegisterKeyMapping('racingtablet', 'Open Racing Tablet', 'keyboard', 'F6')

CreateThread(function()
    while GetResourceState('ox_lib') ~= 'started' do Wait(100) end
    while GetResourceState('ox_target') ~= 'started' do Wait(100) end

    CreateRaceOrganizer()
    TriggerServerEvent('streetracing:server:getPlayerData')
end)

CreateThread(function()
    while true do
        if IsControlJustReleased(0, 322) or IsControlJustReleased(0, 200) then
            CloseRaceMenus()
        end

        Wait(0)
    end
end)

-- Spawns the organizer NPC and registers the current ox_target local entity option.
function CreateRaceOrganizer()
    local model = GetHashKey(Config.NPC.model)

    RequestModel(model)
    local expiresAt = GetGameTimer() + 5000
    while not HasModelLoaded(model) do
        if GetGameTimer() > expiresAt then
            Notify({ title = 'Racing', description = 'Race organizer model failed to load', type = 'error' })
            return
        end
        Wait(100)
    end

    local npc = CreatePed(4, model,
        Config.NPC.coords.x,
        Config.NPC.coords.y,
        Config.NPC.coords.z - 1.0,
        Config.NPC.coords.w,
        false,
        true
    )

    SetModelAsNoLongerNeeded(model)
    if not npc or npc == 0 then
        Notify({ title = 'Racing', description = 'Race organizer could not be created', type = 'error' })
        return
    end

    RaceOrganizerPed = npc
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)

    if Config.NPC.scenario then
        TaskStartScenarioInPlace(npc, Config.NPC.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(npc, {
        {
            name = 'streetracing_talk',
            icon = 'fa-solid fa-flag-checkered',
            label = 'Talk to Race Organizer',
            distance = 2.0,
            onSelect = function()
                OpenRaceMenu()
            end
        }
    })
end

-- Opens the organizer's root context menu with fresh server state.
function OpenRaceMenu()
    TriggerServerEvent('streetracing:server:getPlayerData')
    FetchAvailableLobbies()

    local options = {
        {
            title = 'Create Race',
            description = 'Start a new underground race',
            icon = 'plus',
            onSelect = function()
                OpenCreateRaceMenu()
            end
        },
        {
            title = 'Join Race',
            description = ('%d races available'):format(#AvailableLobbies),
            icon = 'users',
            onSelect = function()
                OpenJoinRaceMenu()
            end
        },
        {
            title = 'Reputation Leaderboard',
            description = ('Your Rep: %d points'):format(PlayerRep),
            icon = 'trophy',
            onSelect = function()
                TriggerServerEvent('streetracing:server:getLeaderboard')
                OpenLeaderboardMenu()
            end
        }
    }

    if CurrentLobby then
        table.insert(options, 1, {
            title = 'Current Lobby',
            description = 'Return to your active lobby',
            icon = 'door-open',
            onSelect = function()
                OpenLobbyMenu()
            end
        })
    end

    lib.registerContext({
        id = 'streetracing_main',
        title = 'Underground Racing',
        canClose = true,
        onExit = CloseRaceMenus,
        options = options
    })

    lib.showContext('streetracing_main')
end

-- Displays all configured routes, honoring reputation gates locally before server validation.
function OpenCreateRaceMenu()
    local routeOptions = {}

    for _, route in ipairs(Config.Routes) do
        local canAccess = PlayerRep >= route.minRep
        local repLabel = route.minRep > 0 and (' (Rep: %d)'):format(route.minRep) or ''

        table.insert(routeOptions, {
            title = route.name,
            description = ('%s%s - Entry: $%d'):format(route.description, repLabel, route.entryFee),
            icon = canAccess and 'road' or 'lock',
            disabled = not canAccess,
            onSelect = function()
                OpenBetMenu(route)
            end
        })
    end

    lib.registerContext({
        id = 'streetracing_create',
        title = 'Select Race Route',
        menu = 'streetracing_main',
        canClose = true,
        onExit = CloseRaceMenus,
        options = routeOptions
    })

    lib.showContext('streetracing_create')
end

-- Allows fixed bet multipliers while the server clamps and charges the final amount.
function OpenBetMenu(route)
    local multipliers = { 1, 2, Config.MaxBetMultiplier }
    local betOptions = {}

    for _, multiplier in ipairs(multipliers) do
        local label = multiplier == 1 and 'Minimum Entry' or (('%dx Entry'):format(multiplier))
        table.insert(betOptions, {
            title = label,
            description = ('$%d'):format(route.entryFee * multiplier),
            icon = multiplier == Config.MaxBetMultiplier and 'fire' or 'dollar-sign',
            onSelect = function()
                TriggerServerEvent('streetracing:server:createLobby', route.id, route.entryFee * multiplier)
            end
        })
    end

    lib.registerContext({
        id = 'streetracing_bet',
        title = 'Set Entry Fee - ' .. route.name,
        menu = 'streetracing_create',
        canClose = true,
        onExit = CloseRaceMenus,
        options = betOptions
    })

    lib.showContext('streetracing_bet')
end

-- Shows joinable lobbies received from the server.
function OpenJoinRaceMenu()
    FetchAvailableLobbies()

    local joinOptions = {}

    for _, lobby in ipairs(AvailableLobbies) do
        local canJoin = PlayerRep >= (lobby.minRep or 0)
        local spotsLeft = (lobby.maxPlayers or Config.MaxPlayers) - (lobby.playerCount or 0)

        table.insert(joinOptions, {
            title = lobby.routeName or 'Unknown Route',
            description = ('Host: %s | Players: %d/%d | Pool: $%d'):format(
                lobby.hostName or 'Unknown',
                lobby.playerCount or 0,
                lobby.maxPlayers or Config.MaxPlayers,
                lobby.prizePool or 0
            ),
            icon = canJoin and 'flag' or 'lock',
            disabled = not canJoin or spotsLeft <= 0,
            onSelect = function()
                TriggerServerEvent('streetracing:server:joinLobby', lobby.id)
            end
        })
    end

    if #joinOptions == 0 then
        table.insert(joinOptions, {
            title = 'No Races Available',
            description = 'Create your own race to get started',
            icon = 'circle-info',
            disabled = true
        })
    end

    lib.registerContext({
        id = 'streetracing_join',
        title = 'Available Races',
        menu = 'streetracing_main',
        canClose = true,
        onExit = CloseRaceMenus,
        options = joinOptions
    })

    lib.showContext('streetracing_join')
end

-- Shows current lobby state and host controls.
function OpenLobbyMenu()
    if not CurrentLobby then return end

    local lobby = CurrentLobby
    local playerOptions = {}

    for _, player in ipairs(lobby.players or {}) do
        local readyText = player.ready and ' (Ready)' or ''
        local hostText = player.isHost and ' [Host]' or ''

        table.insert(playerOptions, {
            title = (player.name or 'Unknown') .. hostText .. readyText,
            icon = player.ready and 'check-circle' or 'circle',
            disabled = true
        })
    end

    local isHost = false
    local myServerId = GetPlayerServerId(PlayerId())
    for _, player in ipairs(lobby.players or {}) do
        if player.src == myServerId then
            isHost = player.isHost == true
            break
        end
    end

    local allReady = true
    for _, player in ipairs(lobby.players or {}) do
        if not player.ready and not player.isHost then
            allReady = false
            break
        end
    end

    table.insert(playerOptions, {
        title = 'Toggle Ready',
        description = 'Mark yourself as ready',
        icon = 'check',
        onSelect = function()
            TriggerServerEvent('streetracing:server:toggleReady')
            Wait(100)
            OpenLobbyMenu()
        end
    })

    if isHost then
        table.insert(playerOptions, {
            title = 'Start Race',
            description = allReady and 'Begin the countdown' or 'Waiting for racers to ready up',
            icon = 'play',
            disabled = #(lobby.players or {}) < Config.MinPlayers or not allReady,
            onSelect = function()
                TriggerServerEvent('streetracing:server:startRace')
            end
        })
    end

    table.insert(playerOptions, {
        title = 'Leave Lobby',
        description = 'Exit the current lobby',
        icon = 'door-open',
        onSelect = function()
            TriggerServerEvent('streetracing:server:leaveLobby')
        end
    })

    lib.registerContext({
        id = 'streetracing_lobby',
        title = ('%s - Prize Pool: $%d'):format(lobby.route and lobby.route.name or 'Race Lobby', lobby.prizePool or 0),
        canClose = true,
        onExit = CloseRaceMenus,
        options = playerOptions
    })

    lib.showContext('streetracing_lobby')
end

function OpenLeaderboardMenu()
    lib.registerContext({
        id = 'streetracing_leaderboard',
        title = 'Reputation Leaderboard',
        menu = 'streetracing_main',
        canClose = true,
        onExit = CloseRaceMenus,
        options = {}
    })
end

RegisterNetEvent('streetracing:client:receivePlayerData', function(data)
    data = data or {}
    PlayerRep = data.rep or 0
    if data.currentLobby then
        TriggerServerEvent('streetracing:server:getLobbies')
    end

    NUI.SendMessage('receivePlayerData', data)
end)

RegisterNetEvent('streetracing:client:receiveLobbies', function(lobbies)
    AvailableLobbies = lobbies or {}
    NUI.SendMessage('receiveLobbies', AvailableLobbies)
end)

RegisterNetEvent('streetracing:client:lobbyUpdate', function(lobby)
    if not lobby then return end
    CurrentLobby = lobby
    NUI.SendFocusedMessage('lobbyUpdate', lobby)
end)

RegisterNetEvent('streetracing:client:leftLobby', function()
    CurrentLobby = nil
    if Config.RacerRadio and Config.RacerRadio.leaveOnLobbyExit ~= false and RacingRadio and RacingRadio.Leave then
        RacingRadio.Leave(true)
    end
    NUI.SendMessage('leftLobby')
    NUI.Close()
end)

RegisterNetEvent('streetracing:client:receiveLeaderboard', function(leaderboard)
    leaderboard = leaderboard or {}
    local lbOptions = {}

    for i, entry in ipairs(leaderboard) do
        if i > 10 then break end

        local rankIcon = 'medal'
        if i == 1 then rankIcon = 'crown'
        elseif i == 3 then rankIcon = 'award'
        end

        table.insert(lbOptions, {
            title = ('#%d %s'):format(i, entry.name or 'Unknown'),
            description = ('%d Rep Points'):format(entry.rep or 0),
            icon = rankIcon,
            disabled = true
        })
    end

    if #lbOptions == 0 then
        table.insert(lbOptions, {
            title = 'No Racers Yet',
            description = 'Finish races to build the leaderboard',
            icon = 'circle-info',
            disabled = true
        })
    end

    lib.registerContext({
        id = 'streetracing_leaderboard',
        title = 'Top Racers',
        menu = 'streetracing_main',
        canClose = true,
        onExit = CloseRaceMenus,
        options = lbOptions
    })

    lib.showContext('streetracing_leaderboard')
    NUI.SendFocusedMessage('receiveLeaderboard', leaderboard)
end)

RegisterNetEvent('streetracing:client:receivePlayerStats', function(stats)
    NUI.SendMessage('receivePlayerStats', stats or {})
end)

RegisterNetEvent('streetracing:client:receiveNetwork', function(network)
    NUI.SendMessage('receiveNetwork', network or {})
end)

RegisterNetEvent('streetracing:client:receiveRouteRecords', function(records)
    NUI.SendMessage('receiveRouteRecords', records or {})
end)

function GetMyServerId()
    return GetPlayerServerId(PlayerId())
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CloseRaceMenus()
    if RaceOrganizerPed and DoesEntityExist(RaceOrganizerPed) then
        exports.ox_target:removeLocalEntity(RaceOrganizerPed, 'streetracing_talk')
        DeleteEntity(RaceOrganizerPed)
    end
end)
