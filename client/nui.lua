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
    isOpen = true
    NUI.SetFocus(true, true)
    NUI.SendMessage('open', data)
end

--- Close the UI and release focus
function NUI.Close()
    if not isOpen then return end
    isOpen = false
    NUI.SetFocus(false, false)
    NUI.SendMessage('close')
end

--- Check if UI is currently open
---@return boolean
function NUI.IsOpen()
    return isOpen
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
