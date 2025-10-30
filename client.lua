local currentMission = nil
local missionBlip = nil
local currentPed = nil
local playerLevel = 1
local playerRobberies = 0
local noiseLevel = 0
local currentZones = {}

CreateThread(function()
    Wait(1000)
    lib.callback('snaily-houserobbery:getPlayerData', false, function(level, robberies)
        playerLevel = level
        playerRobberies = robberies
    end)
end)

RegisterNetEvent('snaily-houserobbery:initializeData')
AddEventHandler('snaily-houserobbery:initializeData', function(level, robberies)
    playerLevel = level
    playerRobberies = robberies
end)

function CreateMissionPed()
    lib.requestModel(Config.MissionNPC.model)

    local ped = CreatePed(4, Config.MissionNPC.model,
        Config.MissionNPC.coords.x,
        Config.MissionNPC.coords.y,
        Config.MissionNPC.coords.z - 0.98,
        Config.MissionNPC.coords.w,
        false, true)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    RequestAnimDict(Config.MissionNPC.animation.dict)
    while not HasAnimDictLoaded(Config.MissionNPC.animation.dict) do Wait(10) end

    TaskPlayAnim(ped,
        Config.MissionNPC.animation.dict,
        Config.MissionNPC.animation.clip,
        8.0, -8.0, -1, 1, 0, false, false, false)

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'mission_giver',
            label = 'Porozmawiaj o robocie',
            icon = 'fas fa-comments',
            onSelect = function()
                OpenMissionMenu()
            end
        }
    })
end

function CreateSleepingPed(coords)
    if currentPed and DoesEntityExist(currentPed) then
        DeleteEntity(currentPed)
    end

    lib.requestModel(Config.SleepingPed.model)

    currentPed = CreatePed(4, GetHashKey(Config.SleepingPed.model),
        coords.x, coords.y, coords.z - 1.0, coords.w, false, true)

    SetEntityHealth(currentPed, Config.SleepingPed.health)
    SetPedArmour(currentPed, Config.SleepingPed.armor)
    SetPedMaxHealth(currentPed, Config.SleepingPed.health)
    SetPedCanRagdoll(currentPed, true)
    SetPedCanRagdollFromPlayerImpact(currentPed, true)
    SetBlockingOfNonTemporaryEvents(currentPed, true)

    RequestAnimDict(Config.SleepingPed.animation.dict)
    while not HasAnimDictLoaded(Config.SleepingPed.animation.dict) do Wait(10) end

    TaskPlayAnim(currentPed,
        Config.SleepingPed.animation.dict,
        Config.SleepingPed.animation.clip,
        8.0, -8.0, -1, 1, 0, false, false, false)

    RemoveAllPedWeapons(currentPed, true)

    return currentPed
end

function OpenMissionMenu()
    lib.callback('snaily-houserobbery:getPlayerData', false, function(level, robberies)
        playerLevel = level
        playerRobberies = robberies

        local nextLevel = level + 1
        local currentLevelRequired = Config.RobberyLevels[level].requiredRobberies or 0
        local nextLevelRequired = Config.RobberyLevels[nextLevel] and Config.RobberyLevels[nextLevel].requiredRobberies or 999
        local robberiesToNext = nextLevelRequired - currentLevelRequired
        local currentProgress = robberies - currentLevelRequired
        local progressPercentage = math.floor((currentProgress / robberiesToNext) * 100)

        lib.registerContext({
            id = 'house_robbery_menu',
            title = 'Menu Włamań',
            options = {
                {
                    title = 'Weź zlecenie',
                    description = ('Poziom %d | Wykonane włamania: %d/%d (%d%%)'):format(
                        playerLevel,
                        robberies,
                        nextLevelRequired,
                        progressPercentage
                    ),
                    icon = 'fas fa-house-damage',
                    progress = progressPercentage,
                    onSelect = function()
                        StartHouseRobbery()
                    end
                },
            }
        })
        lib.showContext('house_robbery_menu')
    end)
end

