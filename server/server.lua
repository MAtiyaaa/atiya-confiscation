QBCore = exports['qb-core']:GetCoreObject()

local lockers = {}
local function getLocker(citizenId)
    return lockers[citizenId]
end

local function hasAccess(player)
    if Config.AccessControl.checkType == 'job' then
        return player.PlayerData.job.name == Config.AccessControl.jobName
    elseif Config.AccessControl.checkType == 'type' then
        return player.PlayerData.job.type == Config.AccessControl.jobName
    end
    return false
end

local function createLocker(citizenId)
    local locker = getLocker(citizenId)
    if not locker then
        local lockerId = 'locker-' .. citizenId
        local lockerLabel = 'Locker - ' .. citizenId
        local slots = Config.Locker.slots
        local maxWeight = Config.Locker.maxWeight

        exports.ox_inventory:RegisterStash(lockerId, lockerLabel, slots, maxWeight, citizenId)

        locker = { id = lockerId, label = lockerLabel, slots = slots, weight = maxWeight, owner = citizenId }
        lockers[citizenId] = locker
    end
    return locker
end

QBCore.Commands.Add(Config.Command.name, Config.Command.description, {{name = Config.Command.usage, help = Config.Command.help}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and hasAccess(Player) then
        local targetId = args[1]
        if targetId then
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetId) or QBCore.Functions.GetPlayer(tonumber(targetId))
            if targetPlayer then
                local citizenId = targetPlayer.PlayerData.citizenid
                local locker = createLocker(citizenId)
                exports.ox_inventory:forceOpenInventory(src, 'stash', locker.id)
            else
                TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'No player ID provided', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You are not a police officer!', 'error')
    end
end, false)


RegisterNetEvent('qb-policelockers:server:OpenLocker', function(citizenId)
    local src = source
    local locker = getLocker(citizenId)
    if locker then
        exports.ox_inventory:forceOpenInventory(src, 'stash', locker.id)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Your locker is empty', 'error')
    end
end)
