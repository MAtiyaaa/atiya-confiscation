QBCore = exports['qb-core']:GetCoreObject()

Citizen.CreateThread(function()
    for _, pedConfig in pairs(Config.Peds) do
        local pedModel = GetHashKey(pedConfig.model)
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Wait(1)
        end

        local ped = CreatePed(4, pedModel, pedConfig.location.x, pedConfig.location.y, pedConfig.location.z, pedConfig.location.w, false, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)

        local interactionOptions = {
            {
                event = 'qb-policelockers:client:RequestOpenLocker',
                icon = 'fas fa-box-open',
                label = 'Open Locker',
            }
        }

        if pedConfig.useQbTarget then
            exports['qb-target']:AddTargetEntity(ped, {
                options = interactionOptions,
                distance = 2.0
            })
        else
            exports['ox_target']:AddEntityZone('policelocker_' .. pedConfig.model, ped, {
                name = 'policelocker_' .. pedConfig.model,
                debugPoly = false,
                useZ = true
            }, {
                options = interactionOptions,
                distance = 2.0
            })
        end
    end
end)

RegisterNetEvent('qb-policelockers:client:RequestOpenLocker', function()
    local Player = QBCore.Functions.GetPlayerData()
    TriggerServerEvent('qb-policelockers:server:CheckLockerStatus', Player.citizenid)
end)

RegisterNetEvent('qb-policelockers:client:LockerStatus', function(isLocked, remainingTime)
    if isLocked then
        QBCore.Functions.Notify('Locker is locked for ' .. remainingTime .. ' more minutes.', 'error')
    else
        TriggerServerEvent('qb-policelockers:server:OpenLocker', QBCore.Functions.GetPlayerData().citizenid)
    end
end)
