NUI = {}
local isOpen = false

--- Send a message to the UI
---@param action string The action name the UI listens for
---@param data? table Optional data payload
function NUI.SendMessage(action, data)
    if type(action) ~= 'string' then return end
    SendNuiMessage(json.encode({ action = action, data = data or {} }))
end

--- Set UI visibility without changing focus
---@param visible boolean
function NUI.SetVisibility(visible)
    NUI.SendMessage('setVisible', { visible = visible })
end

--- Set NUI focus (keyboard/mouse capture)
---@param hasFocus boolean
---@param hasCursor boolean|nil Defaults to hasFocus if not provided
function NUI.SetFocus(hasFocus, hasCursor)
    SetNuiFocus(hasFocus, hasCursor ~= false and hasFocus)
end

--- Send an interactive UI message and make the mouse cursor available.
---@param action string
---@param data? table
function NUI.SendFocusedMessage(action, data)
    isOpen = true
    NUI.SetFocus(true, true)
    NUI.SendMessage(action, data)
end

--- Open the UI with optional data
---@param data? table Data to pass to UI on open
function NUI.Open(data)
    data = data or {}
    data.routes = data.routes or (NUI.GetRouteSummaries and NUI.GetRouteSummaries() or {})
    data.settings = data.settings or (NUI.GetTabletSettings and NUI.GetTabletSettings() or {})
    data.serverId = data.serverId or GetPlayerServerId(PlayerId())
    isOpen = true
    NUI.SetFocus(true, true)
    NUI.SendMessage('open', data)
    if NUI.SendDashboardData then
        NUI.SendDashboardData()
    end
end

--- Close the UI and release focus
function NUI.Close()
    isOpen = false
    NUI.SetFocus(false, false)
    NUI.SendMessage('close')
    NUI.SetVisibility(false)
end

--- Check if UI is currently open
---@return boolean
function NUI.IsOpen()
    return isOpen
end

local defaultTabletSettings = {
    soundEffects = true,
    notifications = true,
    policeAlerts = true,
    raceInvites = true,
    showHud = true,
    music = false,
    volume = 80,
    hudOpacity = 100,
    theme = 'dark'
}

local function GetRouteDifficulty(route)
    local minRep = tonumber(route and route.minRep) or 0
    if minRep >= 150 then return 'Hard' end
    if minRep >= 50 then return 'Medium' end
    return 'Easy'
end