function StartHouseRobbery()
    if currentMission then
        lib.notify(Config.Notifications.activeMission)
        return
    end

    lib.callback('snaily-houserobbery:canStartMission', false, function(canStart, remainingTime)
        if not canStart then
            if remainingTime == -1 then
                lib.notify(Config.Notifications.notEnoughPolice)
                return
            end

            local minutes = math.floor(remainingTime / 60)
            local seconds = remainingTime % 60
            lib.notify({
                title = Config.Notifications.cooldown.title,
                description = string.format(Config.Notifications.cooldown.description, minutes, seconds),
                type = 'error'
            })
            return
        end

        local houses = Config.RobberyLevels[playerLevel].houses
        local randomHouse = houses[math.random(#houses)]
        currentMission = randomHouse

        CreateMissionBlip(randomHouse.robberyStartPoint)
        CreateEntryZone(randomHouse)

        lib.notify(Config.Notifications.missionAccepted)
    end)
end

function CreateMissionBlip(coords)
    if missionBlip then RemoveBlip(missionBlip) end

    missionBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(missionBlip, Config.Blip.mission.sprite)
    SetBlipColour(missionBlip, Config.Blip.mission.color)
    SetBlipScale(missionBlip, Config.Blip.mission.scale)
    SetBlipRoute(missionBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blip.mission.label)
    EndTextCommandSetBlipName(missionBlip)
end

function CreateEntryZone(house)
    ClearSearchZones()

    local zone = exports.ox_target:addSphereZone({
        coords = vec3(house.robberyStartPoint.x, house.robberyStartPoint.y, house.robberyStartPoint.z),
        radius = 1.5,
        options = {
            {
                name = 'house_entry',
                label = 'Włam się',
                icon = 'fas fa-lock-open',
                onSelect = function()
                    StartHouseInterior(house)
                end
            }
        }
    })
    table.insert(currentZones, zone)
end

function StartHouseInterior(house)
    local playerPed = PlayerPedId()
    local sleepingPed = CreateSleepingPed(house.sleepingNPCSpawnPoint)
    local difficulty
    local success = false

    local lockpick = exports.ox_inventory:Search('count', 'lockpick')

    if lockpick < 1 then
        lib.notify({
            title = 'Błąd',
            description = 'Nie posiadasz wytrychu!',
            type = 'error'
        })
        return
    end

    if playerLevel == 1 then
        difficulty = 'easy'
    elseif playerLevel == 2 then
        difficulty = 'medium'
    else
        difficulty = 'hard'
    end

    if lib.progressBar({
        duration = 2000,
        label = 'Przygotowywanie wytrychu...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'mp_arresting',
            clip = 'a_uncuff'
        },
    }) then
        success = lib.skillCheck(difficulty)
    end

    if not success then
        lib.notify({
            title = 'Nieudane włamanie',
            description = 'Wytrych się złamał!',
            type = 'error'
        })

        TriggerServerEvent('snaily-houserobbery:removeItem', 'lockpick', 1)
        return
    end

    house.searchedSpots = {}

    DoScreenFadeOut(1000)
    Wait(1000)

    SetEntityCoords(playerPed, house.interiorSpawnPoint.x, house.interiorSpawnPoint.y, house.interiorSpawnPoint.z)
    SetEntityHeading(playerPed, house.interiorSpawnPoint.w)
    CreateSearchZones(house)
    StartNoiseMonitoring(sleepingPed)

    DoScreenFadeIn(1000)

    TriggerServerEvent('snaily-houserobbery:removeItem', 'lockpick', 1)
end

function StartNoiseMonitoring(ped)
    CreateThread(function()
        local isAlerted = false

        while DoesEntityExist(ped) and not IsEntityDead(ped) and not isAlerted do
            Wait(100)

            local playerPed = PlayerPedId()
            local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(ped))

            if IsPedSprinting(playerPed) then
                noiseLevel = noiseLevel + Config.SearchSettings.noiseIncrease.sprint
            elseif IsPedRunning(playerPed) then
                noiseLevel = noiseLevel + Config.SearchSettings.noiseIncrease.run
            end

            noiseLevel = math.max(0, noiseLevel - Config.SearchSettings.noiseDecrease)

            if noiseLevel > Config.SearchSettings.maxNoise or
               distance < Config.SearchSettings.alertDistance or
               HasEntityBeenDamagedByEntity(ped, playerPed, 1) then
                isAlerted = true
                AlertPed(ped)
            end
        end
    end)
end

function AlertPed(ped)
    if not DoesEntityExist(ped) then return end

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, false)

    if playerLevel == 1 then
        ConfigureMeleeCombat(ped)
    else
        ConfigureRangedCombat(ped)
    end

    StartCombatBehavior(ped)

    lib.callback('snaily-houserobbery:alertPolice', false, function(success)
        if success then
            lib.notify(Config.Notifications.policeAlert)
        end
    end, GetEntityCoords(PlayerPedId()))
end

function ConfigureMeleeCombat(ped)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatMovement(ped, 3)
    SetPedCombatRange(ped, Config.SleepingPed.combat.melee.range)
    SetPedCombatAbility(ped, Config.SleepingPed.combat.melee.aggressiveness)
    RemoveAllPedWeapons(ped)
    SetPedCanSwitchWeapon(ped, false)
end

function ConfigureRangedCombat(ped)
    GiveWeaponToPed(ped, GetHashKey(Config.SleepingPed.combat.ranged.weapon),
        Config.SleepingPed.combat.ranged.ammo, false, true)
    SetPedInfiniteAmmo(ped, true, GetHashKey(Config.SleepingPed.combat.ranged.weapon))
    SetPedAccuracy(ped, Config.SleepingPed.combat.ranged.accuracy)
