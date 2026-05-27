Config = Config or {}

-- Secret NPC location (underground race organizer)
Config.NPC = {
    model = "g_m_m_chicold_01",
    coords = vector4(-1202.06, -1593.14, 3.2, 205.7), -- Hidden alley location
    scenario = "WORLD_HUMAN_SMOKING"
}

-- Rep thresholds for routes
Config.RepThresholds = {
    beginner = 0,
    amateur = 50,
    pro = 150,
    elite = 300,
    legendary = 500
}

-- Race routes (secret underground tracks)
Config.Routes = {
    {
        id = "downtown_drift",
        name = "Downtown Drift",
        description = "Navigate the city streets",
        minRep = 0,
        entryFee = 500,
        checkpoints = {
            vector3(-1190.5, -1580.2, 3.6),
            vector3(-1220.8, -1600.5, 3.5),
            vector3(-1260.3, -1615.8, 3.4),
            vector3(-1300.6, -1620.1, 3.6),
            vector3(-1340.2, -1610.5, 3.5),
            vector3(-1370.8, -1590.3, 3.4),
            vector3(-1390.5, -1560.2, 3.6),
            vector3(-1400.1, -1520.5, 3.5),
            vector3(-1390.3, -1480.8, 3.4),
            vector3(-1360.5, -1450.2, 3.5),
            vector3(-1320.8, -1440.5, 3.6),
            vector3(-1280.2, -1455.3, 3.5),
            vector3(-1250.5, -1480.6, 3.4),
            vector3(-1220.8, -1510.2, 3.5),
            vector3(-1190.5, -1540.8, 3.6)
        }
    },
    {
        id = "harbor_run",
        name = "Harbor Run",
        description = "Industrial speed run",
        minRep = 50,
        entryFee = 1500,
        checkpoints = {
            vector3(-800.5, -1400.2, 4.5),
            vector3(-830.8, -1450.5, 4.3),
            vector3(-860.3, -1500.8, 4.2),
            vector3(-890.6, -1560.1, 4.4),
            vector3(-920.2, -1620.5, 4.3),
            vector3(-950.8, -1680.3, 4.2),
            vector3(-980.5, -1740.2, 4.4),
            vector3(-1010.1, -1800.5, 4.3),
            vector3(-1040.3, -1860.8, 4.2),
            vector3(-1070.5, -1920.2, 4.4),
            vector3(-1050.8, -1980.5, 4.3),
            vector3(-1020.3, -2040.8, 4.2),
            vector3(-980.5, -2090.2, 4.4),
            vector3(-940.8, -2130.5, 4.3),
            vector3(-900.3, -2160.8, 4.2),
            vector3(-860.5, -2180.2, 4.4),
            vector3(-820.8, -2190.5, 4.3),
            vector3(-780.3, -2180.8, 4.2)
        }
    },
    {
        id = "vinewood_escape",
        name = "Vinewood Escape",
        description = "Elite hills and curves",
        minRep = 150,
        entryFee = 5000,
        checkpoints = {
            vector3(-200.5, -900.2, 30.5),
            vector3(-180.8, -860.5, 35.3),
            vector3(-160.3, -820.8, 42.2),
            vector3(-140.6, -780.1, 50.4),
            vector3(-120.2, -740.5, 58.3),
            vector3(-100.8, -700.3, 65.2),
            vector3(-80.5, -660.2, 72.4),
            vector3(-60.1, -620.5, 80.3),
            vector3(-40.3, -580.8, 88.2),
            vector3(-20.5, -540.2, 95.4),
            vector3(-10.8, -500.5, 100.3),
            vector3(-5.3, -460.8, 105.2),
            vector3(0.5, -420.2, 110.4),
            vector3(10.2, -380.5, 115.3),
            vector3(25.8, -340.8, 120.2),
            vector3(50.5, -310.2, 125.4),
            vector3(80.2, -280.5, 130.3),
            vector3(120.5, -260.8, 135.2),
            vector3(160.8, -250.2, 138.4),
            vector3(200.3, -240.5, 140.3),
            vector3(240.5, -250.8, 142.2),
            vector3(280.2, -270.2, 145.4)
        }
    }
}

-- Rep rewards
Config.RepRewards = {
    win = 25,
    second = 15,
    third = 10,
    participate = 5
}

-- Race settings
Config.MaxPlayers = 8
Config.MinPlayers = 2
Config.CountdownTime = 5
Config.CheckpointRadius = 15.0
Config.MaxDistanceFromRoute = 50.0
Config.RaceCooldown = 120 -- seconds between creating races per player
Config.RaceTimeoutMinutes = 15 -- auto-end active races after this many minutes
Config.MaxBetMultiplier = 5
Config.ReputationFile = 'reputation.json'

-- Server-side anti-cheat validation
Config.InteractionDistances = {
    organizer = 8.0,
    startLine = 40.0,
    finishLine = 45.0,
    spikeStrip = 4.0
}

-- GTA vehicle classes allowed in races. Defaults allow common road cars and bikes.
Config.AllowedVehicleClasses = {
    [0] = true,  -- Compacts
    [1] = true,  -- Sedans
    [2] = true,  -- SUVs
    [3] = true,  -- Coupes
    [4] = true,  -- Muscle
    [5] = true,  -- Sports Classics
    [6] = true,  -- Sports
    [7] = true,  -- Super
    [8] = true,  -- Motorcycles
    [9] = true,  -- Off-road
    [12] = true  -- Vans
}

-- Optional economy bridge. Leave disabled for virtual-only prize display.
Config.Economy = {
    enabled = false,
    type = 'ox_inventory',
    cashItem = 'money'
}

-- Police settings
Config.PoliceJobName = "police"
Config.PoliceJobs = {
    police = true,
    sheriff = true,
    state = true,
    leo = true
}
Config.PoliceWarningRadius = 150.0
Config.PoliceWarningCooldown = 30000 -- milliseconds between nearby police alerts per race
Config.PoliceWarningCheckInterval = 5000 -- milliseconds between server-side police proximity checks
Config.SpikeStripDuration = 30000 -- 30 seconds
Config.SpikeStripCooldown = 60000 -- 1 minute cooldown

-- Colors
Config.Colors = {
    primary = { r = 255, g = 50, b = 100 },
    secondary = { r = 50, g = 255, b = 150 },
    checkpoint = { r = 255, g = 200, b = 0 },
    finish = { r = 0, g = 255, b = 100 }
}
