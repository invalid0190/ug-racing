local SpikeStrips = {}
local LocalSpikeEntities = {}
local SpikeHitSent = {}

local function Notify(data)
    lib.notify(data)
end

-- Create spike strip locally
RegisterNetEvent('streetracing:client:createSpikeStrip', function(data)
    data = data or {}
    local spikeId = data.id
    local coords = data.coords
    local heading = data.heading
    if not spikeId or not coords then return end
    
    -- Load model
    local model = GetHashKey("prop_spikestrip_01")
    RequestModel(model)
    local expiresAt = GetGameTimer() + 5000
    while not HasModelLoaded(model) do
        if GetGameTimer() > expiresAt then return end
        Wait(100)
    end
    
    -- Create spike object
    local spike = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    SetEntityHeading(spike, heading)
    SetModelAsNoLongerNeeded(model)
    
    -- Store reference
    LocalSpikeEntities[spikeId] = spike
    SpikeStrips[spikeId] = {
        coords = coords,
        entity = spike
    }
    
    -- Start detection thread
    CreateThread(function()
        while LocalSpikeEntities[spikeId] and DoesEntityExist(LocalSpikeEntities[spikeId]) do
            local playerPed = PlayerPedId()
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            
            if playerVehicle and playerVehicle ~= 0 then
                local vehicleCoords = GetEntityCoords(playerVehicle)
                local dist = #(vehicleCoords - coords)
                
                -- Check if vehicle hits spike (within 2 meters)
                if dist < 2.0 and not SpikeHitSent[spikeId] then
                    -- Check if vehicle is actually driving over it (moving)
                    local speed = GetEntitySpeed(playerVehicle)
                    if speed > 5.0 then -- Only if moving
                        SpikeHitSent[spikeId] = true
                        TriggerServerEvent('streetracing:server:hitSpikeStrip', spikeId)
                    end
                end
            end
            
            Wait(100)
        end
    end)
end)

-- Remove spike strip
RegisterNetEvent('streetracing:client:removeSpikeStrip', function(spikeId)
    if LocalSpikeEntities[spikeId] then
        if DoesEntityExist(LocalSpikeEntities[spikeId]) then
            DeleteEntity(LocalSpikeEntities[spikeId])
        end
        LocalSpikeEntities[spikeId] = nil
    end
    SpikeStrips[spikeId] = nil
    SpikeHitSent[spikeId] = nil
end)

-- Burst tires effect
RegisterNetEvent('streetracing:client:burstTires', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle and vehicle ~= 0 then
        -- Burst all tires
        for i = 0, 7 do
            SetVehicleTyreBurst(vehicle, i, true, 1000.0)
        end
        
        -- Visual effect
        Notify({
            title = 'TIRES BLOWN!',
            description = 'Your tires have been shredded!',
            type = 'error'
        })
        
        -- Screen shake effect
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.5)
    end
end)

-- Set GPS to race location
RegisterNetEvent('streetracing:client:setRaceGPS', function(coords)
    if not coords then return end
    -- Remove old waypoint if exists
    SetNewWaypoint(coords.x, coords.y)
    
    Notify({
        title = 'GPS Set',
        description = 'Race location marked on your GPS',
        type = 'inform'
    })
end)

-- Police scanner command (for officers)
RegisterCommand('policeradio', function()
    lib.registerContext({
        id = 'police_radio',
        title = 'Police Radio',
        canClose = true,
        options = {
            {
                title = 'Scan for Street Races',
                description = 'Detect any active illegal races',
                icon = 'search',
                onSelect = function()
                    ExecuteCommand('scanraces')
                end
            },
            {
                title = 'Deploy Spike Strip',
                description = 'Place a spike strip at your location',
                icon = 'road',
                onSelect = function()
                    ExecuteCommand('spike')
                end
            },
            {
                title = 'Remove Spike Strip',
                description = 'Remove your deployed spike strip',
                icon = 'times',
                onSelect = function()
                    ExecuteCommand('removespike')
                end
            }
        }
    })
    
    lib.showContext('police_radio')
end, false)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Remove all spike strips
        for spikeId, entity in pairs(LocalSpikeEntities) do
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end
    end
end)