end

function StartCombatBehavior(ped)
    CreateThread(function()
        while DoesEntityExist(ped) and not IsEntityDead(ped) do
            Wait(1000)
            local playerPed = PlayerPedId()
            local distance = #(GetEntityCoords(ped) - GetEntityCoords(playerPed))

            if playerLevel == 1 then
                if distance > Config.SleepingPed.combat.melee.range * 2 then
                    TaskGoToEntityWhileAimingAtEntity(ped, playerPed, playerPed, 2.0, true, 0, 0, 0, 0)
                else
                    if not IsPedInCombat(ped, playerPed) then
                        TaskCombatPed(ped, playerPed, 0, 16)
                    end
                end
            else
                if distance > Config.SleepingPed.combat.ranged.range then
                    TaskGoToEntityWhileAimingAtEntity(ped, playerPed, playerPed, 2.0, true, 0, 0, 0, 0)
                elseif distance < Config.SleepingPed.combat.ranged.range * 0.3 then
                    local behind = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -5.0, 0.0)
                    TaskGoToCoordAnyMeans(ped, behind.x, behind.y, behind.z, 2.0, 0, false, 786603, 0)
                else
                    if not IsPedInCombat(ped, playerPed) then
                        TaskCombatPed(ped, playerPed, 0, 16)
                    end
                end
            end
        end
    end)
end

function CreateSearchZones(house)
    ClearSearchZones()

    local exitZone = exports.ox_target:addSphereZone({
        coords = vec3(house.exitTargetPoint.x, house.exitTargetPoint.y, house.exitTargetPoint.z),
        radius = 1.5,
        options = {
            {
                name = 'house_exit',
                label = 'Wyjdź z domu',
                icon = 'fas fa-door-open',
                onSelect = function()
                    ExitHouse(house)
                end
            }
        }
    })
    table.insert(currentZones, exitZone)

    for i, spot in ipairs(house.lootSpots) do
        local zone = exports.ox_target:addSphereZone({
            coords = vec3(spot.x, spot.y, spot.z),
            radius = 1.0,
            options = {
                {
                    name = 'search_spot_' .. i,
                    label = 'Przeszukaj',
                    icon = 'fas fa-search',
                    canInteract = function()
                        return not house.searchedSpots[i]
                    end,
                    onSelect = function()
                        SearchSpot(i, house)
                    end
                }
            }
        })
        table.insert(currentZones, zone)
    end
end

function SearchSpot(spotId, house)
    if lib.progressBar({
        duration = Config.SearchSettings.duration,
        label = 'Przeszukiwanie...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = Config.SearchSettings.animation.dict,
            clip = Config.SearchSettings.animation.clip
        }
    }) then
        house.searchedSpots[spotId] = true
        local loot = GenerateLoot()

        if loot then
            lib.callback('snaily-houserobbery:addItem', false, function(success)
                if success then
                    lib.notify({
                        title = 'Znaleziono!',
                        description = 'Znalazłeś: ' .. loot.label .. ' x' .. loot.amount,
                        type = 'success'
                    })

                    CheckRobberyCompletion(house)
                end
            end, loot.item, loot.amount)
        else
            lib.notify({
                title = 'Puste',
                description = 'Nic tu nie ma...',
                type = 'error'
            })
        end
    end
end

function GenerateLoot()
    local multiplier = Config.RobberyLevels[playerLevel].lootMultiplier

    for _, item in ipairs(Config.PossibleLoot) do
        if math.random(100) <= item.chance then
            local baseAmount = math.random(item.minAmount, item.maxAmount)
            local finalAmount = math.ceil(baseAmount * multiplier)

            return {
                item = item.item,
                amount = finalAmount,
                label = item.label
            }
        end
    end
    return nil
end

function CheckRobberyCompletion(house)
    local allSearched = true
    for i = 1, #house.lootSpots do
        if not house.searchedSpots[i] then
            allSearched = false
            break
        end
    end

    if allSearched then
        lib.callback('snaily-houserobbery:completeRobbery', false, function(success, newLevel, newRobberies, leveledUp)
            if success then
                playerLevel = newLevel
                playerRobberies = newRobberies

                if leveledUp then
                    lib.notify({
                        title = 'Awans!',
                        description = 'Osiągnąłeś poziom ' .. newLevel,
                        type = 'success'
                    })
                end
            end
        end)
    end
end

function ClearSearchZones()
    for _, zone in ipairs(currentZones) do
        exports.ox_target:removeZone(zone)
    end
    currentZones = {}
end

