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
        description = "Technical downtown circuit around Legion, Pillbox, and Alta",
        minRep = 0,
        entryFee = 500,
        type = "urban",
        features = { "starter", "circuit", "technical" },
        checkpoints = {
            vector3(-302.4, -875.8, 31.1),
            vector3(-207.7, -1017.6, 30.1),
            vector3(35.4, -1044.7, 29.5),
            vector3(220.2, -1005.2, 29.3),
            vector3(287.3, -812.7, 29.2),
            vector3(265.4, -606.3, 43.0),
            vector3(95.6, -563.8, 43.5),
            vector3(-124.4, -585.5, 36.3),
            vector3(-274.5, -678.4, 33.4),
            vector3(-363.2, -806.8, 31.5),
            vector3(-302.4, -875.8, 31.1)
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
    },
    {
        id = "vespucci_canal_dash",
        name = "Vespucci Canal Dash",
        description = "Fast beachside cuts through Vespucci and the canals",
        minRep = 0,
        entryFee = 750,
        type = "urban",
        features = { "short", "technical", "night-friendly" },
        checkpoints = {
            vector3(-1205.8, -1593.2, 3.9),
            vector3(-1112.6, -1648.5, 4.2),
            vector3(-972.1, -1585.8, 5.0),
            vector3(-875.4, -1450.6, 5.0),
            vector3(-834.5, -1302.8, 5.0),
            vector3(-969.8, -1194.2, 5.2),
            vector3(-1146.7, -1219.6, 6.3),
            vector3(-1319.8, -1294.4, 4.4),
            vector3(-1433.2, -1446.7, 3.9),
            vector3(-1350.7, -1573.6, 4.3),
            vector3(-1236.4, -1605.5, 4.0)
        }
    },
    {
        id = "airport_midnight_loop",
        name = "Airport Midnight Loop",
        description = "Wide LSIA lanes with heavy braking around the terminal",
        minRep = 0,
        entryFee = 1000,
        type = "circuit",
        features = { "wide", "beginner", "high-speed" },
        checkpoints = {
            vector3(-968.5, -2698.8, 13.8),
            vector3(-1105.2, -2897.5, 13.8),
            vector3(-1294.5, -3053.6, 13.8),
            vector3(-1539.4, -2995.9, 13.8),
            vector3(-1650.8, -2782.3, 13.8),
            vector3(-1512.8, -2608.6, 13.8),
            vector3(-1280.9, -2529.8, 13.8),
            vector3(-1058.5, -2560.3, 13.8),
            vector3(-968.5, -2698.8, 13.8)
        }
    },
    {
        id = "mirror_park_circuit",
        name = "Mirror Park Circuit",
        description = "Clean residential circuit with quick turns and short straights",
        minRep = 25,
        entryFee = 1250,
        type = "urban",
        features = { "circuit", "balanced", "traffic-risk" },
        checkpoints = {
            vector3(1087.4, -777.2, 58.3),
            vector3(1209.5, -654.8, 62.5),
            vector3(1261.2, -438.5, 69.0),
            vector3(1122.7, -318.4, 67.0),
            vector3(931.9, -358.5, 66.3),
            vector3(833.4, -547.1, 57.3),
            vector3(918.8, -742.2, 42.9),
            vector3(1035.5, -823.9, 48.0),
            vector3(1087.4, -777.2, 58.3)
        }
    },
    {
        id = "cypress_industrial_gp",
        name = "Cypress Industrial GP",
        description = "Industrial blocks, blind corners, and dockside straights",
        minRep = 50,
        entryFee = 1750,
        type = "industrial",
        features = { "circuit", "technical", "medium" },
        checkpoints = {
            vector3(923.8, -2362.4, 30.5),
            vector3(1115.4, -2292.5, 30.4),
            vector3(1225.7, -2072.6, 43.0),
            vector3(1051.8, -1968.4, 31.1),
            vector3(842.6, -2096.2, 29.7),
            vector3(724.5, -2258.6, 29.3),
            vector3(814.6, -2417.8, 28.5),
            vector3(923.8, -2362.4, 30.5)
        }
    },
    {
        id = "rockford_grand_prix",
        name = "Rockford Grand Prix",
        description = "Premium city circuit through Rockford and Burton",
        minRep = 75,
        entryFee = 2500,
        type = "urban",
        features = { "circuit", "clean", "premium" },
        checkpoints = {
            vector3(-559.5, -310.2, 35.1),
            vector3(-768.8, -207.4, 37.3),
            vector3(-958.6, -181.6, 37.7),
            vector3(-1080.2, -284.9, 37.7),
            vector3(-1004.2, -462.1, 37.2),
            vector3(-823.8, -571.4, 29.8),
            vector3(-623.5, -520.7, 34.7),
            vector3(-497.9, -410.3, 34.2),
            vector3(-559.5, -310.2, 35.1)
        }
    },
    {
        id = "olympic_freeway_rush",
        name = "Olympic Freeway Rush",
        description = "Point-to-point freeway blast built for top speed",
        minRep = 100,
        entryFee = 3000,
        type = "freeway",
        features = { "point-to-point", "high-speed", "drafting" },
        checkpoints = {
            vector3(255.4, -1075.7, 29.2),
            vector3(470.8, -1198.3, 29.2),
            vector3(780.5, -1231.4, 26.4),
            vector3(1082.6, -1273.8, 20.8),
            vector3(1337.4, -1422.7, 13.3),
            vector3(1530.8, -1622.6, 12.7),
            vector3(1714.3, -1714.9, 12.9),
            vector3(1917.8, -1866.5, 20.0)
        }
    },
    {
        id = "vinewood_hills_switchback",
        name = "Vinewood Hills Switchback",
        description = "Hill climb and descent with sharp switchbacks",
        minRep = 150,
        entryFee = 4500,
        type = "hills",
        features = { "elevation", "technical", "hard" },
        checkpoints = {
            vector3(-318.4, 829.6, 198.1),
            vector3(-497.5, 706.8, 151.6),
            vector3(-621.3, 541.2, 106.5),
            vector3(-731.5, 356.1, 87.8),
            vector3(-735.9, 160.4, 73.7),
            vector3(-620.4, 34.8, 43.6),
            vector3(-418.6, -55.7, 44.9),
            vector3(-265.2, -16.8, 49.0),
            vector3(-160.6, 120.5, 70.4),
            vector3(-95.2, 330.6, 112.4),
            vector3(-188.8, 525.4, 138.3),
            vector3(-318.4, 829.6, 198.1)
        }
    },
    {
        id = "sandy_airstrip_rally",
        name = "Sandy Airstrip Rally",
        description = "Loose desert loop around Sandy Shores airfield",
        minRep = 150,
        entryFee = 4000,
        type = "offroad",
        features = { "dirt", "circuit", "slippery" },
        checkpoints = {
            vector3(1738.2, 3278.5, 41.1),
            vector3(1886.4, 3285.8, 45.0),
            vector3(2036.7, 3170.4, 45.2),
            vector3(2061.4, 2940.8, 47.2),
            vector3(1935.4, 2678.9, 46.0),
            vector3(1711.7, 2634.8, 45.5),
            vector3(1512.4, 2787.9, 38.6),
            vector3(1556.8, 3041.5, 40.4),
            vector3(1665.7, 3204.8, 41.3),
            vector3(1738.2, 3278.5, 41.1)
        }
    },
    {
        id = "senora_desert_sprint",
        name = "Senora Desert Sprint",
        description = "Fast desert road sprint through Harmony and Senora",
        minRep = 200,
        entryFee = 5500,
        type = "desert",
        features = { "long", "high-speed", "rural" },
        checkpoints = {
            vector3(1160.5, 2660.5, 38.0),
            vector3(1366.4, 2655.3, 37.7),
            vector3(1650.9, 2576.4, 45.4),
            vector3(1941.2, 2620.8, 46.0),
            vector3(2241.5, 2681.3, 46.6),
            vector3(2532.2, 2601.6, 37.9),
            vector3(2701.6, 2960.5, 40.2),
            vector3(2510.7, 3200.6, 51.2),
            vector3(2220.5, 3311.4, 46.5)
        }
    },
    {
        id = "great_ocean_coastal",
        name = "Great Ocean Coastal",
        description = "Long coastal run with cliffs, sweepers, and traffic danger",
        minRep = 250,
        entryFee = 6500,
        type = "coastal",
        features = { "long", "scenic", "dangerous" },
        checkpoints = {
            vector3(-2150.6, -330.4, 13.0),
            vector3(-2370.4, -190.6, 13.4),
            vector3(-2600.7, 260.5, 15.0),
            vector3(-2880.8, 740.2, 30.0),
            vector3(-3060.3, 1185.7, 21.1),
            vector3(-3090.9, 1661.5, 36.4),
            vector3(-2995.8, 2145.7, 42.2),
            vector3(-2680.4, 2315.9, 19.0),
            vector3(-2300.8, 2465.5, 5.0)
        }
    },
    {
        id = "zancudo_to_paleto",
        name = "Zancudo To Paleto",
        description = "Northbound endurance race from Fort Zancudo to Paleto",
        minRep = 300,
        entryFee = 8500,
        type = "endurance",
        features = { "long", "endurance", "top-speed" },
        checkpoints = {
            vector3(-2300.4, 3410.8, 32.8),
            vector3(-2180.6, 4050.2, 13.2),
            vector3(-2000.7, 4520.4, 57.0),
            vector3(-1690.4, 4941.6, 61.5),
            vector3(-1290.5, 5260.4, 52.2),
            vector3(-760.7, 5530.8, 35.4),
            vector3(-380.2, 6125.6, 31.5),
            vector3(-105.5, 6350.3, 31.5),
            vector3(140.4, 6615.8, 31.8)
        }
    },
    {
        id = "chiliad_foothills_rally",
        name = "Chiliad Foothills Rally",
        description = "Legendary mixed-surface route around Paleto foothills",
        minRep = 500,
        entryFee = 12000,
        type = "offroad",
        features = { "legendary", "offroad", "endurance" },
        checkpoints = {
            vector3(154.7, 6547.6, 31.8),
            vector3(-28.6, 6795.4, 41.8),
            vector3(-421.5, 6857.8, 75.6),
            vector3(-758.6, 6750.2, 103.4),
            vector3(-1017.8, 6497.5, 119.6),
            vector3(-920.7, 6200.9, 99.8),
            vector3(-650.2, 5900.8, 89.3),
            vector3(-320.4, 5760.3, 74.8),
            vector3(20.6, 5600.4, 60.5),
            vector3(380.5, 5520.8, 205.4)
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
Config.MaxDistanceFromRoute = 220.0
Config.RaceCooldown = 120 -- seconds between creating races per player
Config.RaceTimeoutMinutes = 15 -- auto-end active races after this many minutes
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
