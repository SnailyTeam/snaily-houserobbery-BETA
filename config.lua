Config = {}

Config.MissionNPC = {
    model = 'a_m_m_beach_01',
    coords = vector4(246.5643, 371.6057, 106.3246, 146.8855),
    animation = {
        dict = "anim@amb@business@bgen@bgen_no_work@",
        clip = "sit_phone_phoneputdown_sleeping_nowork"
    }
}

Config.SearchSettings = {
    duration = 5000,
    animation = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        clip = 'machinic_loop_mechandplayer'
    },
    noiseIncrease = {
        sprint = 0.2,
        run = 0.1
    },
    noiseDecrease = 0.05,
    maxNoise = 0.8,
    alertDistance = 2.0
}

Config.Blip = {
    mission = {
        sprite = 40,
        color = 1,
        scale = 0.8,
        label = 'Cel włamania'
    },
    pawnshop = {
        sprite = 226,
        color = 5,
        scale = 0.8,
        label = 'Lombard'
    }
}

Config.Settings = {
    Cooldown = 1, -- Cooldown między włamaniami w sekundach (domyślnie 30 minut)1800
    MaxLevel = 3, -- Maksymalny poziom
    EnablePoliceAlerts = true, -- Czy włączyć alerty dla policji
    MinimumPolice = 0, -- Minimalna liczba policjantów na służbie do rozpoczęcia włamania
}

Config.SleepingPed = {
    model = 'a_m_m_beach_01',
    health = 200,
    armor = 50,
    animation = {
        dict = 'missarmenian2',
        clip = 'corpse_search_exit_ped'
    },
    combat = {
        accuracy = 40,
        melee = {
            damage = 10,
            range = 2.0,
            aggressiveness = 100
        },
        ranged = {
            weapon = 'WEAPON_PISTOL',
            ammo = 250,
            accuracy = 40,
            range = 15.0
        }
    }
}

Config.Notifications = {
    missionAccepted = {
        title = 'Nowe zlecenie',
        description = 'Lokalizacja została oznaczona na GPS',
        type = 'success'
    },
    cooldown = {
        title = 'Cooldown',
        description = 'Musisz poczekać %d minut i %d sekund',
        type = 'error'
    },
    activeMission = {
        title = 'Błąd',
        description = 'Już masz aktywne zlecenie!',
        type = 'error'
    },
    policeAlert = {
        title = 'ALARM WŁAMANIOWY',
        description = 'Zgłoszono włamanie do domu!',
        type = 'error'
    },
    notEnoughPolice = {
        title = 'Błąd',
        description = 'Za mało policjantów na służbie!',
        type = 'error'
    }
}