function ExitHouse(house)
    DoScreenFadeOut(1000)
    Wait(1000)

    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, house.robberyStartPoint.x, house.robberyStartPoint.y, house.robberyStartPoint.z)
    SetEntityHeading(playerPed, house.robberyStartPoint.w)

    ClearSearchZones()
    if currentPed and DoesEntityExist(currentPed) then
        DeleteEntity(currentPed)
    end

    currentMission = nil
    noiseLevel = 0

    if missionBlip then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end

    DoScreenFadeIn(1000)
end

function CreatePawnShopNPC()
    lib.requestModel(Config.PawnShop.npc.model)

    local ped = CreatePed(4, Config.PawnShop.npc.model,
        Config.PawnShop.npc.coords.x,
        Config.PawnShop.npc.coords.y,
        Config.PawnShop.npc.coords.z - 1.0,
        Config.PawnShop.npc.coords.w,
        false, true)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if Config.PawnShop.npc.scenario then
        TaskStartScenarioInPlace(ped, Config.PawnShop.npc.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'pawnshop_dealer',
            label = 'Porozmawiaj z handlarzem',
            icon = 'fas fa-hand-holding-dollar',
            onSelect = function()
                OpenPawnShopMenu()
            end
        }
    })
end

function OpenPawnShopMenu()
    lib.registerContext({
        id = 'pawnshop_menu',
        title = 'Lombard',
        options = {
            {
                title = 'Sprzedaj przedmioty',
                description = 'Sprzedaj skradzione przedmioty',
                icon = 'fas fa-dollar-sign',
                onSelect = function()
                    OpenSellMenu()
                end
            },
            {
                title = 'Informacje o cenach',
                description = 'Sprawdź aktualne ceny skupu',
                icon = 'fas fa-info-circle',
                onSelect = function()
                    ShowPriceList()
                end
            }
        }
    })

    lib.showContext('pawnshop_menu')
end

function OpenSellMenu()
    local options = {}
    local inventory = lib.callback.await('snaily-houserobbery:getPlayerInventory', false)

    for _, item in pairs(inventory) do
        if Config.PawnShop.prices[item.name] then
            table.insert(options, {
                title = Config.PawnShop.prices[item.name].label,
                description = ('Cena: $%s | Posiadane: x%s'):format(
                    Config.PawnShop.prices[item.name].price,
                    item.count
                ),
                icon = 'fas fa-box',
                onSelect = function()
                    local input = lib.inputDialog('Sprzedaż przedmiotów', {
                        {
                            type = 'number',
                            label = 'Ilość',
                            description = 'Ile sztuk chcesz sprzedać?',
                            default = 1,
                            min = 1,
                            max = item.count,
                            required = true
                        }
                    })

                    if input then
                        local amount = input[1]
                        SellItems(item.name, amount)
                    end
                end
            })
        end
    end

    if #options == 0 then
        lib.notify({
            title = 'Lombard',
            description = 'Nie masz żadnych przedmiotów na sprzedaż',
            type = 'error'
        })
        return
    end

    lib.registerContext({
        id = 'pawnshop_sell_menu',
        title = 'Sprzedaż przedmiotów',
        menu = 'pawnshop_menu',
        options = options
    })

    lib.showContext('pawnshop_sell_menu')
end

function ShowPriceList()
    local options = {}

    for item, data in pairs(Config.PawnShop.prices) do
        table.insert(options, {
            title = data.label,
            description = ('Cena skupu: $%s'):format(data.price),
            icon = 'fas fa-tag'
        })
    end

    lib.registerContext({
        id = 'pawnshop_prices',
        title = 'Lista cen',
        menu = 'pawnshop_menu',
        options = options
    })

    lib.showContext('pawnshop_prices')
end

function SellItems(item, amount)
    lib.callback('snaily-houserobbery:sellItems', false, function(success, money)
        if success then
            lib.notify({
                title = 'Lombard',
                description = ('Sprzedano przedmioty za $%s'):format(money),
                type = 'success'
            })
        else
            lib.notify({
                title = 'Lombard',
                description = 'Wystąpił błąd podczas sprzedaży',
                type = 'error'
            })
        end
    end, item, amount)
end

CreateThread(function()
    Wait(1000)
    CreateMissionPed()
    CreatePawnShopNPC()

    local pawnBlip = AddBlipForCoord(
        Config.PawnShop.npc.coords.x,
        Config.PawnShop.npc.coords.y,
        Config.PawnShop.npc.coords.z
    )
    SetBlipSprite(pawnBlip, Config.Blip.pawnshop.sprite)
    SetBlipColour(pawnBlip, Config.Blip.pawnshop.color)
    SetBlipScale(pawnBlip, Config.Blip.pawnshop.scale)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blip.pawnshop.label)
    EndTextCommandSetBlipName(pawnBlip)
end)