local function BuildRoutePreview(checkpoints)
    if type(checkpoints) ~= 'table' or #checkpoints < 2 then return nil end

    local minX, maxX = checkpoints[1].x, checkpoints[1].x
    local minY, maxY = checkpoints[1].y, checkpoints[1].y

    for _, point in ipairs(checkpoints) do
        minX = math.min(minX, point.x)
        maxX = math.max(maxX, point.x)
        minY = math.min(minY, point.y)
        maxY = math.max(maxY, point.y)
    end

    local spanX = math.max(1.0, maxX - minX)
    local spanY = math.max(1.0, maxY - minY)
    local step = math.max(1, math.floor(#checkpoints / 10))
    local preview = {}

    for index = 1, #checkpoints, step do
        local point = checkpoints[index]
        preview[#preview + 1] = {
            math.floor(20 + ((point.x - minX) / spanX) * 360),
            math.floor(100 - ((point.y - minY) / spanY) * 80)
        }
    end

    local lastPoint = checkpoints[#checkpoints]
    local lastPreview = preview[#preview]
    local lastX = math.floor(20 + ((lastPoint.x - minX) / spanX) * 360)
    local lastY = math.floor(100 - ((lastPoint.y - minY) / spanY) * 80)
    if not lastPreview or lastPreview[1] ~= lastX or lastPreview[2] ~= lastY then
        preview[#preview + 1] = { lastX, lastY }
    end

    return preview
end

local function EstimateRouteTime(checkpointCount)
    local seconds = math.max(90, (tonumber(checkpointCount) or 0) * 12)
    return ('%d:%02d'):format(math.floor(seconds / 60), seconds % 60)
end

local function BuildRouteSummaries()
    local routes = {}

    for _, route in ipairs(Config.Routes or {}) do
        local checkpointCount = type(route.checkpoints) == 'table' and #route.checkpoints or 0
        local minRep = tonumber(route.minRep) or 0
        routes[#routes + 1] = {
            id = route.id,
            name = route.name,
            description = route.description,
            minRep = minRep,
            entryFee = tonumber(route.entryFee) or 0,
            checkpointCount = checkpointCount,
            estimatedTime = EstimateRouteTime(checkpointCount),
            difficulty = GetRouteDifficulty(route),
            type = route.type or (minRep >= 150 and 'hills' or minRep >= 50 and 'industrial' or 'urban'),
            features = route.features,
            preview = BuildRoutePreview(route.checkpoints)
        }
    end

    return routes
end

local function SanitizeTabletSettings(settings)
    local sanitized = {}

    for key, value in pairs(defaultTabletSettings) do
        if type(value) == 'boolean' then
            if settings and type(settings[key]) == 'boolean' then
                sanitized[key] = settings[key]
            else
                sanitized[key] = value
            end
        elseif type(value) == 'number' then
            sanitized[key] = math.floor(tonumber(settings and settings[key]) or value)
        else
            if settings and type(settings[key]) == type(value) then
                sanitized[key] = settings[key]
            else
                sanitized[key] = value
            end
        end
    end

    sanitized.volume = math.max(0, math.min(100, sanitized.volume))
    sanitized.hudOpacity = math.max(30, math.min(100, sanitized.hudOpacity))
    if sanitized.theme ~= 'dark' and sanitized.theme ~= 'light' then
        sanitized.theme = 'dark'
    end

    return sanitized
end

local function LoadTabletSettings()
    local raw = GetResourceKvpString('ug_racing_tablet_settings')
    if not raw or raw == '' then return SanitizeTabletSettings({}) end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        return SanitizeTabletSettings({})
    end

    return SanitizeTabletSettings(decoded)
end

local function SaveTabletSettings(settings)
    local sanitized = SanitizeTabletSettings(settings or {})
    SetResourceKvp('ug_racing_tablet_settings', json.encode(sanitized))
    return sanitized
end

function NUI.GetRouteSummaries()
    return BuildRouteSummaries()
end

function NUI.GetTabletSettings()
    return LoadTabletSettings()
end

function NUI.SendDashboardData()
    NUI.SendMessage('receiveRoutes', BuildRouteSummaries())
    NUI.SendMessage('receiveSettings', LoadTabletSettings())
    if RacingRadio and RacingRadio.GetState then
        NUI.SendMessage('raceRadioUpdate', RacingRadio.GetState())
    end
    TriggerServerEvent('streetracing:server:getPlayerData')
    TriggerServerEvent('streetracing:server:getLobbies')
    TriggerServerEvent('streetracing:server:getLeaderboard')
    TriggerServerEvent('streetracing:server:getPlayerStats')
    TriggerServerEvent('streetracing:server:getNetwork')
    TriggerServerEvent('streetracing:server:getRouteRecords')
    TriggerServerEvent('streetracing:server:getRaceRadio')
end

-- Register close callback from UI
RegisterNUICallback('close', function(_, cb)
    NUI.Close()
    cb({ success = true })
end)

-- Get player data callback
RegisterNUICallback('getPlayerData', function(_, cb)
    TriggerServerEvent('streetracing:server:getPlayerData')
    cb({ success = true })
end)

-- Get lobbies callback
RegisterNUICallback('getLobbies', function(_, cb)
    TriggerServerEvent('streetracing:server:getLobbies')
    cb({ success = true })
end)

-- Create lobby callback
RegisterNUICallback('createLobby', function(data, cb)
    data = data or {}
    if not data.routeId then
        cb({ success = false, error = 'missing_route' })
        return
    end

    TriggerServerEvent('streetracing:server:createLobby', data.routeId, data.betAmount)
    cb({ success = true })
end)

-- Join lobby callback
RegisterNUICallback('joinLobby', function(data, cb)
    data = data or {}
    if not data.lobbyId then
        cb({ success = false, error = 'missing_lobby' })
        return
    end

    TriggerServerEvent('streetracing:server:joinLobby', data.lobbyId)
    cb({ success = true })
end)

-- Leave lobby callback
RegisterNUICallback('leaveLobby', function(_, cb)
    TriggerServerEvent('streetracing:server:leaveLobby')
    cb({ success = true })
end)

-- Toggle ready callback
RegisterNUICallback('toggleReady', function(_, cb)
    TriggerServerEvent('streetracing:server:toggleReady')
    cb({ success = true })
end)

-- Start race callback
RegisterNUICallback('startRace', function(_, cb)
    TriggerServerEvent('streetracing:server:startRace')
    cb({ success = true })
end)

-- Get leaderboard callback
RegisterNUICallback('getLeaderboard', function(_, cb)
    TriggerServerEvent('streetracing:server:getLeaderboard')
    cb({ success = true })
end)

-- Set waypoint to race start line
RegisterNUICallback('setWaypoint', function(_, cb)
    if not CurrentLobby or not CurrentLobby.route or not CurrentLobby.route.checkpoints then
        cb({ success = false, error = 'no_lobby' })
        return
    end

    local startPos = CurrentLobby.route.checkpoints[1]
    if startPos then
        SetNewWaypoint(startPos.x, startPos.y)
        lib.notify({
            title = 'Waypoint Set',
            description = 'Start line marked on your GPS. Drive there!',
            type = 'success'
        })
    end
    cb({ success = true })
end)

RegisterNUICallback('getDashboardData', function(_, cb)
    NUI.SendDashboardData()
    cb({ success = true })
end)

RegisterNUICallback('getRoutes', function(_, cb)
    NUI.SendMessage('receiveRoutes', BuildRouteSummaries())
    TriggerServerEvent('streetracing:server:getRouteRecords')
    cb({ success = true })
end)

RegisterNUICallback('getStats', function(_, cb)
    TriggerServerEvent('streetracing:server:getPlayerStats')
    cb({ success = true })
end)

RegisterNUICallback('getNetwork', function(_, cb)
    TriggerServerEvent('streetracing:server:getNetwork')
    cb({ success = true })
end)

RegisterNUICallback('getSettings', function(_, cb)
    NUI.SendMessage('receiveSettings', LoadTabletSettings())
    cb({ success = true })
end)

RegisterNUICallback('saveSettings', function(data, cb)
    local settings = SaveTabletSettings(data)
    NUI.SendMessage('receiveSettings', settings)
    cb({ success = true, settings = settings })
end)

RegisterNUICallback('networkInvite', function(data, cb)
    TriggerServerEvent('streetracing:server:networkInvite', data and data.targetId or nil)
    cb({ success = true })
end)

RegisterNUICallback('networkMessage', function(data, cb)
    TriggerServerEvent('streetracing:server:networkMessage', data and data.targetId or nil)
    cb({ success = true })
end)

RegisterNUICallback('networkBroadcast', function(_, cb)
    TriggerServerEvent('streetracing:server:networkBroadcast')
    cb({ success = true })
end)

RegisterNUICallback('raceRadioJoin', function(_, cb)
    TriggerServerEvent('streetracing:server:joinRaceRadio')
    cb({ success = true })
end)

RegisterNUICallback('raceRadioLeave', function(_, cb)
    if RacingRadio and RacingRadio.Leave then
        RacingRadio.Leave(true)
    else
        TriggerServerEvent('streetracing:server:raceRadioState', false, nil)
    end
    cb({ success = true })
end)

RegisterNUICallback('getRaceRadio', function(_, cb)
    if RacingRadio and RacingRadio.GetState then
        NUI.SendMessage('raceRadioUpdate', RacingRadio.GetState())
    end
    TriggerServerEvent('streetracing:server:getRaceRadio')
    cb({ success = true })
end)