Config.RobberyLevels = {
    [1] = {
        requiredRobberies = 0,
        houses = {
            {
                robberyStartPoint = vector4(252.5, -1670.6, 29.6, 142.5),
                interiorSpawnPoint = vector4(266.0, -1007.4, -101.0, 358.5),
                exitTargetPoint = vector4(265.9105, -1007.5816, -101.0087, 192.5960),
                sleepingNPCSpawnPoint = vector4(262.8, -1004.5, -99.0, 88.5),
                lootSpots = {
                    vector3(265.9, -999.4, -99.0),
                    vector3(259.5, -1004.0, -99.0)
                },
                searchedSpots = {}
            },
            {
                robberyStartPoint = vector4(1229.5, -725.6, 60.9, 89.5),
                interiorSpawnPoint = vector3(346.6265, -1013.1642, -99.1963),
                exitTargetPoint = vector4(346.6646, -1013.1846, -99.1963, 181.9012),
                sleepingNPCSpawnPoint = vector4(349.6853, -996.2477, -98.5398, 275.8073),
                lootSpots = {
                    vector3(344.5, -1001.4, -99.2),
                    vector3(346.2, -1001.4, -99.2)
                },
                searchedSpots = {}
            }
        },
        lootMultiplier = 1.0
    },
    [2] = {
        requiredRobberies = 5,
        houses = {
            {
                robberyStartPoint = vector4(-1910.7, 292.9, 88.6, 100.5),
                interiorSpawnPoint = vector3(117.2, 559.7, 184.3),
                exitTargetPoint = vector4(117.0805, 559.9503, 184.3048, 17.4953),
                sleepingNPCSpawnPoint = vector4(121.1624, 542.5545, 185.3907, 12.1825),
                lootSpots = {
                    vector3(120.0134, 557.3052, 184.2970),
                    vector3(118.0016, 548.4315, 184.0968),
                    vector3(120.9, 554.4, 184.3)
                },
                searchedSpots = {}
            },
            {
                robberyStartPoint = vector4(-174.7, 502.6, 137.4, 189.5),
                interiorSpawnPoint = vector3(-174.7, 497.8, 137.6),
                exitTargetPoint = vector4(-174.5595, 497.6523, 137.6550, 19.5659),
                sleepingNPCSpawnPoint = vector4(-167.6041, 481.8647, 138.2225, 23.5039),
                lootSpots = {
                    vector3(-170.9, 496.4, 137.6),
                    vector3(-168.9698, 493.3098, 138.5871-1),
                    vector3(-171.9238, 486.6628, 138.2300-1)
                },
                searchedSpots = {}
            }
        },
        lootMultiplier = 1.5
    },
    [3] = {
        requiredRobberies = 15,
        houses = {
            {
                robberyStartPoint = vector4(-780.2346, -791.6113, 27.8730, 271.8506),
                interiorSpawnPoint = vector4(-785.5801, 315.6420, 217.6383, 271.2926),
                exitTargetPoint = vector4(-787.4222, 315.5664, 217.6383, 100.1476),
                sleepingNPCSpawnPoint = vector4(-786.7749, 338.3646, 217.3078, 3.1002),
                lootSpots = {
                    vector3(-783.4391, 325.4206, 217.0381),
                    vector3(-798.7376, 327.6637, 217.0381),
                    vector3(-800.1044, 338.4193, 220.4386),
                    vector3(-796.2819, 328.6352, 220.4384)
                },
                searchedSpots = {}
            },
            {
                robberyStartPoint = vector4(-761.9060, 351.5860, 87.8217, 179.2718),
                interiorSpawnPoint = vector4(-785.1845, 323.4698, 211.9972, 258.5872),
                exitTargetPoint = vector4(-785.1195, 323.6523, 211.9972, 97.5467),
                sleepingNPCSpawnPoint = vector4(-784.0604, 336.7764, 211.6640, 2.1302),
                lootSpots = {
                    vector3(-789.7723, 334.0271, 210.8318),
                    vector3(-779.5778, 333.4567, 211.1971),
                    vector3(-786.2425, 337.5199, 211.1971),
                    vector3(-763.0630, 327.1236, 211.3965)
                },
                searchedSpots = {}
            }
        },
        lootMultiplier = 2.0
    }
}

Config.PossibleLoot = {
    {item = 'gold', label = 'Złoto', chance = 30, minAmount = 1, maxAmount = 3},
    {item = 'diamond', label = 'Diament', chance = 10, minAmount = 1, maxAmount = 2},
    {item = 'money', label = 'Gotówka', chance = 50, minAmount = 100, maxAmount = 1000},
    {item = 'jewels', label = 'Biżuteria', chance = 40, minAmount = 1, maxAmount = 4},
    {item = 'laptop', label = 'Laptop', chance = 25, minAmount = 1, maxAmount = 1},
    {item = 'phone', label = 'Telefon', chance = 35, minAmount = 1, maxAmount = 2},
    {item = 'watch', label = 'Zegarek', chance = 45, minAmount = 1, maxAmount = 2}
}

Config.PawnShop = {
    npc = {
        model = 'a_m_m_eastsa_02',
        coords = vector4(182.7, -1319.5, 29.3, 238.5),
        scenario = 'WORLD_HUMAN_SMOKING'
    },
    prices = {
        gold = {price = 1000, label = "Złoto"},
        diamond = {price = 2500, label = "Diament"},
        jewels = {price = 750, label = "Biżuteria"},
        laptop = {price = 500, label = "Laptop"},
        phone = {price = 250, label = "Telefon"},
        watch = {price = 350, label = "Zegarek"}
    }
}
