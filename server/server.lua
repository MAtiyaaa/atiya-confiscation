QBCore = exports['qb-core']:GetCoreObject()

local lockers = {}
local lockerTimers = {}
MySQL = exports.oxmysql

local function saveLockerTimes()
    local timeData = {}
    for cid, timeLocked in pairs(lockerTimers) do
        timeData[cid] = timeLocked
    end

    local file = io.open('lockerTimes.json', 'w')
    if file then
        file:write(json.encode(timeData))
        file:close()
    end
end


local function loadLockerTimes()
    local file = io.open('lockerTimes.json', 'r')
    if file then
        local data = file:read('*a')
        file:close()
        lockerTimers = json.decode(data) or {}
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        loadLockerTimes()
    end
end)

local function getLocker(citizenId)
    return lockers[citizenId]
end

local function hasAccess(player, citizenId)
    local jobName = player.PlayerData.job.name
    local isAuthorizedJob = false

    if Config.AccessControl.checkType == 'job' then
        for _, allowedJob in ipairs(Config.AccessControl.jobName) do
            if jobName == allowedJob then
                isAuthorizedJob = true
                break
            end
        end
    elseif Config.AccessControl.checkType == 'type' then
        isAuthorizedJob = player.PlayerData.job.type == Config.AccessControl.jobName
    end

    local isLockerLocked = lockerTimers[citizenId] and lockerTimers[citizenId] > os.time()

    return isAuthorizedJob and not isLockerLocked
end

RegisterNetEvent('qb-confiscation:server:checkAccess', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        local serverHasAccess = hasAccess(Player, Player.PlayerData.citizenid)
        TriggerClientEvent('qb-confiscation:client:checkAccessResult', src, serverHasAccess)
    end
end)


local function createLocker(citizenId)
    local locker = getLocker(citizenId)
    if not locker then
        local lockerId = 'locker-' .. citizenId
        local lockerLabel = 'Locker - ' .. citizenId
        local slots = Config.Locker.slots
        local maxWeight = Config.Locker.weight
        locker = { id = lockerId, label = lockerLabel, slots = slots, weight = maxWeight, owner = citizenId }
        lockers[citizenId] = locker

        if Config.Inventory == 'OX' then
            exports.ox_inventory:RegisterStash(lockerId, lockerLabel, slots, maxWeight, citizenId)
        else
            return locker
        end
    end
    return locker
end

QBCore.Commands.Add(Config.Commands.openLocker.name, Config.Commands.openLocker.description, {}, true, function(source, args)

    if Config.Commands.openLocker.enabled then
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local targetId = args[1]

        if not Player then
            TriggerClientEvent('QBCore:Notify', src, 'You are not authorized!', 'error')
            return
        end

        if Config.Commands.openLocker.locationOnly then
            local playerCoords = GetEntityCoords(GetPlayerPed(src))
            local isInAllowedLocation = false

            for _, location in ipairs(Config.Commands.openLocker.locations) do
                if #(playerCoords - location.coords) <= location.radius then
                    isInAllowedLocation = true
                    break
                end
            end

            if not isInAllowedLocation then
                TriggerClientEvent('QBCore:Notify', src, 'This command can only be used in specific locations.', 'error')
                return
            end
        end

        local isAdmin = QBCore.Functions.HasPermission(src, 'admin')

        if Player and hasAccess(Player, targetId) or isAdmin then
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetId) or QBCore.Functions.GetPlayer(tonumber(targetId))

            if not targetPlayer or not targetPlayer.PlayerData or not targetPlayer.PlayerData.citizenid then
                TriggerClientEvent('QBCore:Notify', src, 'Player not found or missing citizen ID.', 'error')
                return
            end

            local citizenId = targetPlayer.PlayerData.citizenid
            local lockerId = 'Locker ' .. citizenId
            local locker = createLocker(citizenId)

            if not lockerTimers[citizenId] or lockerTimers[citizenId] <= os.time() then
                if Config.Inventory == 'QB' then
                    TriggerClientEvent('qb-confiscation:client:open-locker-custom', src, lockerId)
                elseif Config.Inventory == 'OX' then
                    exports.ox_inventory:forceOpenInventory(src, 'stash', locker.id)
                end
            else
                TriggerClientEvent('QBCore:Notify', src, 'This locker is currently locked.', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'You are not authorized!', 'error')
        end
    else
        return
    end
