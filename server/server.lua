QBCore = exports['qb-core']:GetCoreObject()

local lockers = {}
local lockerTimers = {}

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

local function createLocker(citizenId)
    local locker = getLocker(citizenId)
    if not locker then
        local lockerId = 'locker-' .. citizenId
        local lockerLabel = 'Locker - ' .. citizenId
        local slots = Config.Locker.slots
        local maxWeight = Config.Locker.maxWeight
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

QBCore.Commands.Add(Config.Commands.openLocker.name, Config.Commands.openLocker.description, {{name = Config.Commands.openLocker.usage, help = 'Enter Player ID or CID'}}, true, function(source, args)   
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local targetId = args[1]
    local isAdmin = QBCore.Functions.HasPermission(source, 'admin')
    local isAllowedToUnlock = Config.Unlocking.adminCanUnlock and isAdmin

    if Player and hasAccess(Player, targetId) or isAllowedToUnlock then
        local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetId) or QBCore.Functions.GetPlayer(tonumber(targetId))
        if targetPlayer then
            local citizenId = targetPlayer.PlayerData.citizenid
            local locker = createLocker(citizenId)
            if not lockerTimers[citizenId] or lockerTimers[citizenId] <= os.time() then
                if Config.Inventory == 'QB' then
                    TriggerClientEvent('qb-policelockers:client:open-locker-custom', src, locker.id)
                elseif Config.Inventory == 'OX' then
                    exports.ox_inventory:forceOpenInventory(src, 'stash', locker.id)
                end
            else
                TriggerClientEvent('QBCore:Notify', src, 'This locker is currently locked.', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You are not authorized!', 'error')
    end
end, false)
QBCore.Commands.Add(Config.Commands.lockLocker.name, Config.Commands.lockLocker.description, {
    {name = 'ID/CitizenID', help = 'Enter the player\'s server ID or CitizenID'},
    {name = 'Minutes', help = 'How many minutes should the locker stay locked'}
    }, true, function(source, args)
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
end, false)

QBCore.Commands.Add(Config.Commands.unlockLocker.name, Config.Commands.unlockLocker.description, {{name = 'id', help = Config.Commands.unlockLocker.usage}}, true, function(source, args)
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
end, false)

RegisterNetEvent('qb-policelockers:server:CheckLockerStatus', function(citizenId)
    local src = source
    local locker = createLocker(citizenId)
    if locker then
        if lockerTimers[citizenId] and lockerTimers[citizenId] > os.time() then
            local remainingTime = math.ceil((lockerTimers[citizenId] - os.time()) / 60)
            TriggerClientEvent('qb-policelockers:client:LockerStatus', src, true, remainingTime)
        else
            if Config.Inventory == 'QB' then
                TriggerClientEvent('qb-policelockers:client:open-locker-custom', src, locker.id)
            elseif Config.Inventory == 'OX' then
                exports.ox_inventory:forceOpenInventory(src, 'stash', locker.id)
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Your locker is empty', 'error')
    end
end)


RegisterNetEvent('qb-policelockers:server:OpenLocker', function(citizenId)
    local src = source
    if lockerTimers[citizenId] and lockerTimers[citizenId] > os.time() then
        local remainingTime = math.ceil((lockerTimers[citizenId] - os.time()) / 60)
        TriggerClientEvent('qb-policelockers:client:LockerStatus', src, true, remainingTime)
        return
    end
    local locker = createLocker(citizenId)
    if locker then
        if Config.Inventory == 'QB' then
            TriggerClientEvent('qb-policelockers:client:open-locker-custom', src, locker.id)
        elseif Config.Inventory == 'OX' then
            exports.ox_inventory:forceOpenInventory(src, 'stash', locker.id)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Your locker is empty', 'error')
    end
end)
