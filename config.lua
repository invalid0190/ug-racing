Config = Config or {}

-- Resource language. Add another locales/<code>.lua file to extend support.
Config.Locale = "en"

-- Secret NPC location (underground race organizer)
Config.NPC = {
    model = "g_m_m_chicold_01",
    coords = vector4(-1202.06, -1593.14, 4.21, 205.7), -- Hidden alley location
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
        description = "Technical downtown circuit around Legion, Pillbox, and Alta",
        minRep = 0,
        entryFee = 500,
        type = "urban",
        features = { "starter", "circuit", "technical" },
        checkpoints = {
            vec3(-190.57, -891.67, 28.67),--1
            vec3(-44.73, -960.87, 28.75),--2
            vec3(-87.16, -1126.66, 25.11),--3
            vec3(42.35, -1125.0, 28.66),--4
            vec3(109.99, -1013.52, 28.73),--5
            vec3(225.02, -1022.95, 28.69),--6
            vec3(254.72, -849.08, 28.89),--7
            vec3(36.52, -767.85, 30.94),--8
            vec3(-221.94, -679.01, 32.87),--9
        }
    },
    {
        id = "harbor_run",
        name = "Harbor Run",
        description = "Dockyard circuit with long straights and heavy braking zones",
        minRep = 50,
        entryFee = 1500,
        type = "industrial",
        features = { "circuit", "high-speed", "industrial" },
        checkpoints = {
            vector3(822.5, -2988.7, 6.0),
            vector3(900.8, -3214.1, 5.9),
            vector3(1070.5, -3345.8, 5.9),
            vector3(1265.8, -3266.7, 5.8),
            vector3(1370.9, -3055.5, 5.9),
            vector3(1278.5, -2857.6, 5.9),
            vector3(1032.4, -2772.5, 5.9),
            vector3(802.5, -2826.9, 5.9),
            vector3(643.8, -2932.5, 6.0),
            vector3(594.2, -3110.4, 6.0),
            vector3(720.4, -3256.5, 5.9),
            vector3(822.5, -2988.7, 6.0)
        }
    },
    {
        id = "vinewood_escape",
        name = "Vinewood Escape",
        description = "Hard hill route through Vinewood backroads and overlook curves",
        minRep = 150,
        entryFee = 5000,
        type = "hills",
        features = { "elevation", "technical", "elite" },
        checkpoints = {
            vector3(-322.8, 270.8, 86.5),
            vector3(-445.5, 316.8, 83.2),
            vector3(-551.7, 435.2, 97.0),
            vector3(-672.4, 588.6, 144.4),
            vector3(-735.8, 784.6, 213.2),
            vector3(-680.4, 960.3, 238.5),
            vector3(-522.7, 1078.2, 323.8),
            vector3(-346.6, 1035.7, 289.2),
            vector3(-198.5, 899.9, 235.7),
            vector3(-96.2, 816.5, 227.6),
            vector3(78.8, 774.4, 211.6),
            vector3(231.2, 774.9, 189.7),
            vector3(345.6, 687.4, 169.3),
            vector3(440.7, 563.9, 156.5)
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
Config.CountdownTime = 10
Config.CheckpointRadius = 15.0
Config.MaxDistanceFromRoute = 220.0
Config.RaceCooldown = 120 -- seconds between creating races per player
Config.RaceTimeoutMinutes = 15 -- auto-end active races after this many minutes
Config.DNFTimeoutSeconds = 120 -- seconds after first finisher before remaining racers are marked DNF
Config.MaxBetMultiplier = 5
Config.ReputationFile = 'reputation.json'
Config.StatsFile = 'racing_stats.json'
Config.RaceHistoryLimit = 25

-- Racer crew radio. Uses pma-voice when available and gives each race lobby a private channel.
Config.RacerRadio = {
    enabled = true,
    voiceResource = 'pma-voice',
    channelBase = 700,
    channelRange = 200,
    autoJoinOnRaceStart = true,
    leaveOnRaceEnd = true,
    leaveOnLobbyExit = true
}

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