end, false)

QBCore.Commands.Add(Config.Commands.lockLocker.name, Config.Commands.lockLocker.description, {
    {name = 'ID/CitizenID', help = 'Enter the player\'s server ID or CitizenID'},
    {name = 'Minutes', help = 'How many minutes should the locker stay locked'}
    }, true, function(source, args)
    if Config.Commands.lockLocker.enabled then
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local targetId = args[1]
        local lockDuration = tonumber(args[2])
        local isAdmin = QBCore.Functions.HasPermission(source, 'admin')
        local isAllowedToUnlock = Config.Unlocking.adminCanUnlock and isAdmin

        if Player and hasAccess(Player, targetId) or isAllowedToUnlock then
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetId) or QBCore.Functions.GetPlayer(tonumber(targetId))
            if targetPlayer and lockDuration and lockDuration > 0 then
                local citizenId = targetPlayer.PlayerData.citizenid
                lockerTimers[citizenId] = os.time() + (lockDuration * 60)
                saveLockerTimes()          
                TriggerClientEvent('QBCore:Notify', src, 'Locker is locked for ' .. lockDuration .. ' minutes', 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Invalid parameters', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'You are not authorized!', 'error')
        end
    else
        return
    end
end, false)

QBCore.Commands.Add(Config.Commands.unlockLocker.name, Config.Commands.unlockLocker.description, {{name = 'id', help = Config.Commands.unlockLocker.usage}}, true, function(source, args)
    if Config.Commands.unlockLocker.enabled then
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local targetId = args[1]
        local lockDuration = tonumber(args[2])
        local isAdmin = QBCore.Functions.HasPermission(source, 'admin')
        local isAllowedToUnlock = Player.PlayerData.job.grade.level >= Config.Unlocking.allowedGrade or (Config.Unlocking.adminCanUnlock and isAdmin)

        if Player and hasAccess(Player, targetId) and isAllowedToUnlock then
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetId) or QBCore.Functions.GetPlayer(tonumber(targetId))
            if targetPlayer then
                local citizenId = targetPlayer.PlayerData.citizenid
                lockerTimers[citizenId] = os.time() + (0 * 60)
                saveLockerTimes()
                TriggerClientEvent('QBCore:Notify', src, 'Locker has been unlocked.', 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'This locker is not currently locked.', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'You are not authorized!', 'error')
        end
    else
        return
    end
end, false)

RegisterNetEvent('qb-confiscation:server:lockLocker', function(targetId, lockDuration)
    local src = source
    local citizenId
    
    if tonumber(targetId) then
        local targetPlayer = QBCore.Functions.GetPlayer(tonumber(targetId))
        if targetPlayer then
            citizenId = targetPlayer.PlayerData.citizenid
        end
    else
        citizenId = targetId
    end
    
    if not citizenId then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid ID or Citizen ID.', 'error')
        return
    end
    
    lockerTimers[citizenId] = os.time() + (lockDuration * 60)
    saveLockerTimes()
    
    TriggerClientEvent('QBCore:Notify', src, 'Locker locked for ' .. lockDuration .. ' minutes.', 'success')
end)

RegisterNetEvent('qb-confiscation:server:unlockLocker', function(targetId)
    local src = source
    local citizenId
    
    if tonumber(targetId) then
        local targetPlayer = QBCore.Functions.GetPlayer(tonumber(targetId))
        if targetPlayer then
            citizenId = targetPlayer.PlayerData.citizenid
        end
    else
        citizenId = targetId
    end
    
    if not citizenId then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid ID or Citizen ID.', 'error')
        return
    end
    
    lockerTimers[citizenId] = 0
    saveLockerTimes()
    
    TriggerClientEvent('QBCore:Notify', src, 'Locker unlocked.', 'success')
end)


