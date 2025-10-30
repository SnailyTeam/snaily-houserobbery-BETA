local function LoadPlayerData()
    local file = LoadResourceFile(GetCurrentResourceName(), 'snaily-houserobberyData.json')
    if file then
        return json.decode(file) or {}
    end
    local defaultData = {}
    SaveResourceFile(GetCurrentResourceName(), 'snaily-houserobberyData.json', json.encode(defaultData), -1)
    return defaultData
end

local function SavePlayerData(data)
    if not data then data = {} end
    SaveResourceFile(GetCurrentResourceName(), 'snaily-houserobberyData.json', json.encode(data), -1)
end

local function GetPlayerData(identifier)
    local data = LoadPlayerData()
    if not data[identifier] then
        data[identifier] = {
            level = 1,
            robberies = 0,
            lastRobbery = 0
        }
        SavePlayerData(data)
    end
    return data[identifier]
end

local function CountPolice()
    local count = 0
    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.job.name == 'police' then
            count = count + 1
        end
    end
    return count
end

lib.callback.register('snaily-houserobbery:getPlayerData', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local playerData = GetPlayerData(identifier)

    return playerData.level, playerData.robberies
end)

lib.callback.register('snaily-houserobbery:checkItem', function(source, item, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local itemCount = xPlayer.getInventoryItem(item).count
    return itemCount >= amount
end)

RegisterNetEvent('snaily-houserobbery:removeItem', function(item, count)
    local source = source
    exports.ox_inventory:RemoveItem(source, item, count)
end)

lib.callback.register('snaily-houserobbery:canStartMission', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local data = LoadPlayerData()

    if Config.Settings.EnablePoliceAlerts and CountPolice() < Config.Settings.MinimumPolice then
        return false, -1
    end

    if not data[identifier] then
        data[identifier] = {
            level = 1,
            robberies = 0,
            lastRobbery = 0
        }
    end

    local currentTime = os.time()
    local lastRobbery = data[identifier].lastRobbery or 0
    local timeDiff = currentTime - lastRobbery

    if timeDiff < Config.Settings.Cooldown then
        return false, Config.Settings.Cooldown - timeDiff
    end

    data[identifier].lastRobbery = currentTime
    SavePlayerData(data)

    return true, 0
end)

lib.callback.register('snaily-houserobbery:completeRobbery', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local data = LoadPlayerData()

    if not data[identifier] then return false end

    data[identifier].robberies = data[identifier].robberies + 1

    local nextLevel = data[identifier].level + 1
    local leveledUp = false

    if nextLevel <= Config.Settings.MaxLevel and Config.RobberyLevels[nextLevel] and
       data[identifier].robberies >= Config.RobberyLevels[nextLevel].requiredRobberies then
        data[identifier].level = nextLevel
        leveledUp = true
    end

    SavePlayerData(data)
    return true, data[identifier].level, data[identifier].robberies, leveledUp
end)

lib.callback.register('snaily-houserobbery:addItem', function(source, item, amount)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.canCarryItem(item, amount) then
        xPlayer.addInventoryItem(item, amount)
        return true
    end
    return false
end)

lib.callback.register('snaily-houserobbery:getPlayerInventory', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local items = {}
    local inventory = xPlayer.getInventory()

    for _, item in pairs(inventory) do
        if item.count > 0 and Config.PawnShop.prices[item.name] then
            table.insert(items, {
                name = item.name,
                label = Config.PawnShop.prices[item.name].label,
                count = item.count
            })
        end
    end

    return items
end)

lib.callback.register('snaily-houserobbery:sellItems', function(source, item, amount)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not Config.PawnShop.prices[item] then return false end

    local itemCount = xPlayer.getInventoryItem(item).count
    if itemCount < amount then return false end

    local price = Config.PawnShop.prices[item].price * amount
    xPlayer.removeInventoryItem(item, amount)
    xPlayer.addMoney(price)

    return true, price
end)

lib.callback.register('snaily-houserobbery:alertPolice', function(source, coords)
    if not Config.Settings.EnablePoliceAlerts then return true end

    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.job.name == 'police' then
            TriggerClientEvent('snaily-houserobbery:policeAlert', xPlayers[i], coords)
        end
    end
    return true
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    local playerData = GetPlayerData(identifier)

    TriggerClientEvent('snaily-houserobbery:initializeData', source, playerData.level, playerData.robberies)
end)
