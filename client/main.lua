CurrentLobby = nil
local PlayerRep = 0
local AvailableLobbies = {}
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
    NUI.SendMessage('lobbyUpdate', lobby)

    if lobby.status == 'starting' then
        CloseRaceMenus()
    end
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
    NUI.SendMessage('receiveLeaderboard', leaderboard)
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
end)