RegisterNetEvent('qb-confiscation:server:CheckLockerStatus', function(citizenId)
    local src = source
    local locker = createLocker(citizenId)
    local lockerId = 'Locker ' .. citizenId
    if locker then
        if lockerTimers[citizenId] and lockerTimers[citizenId] > os.time() then
            local remainingTime = math.ceil((lockerTimers[citizenId] - os.time()) / 60)
            TriggerClientEvent('qb-confiscation:client:LockerStatus', src, true, remainingTime)
        else
            if Config.Inventory == 'QB' then
                TriggerClientEvent('qb-confiscation:client:open-locker-custom', src, lockerId)
            elseif Config.Inventory == 'OX' then
                exports.ox_inventory:forceOpenInventory(src, 'stash', locker.id)
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Your locker is empty', 'error')
    end
end)

RegisterNetEvent('qb-confiscation:confiscateItems', function(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then
        -- print("Player not found with ID: " .. playerId)
        return
    end
    if Config.Inventory == 'QB' then
        local itemsProcessedQB = false
        
        local shouldProcessItem = function(itemName)
            local item = string.lower(itemName)
            local isInList = table.contains(Config.Confiscation.Items, item)
            if Config.Confiscation.Mode == 'blacklist' then
                return isInList
            else
                return not isInList
            end
        end
        
        for _, itemData in pairs(Player.PlayerData.items) do
            if itemData and itemData.amount > 0 and shouldProcessItem(itemData.name) then
                Player.Functions.RemoveItem(itemData.name, itemData.amount, itemData.slot)
                AddToLockerForQB(Player.PlayerData.citizenid, itemData.name, itemData.amount, itemData.info)
                itemsProcessedQB = true
            end
        end
        
        if itemsProcessedQB then
            TriggerClientEvent('QBCore:Notify', playerId, 'Some of your items have been placed in your locker', 'error')
        end

    elseif Config.Inventory == 'OX' then
        if Player then
            local lockerId = 'locker-' .. Player.PlayerData.citizenid
            local lockerInventory = exports.ox_inventory:GetInventory(lockerId)
            local itemsProcessed = false

            for _, itemSlot in pairs(Player.PlayerData.items) do
                if itemSlot.name and itemSlot.count and itemSlot.count > 0 then
                    local item = string.lower(itemSlot.name)
                    local amount = itemSlot.count
                    local isInList = table.contains(Config.Confiscation.Items, item)

                    local shouldProcess = (Config.Confiscation.Mode == 'blacklist' and isInList) or
                                          (Config.Confiscation.Mode == 'whitelist' and not isInList)

                    if shouldProcess then
                        local canCarry = lockerInventory and exports.ox_inventory:CanCarryItem(lockerInventory, itemSlot.name, amount)
                        if canCarry then
                            itemsProcessed = true
                            Player.Functions.RemoveItem(itemSlot.name, amount)
                            AddToLocker(Player.PlayerData.citizenid, itemSlot.name, amount)
                        else
                            -- print("Not enough space in the locker to add " .. itemSlot.name)
                            TriggerClientEvent('QBCore:Notify', playerId, "Not enough space in your locker for " .. itemSlot.name, 'error')
                        end
                    end
                else
                    -- print("Invalid item data or count for item: " .. tostring(itemSlot.name))
                end
            end

            if itemsProcessed then
                TriggerClientEvent('QBCore:Notify', playerId, 'Some of your items have been placed in your locker', 'error')
            end
        end
    end
end)

function table.contains(table, element)
    for _, value in pairs(table) do
        if string.lower(value) == element then
            return true
        end
    end
    return false
end

RegisterNetEvent('qb-confiscation:server:OpenLocker', function(inputId)
    local src = source
    local citizenId

    if tonumber(inputId) then
        local targetPlayer = QBCore.Functions.GetPlayer(tonumber(inputId))
        if targetPlayer then
            citizenId = targetPlayer.PlayerData.citizenid
        end
    else
        citizenId = inputId
    end
    
    if not citizenId then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid ID or Citizen ID.', 'error')
        return
    end
    
    if lockerTimers[citizenId] and lockerTimers[citizenId] > os.time() then
        local remainingTime = math.ceil((lockerTimers[citizenId] - os.time()) / 60)
        TriggerClientEvent('qb-confiscation:client:LockerStatus', src, true, remainingTime)
        return
    end
    
    local locker = createLocker(citizenId)
    local lockerId = 'Locker ' .. citizenId
    
    if locker then
        if Config.Inventory == 'QB' then
            TriggerClientEvent('qb-confiscation:client:open-locker-custom', src, lockerId)
        elseif Config.Inventory == 'OX' then
            exports.ox_inventory:forceOpenInventory(src, 'stash', locker.id)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Your locker is empty', 'error')
    end
end)


function AddToLocker(citizenId, item, amount, metadata)
    local lockerId = 'locker-' .. citizenId
    local lockerLabel = 'Locker - ' .. citizenId

    local lockerInventory = exports.ox_inventory:GetInventory(lockerId, citizenId)
    if not lockerInventory then
        local slots = Config.Locker.slots
        local maxWeight = Config.Locker.weight
        exports.ox_inventory:RegisterStash(lockerId, lockerLabel, slots, maxWeight, citizenId)
        lockerInventory = { id = lockerId, owner = citizenId }
    end

    if not exports.ox_inventory:CanCarryItem(lockerInventory, item, amount) then
        -- print('Locker cannot carry more items')
        return
    end
    local success, response = exports.ox_inventory:AddItem(lockerId, item, amount)
    if not success then
        -- print('Failed to add item to locker:', response)
    end
end

function asyncUpdateStashItems(lockerId, items, callback)
    local updateQuery = 'UPDATE stashitems SET items = ? WHERE stash = ?'
    exports.oxmysql:execute_async(updateQuery, {json.encode(items), lockerId}, function(affectedRows)
        if callback then
            callback(affectedRows)
        end
    end)
end

function AddToLockerForQB(citizenId, item, amount, info)
    local lockerId = 'Locker ' .. citizenId
    local itemsJson = exports.oxmysql:scalar_async('SELECT items FROM stashitems WHERE stash = ?', { lockerId })
    local items = itemsJson and json.decode(itemsJson) or {}

    local itemData = QBCore.Shared.Items[item:lower()]
    if not itemData then
        -- print("Item data not found for item:", item)
        return
    end
    local metaInfo = info or {}

    if itemData.type == 'weapon' then
        metaInfo.serie = metaInfo.serie or tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
        metaInfo.quality = metaInfo.quality or 100

    elseif itemData.name == 'harness' then
        metaInfo.uses = metaInfo.uses or 20

    elseif itemData.name == 'markedbills' then
        metaInfo.worth = metaInfo.worth or math.random(5000,10000)

    elseif itemData.name == 'id_card' then
        metaInfo.citizenid = metaInfo.citizenid or Player.PlayerData.citizenid
        metaInfo.firstname = metaInfo.firstname or Player.PlayerData.charinfo.firstname
        metaInfo.lastname = metaInfo.lastname or Player.PlayerData.charinfo.lastname
        metaInfo.birthdate = metaInfo.birthdate or Player.PlayerData.charinfo.birthdate
        metaInfo.gender = metaInfo.gender or Player.PlayerData.charinfo.gender
        metaInfo.nationality = metaInfo.nationality or Player.PlayerData.charinfo.nationality

    elseif itemData.name == 'driver_license' then
        metaInfo.firstname = metaInfo.firstname or Player.PlayerData.charinfo.firstname
        metaInfo.lastname = metaInfo.lastname or Player.PlayerData.charinfo.lastname
        metaInfo.birthdate = metaInfo.birthdate or Player.PlayerData.charinfo.birthdate
        metaInfo.type = metaInfo.type or 'Class C Driver License'
    end

    local isUnique = itemData.unique

    if isUnique then
        for i = 1, amount do
            table.insert(items, {
                name = item,
                amount = 1,
                info = metaInfo,
                label = itemData.label,
                weight = itemData.weight,
                unique = true,
                slot = #items + 1
            })
        end
    else
        local found = false
        for i, lockerItem in ipairs(items) do
            if lockerItem.name == item and not lockerItem.unique then
                lockerItem.amount = lockerItem.amount + amount
                found = true
                break
            end
        end
        if not found then
            table.insert(items, {
                name = item,
                amount = amount,
                info = metaInfo,
                label = itemData.label,
                weight = itemData.weight,
                unique = false,
                slot = #items + 1
            })
        end
    end

    asyncUpdateStashItems(lockerId, items, function(response)
        if response and response > 0 then
            -- print('Items updated successfully in locker:', lockerId)
        else
            -- print('Failed to update items for locker:', lockerId)
        end
    end)
end
