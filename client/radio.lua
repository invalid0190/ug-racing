RacingRadio = {
    joined = false,
    currentChannel = 0,
    previousChannel = nil,
    joinedAutomatically = false
}

local function Notify(data)
    lib.notify(LocalizeNotification(data))
end

local function GetVoiceResource()
    local radioConfig = Config.RacerRadio or {}
    return radioConfig.voiceResource or 'pma-voice'
end

local function IsRacerRadioEnabled()
    return Config.RacerRadio and Config.RacerRadio.enabled ~= false
end

local function IsVoiceReady()
    local voiceResource = GetVoiceResource()
    return IsRacerRadioEnabled() and GetResourceState(voiceResource) == 'started'
end

local function GetCurrentVoiceChannel()
    local channel = LocalPlayer and LocalPlayer.state and LocalPlayer.state.radioChannel
    return math.floor(tonumber(channel) or 0)
end

local function SendRadioState()
    if NUI and NUI.SendMessage then
        NUI.SendMessage('raceRadioUpdate', RacingRadio.GetState())
    end
end

function RacingRadio.GetState()
    local stateChannel = GetCurrentVoiceChannel()
    return {
        enabled = IsRacerRadioEnabled(),
        available = IsVoiceReady(),
        joined = RacingRadio.joined == true and stateChannel == RacingRadio.currentChannel,
        channel = RacingRadio.currentChannel,
        currentVoiceChannel = stateChannel,
        previousChannel = RacingRadio.previousChannel
    }
end

function RacingRadio.Join(channel, automatic)
    channel = math.floor(tonumber(channel) or 0)
    if channel <= 0 then
        Notify({ title = 'Race Radio', description = 'Radio channel is unavailable', type = 'error' })
        return false
    end

    if not IsVoiceReady() then
        Notify({ title = 'Race Radio', description = 'pma-voice is not started', type = 'error' })
        TriggerServerEvent('streetracing:server:raceRadioState', false, channel)
        SendRadioState()
        return false
    end

    if RacingRadio.joined and RacingRadio.currentChannel == channel and GetCurrentVoiceChannel() == channel then
        SendRadioState()
        return true
    end

    local voiceResource = GetVoiceResource()
    local currentVoiceChannel = GetCurrentVoiceChannel()
    if currentVoiceChannel > 0 and currentVoiceChannel ~= channel and not RacingRadio.joined then
        RacingRadio.previousChannel = currentVoiceChannel
    end

    local ok, err = pcall(function()
        exports[voiceResource]:setVoiceProperty('radioEnabled', true)
        exports[voiceResource]:setRadioChannel(channel)
    end)

    if not ok then
        Notify({ title = 'Race Radio', description = 'Could not connect to racer radio', type = 'error' })
        TriggerServerEvent('streetracing:server:raceRadioState', false, channel)
        print(('[racing-system] ERROR: race radio join failed: %s'):format(tostring(err)))
        SendRadioState()
        return false
    end

    RacingRadio.joined = true
    RacingRadio.currentChannel = channel
    RacingRadio.joinedAutomatically = automatic == true

    TriggerServerEvent('streetracing:server:raceRadioState', true, channel)
    Notify({ title = 'Race Radio', description = _L('crew_radio_connected', channel + 0.0), type = 'success' })
    SendRadioState()
    return true
end

function RacingRadio.Leave(restorePrevious)
    local channel = RacingRadio.currentChannel
    local voiceResource = GetVoiceResource()

    if IsVoiceReady() then
        local restoreChannel = restorePrevious and tonumber(RacingRadio.previousChannel) or 0
        local ok, err = pcall(function()
            exports[voiceResource]:setRadioChannel(math.floor(restoreChannel or 0))
        end)

        if not ok then
            print(('[racing-system] ERROR: race radio leave failed: %s'):format(tostring(err)))
        end
    end

    RacingRadio.joined = false
    RacingRadio.currentChannel = 0
    RacingRadio.previousChannel = nil
    RacingRadio.joinedAutomatically = false

    TriggerServerEvent('streetracing:server:raceRadioState', false, channel)
    SendRadioState()
end

RegisterNetEvent('streetracing:client:joinRaceRadio', function(data)
    data = data or {}
    RacingRadio.Join(data.channel, data.automatic == true)
end)

RegisterNetEvent('streetracing:client:leaveRaceRadio', function(data)
    data = data or {}
    RacingRadio.Leave(data.restorePrevious == true)
end)

RegisterNetEvent('streetracing:client:receiveRaceRadio', function(data)
    data = data or {}
    if NUI and NUI.SendMessage then
        data.localState = RacingRadio.GetState()
        NUI.SendMessage('receiveRaceRadio', data)
    end
end)

AddStateBagChangeHandler('radioChannel', nil, function(bagName, _, value)
    if bagName ~= ('player:%d'):format(GetPlayerServerId(PlayerId())) then return end

    if RacingRadio.joined and tonumber(value) ~= RacingRadio.currentChannel then
        RacingRadio.joined = false
        RacingRadio.currentChannel = 0
        RacingRadio.joinedAutomatically = false
        TriggerServerEvent('streetracing:server:raceRadioState', false, nil)
        SendRadioState()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RacingRadio.Leave(true)
    end
end)
