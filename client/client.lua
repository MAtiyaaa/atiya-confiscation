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

        if pedConfig.animDict and pedConfig.animName then
            RequestAnimDict(pedConfig.animDict)
            while not HasAnimDictLoaded(pedConfig.animDict) do
                Wait(1)
            end
            TaskPlayAnim(ped, pedConfig.animDict, pedConfig.animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
        
        if pedConfig.prop then
            local propHash = GetHashKey(pedConfig.prop)
            RequestModel(propHash)
            while not HasModelLoaded(propHash) do
                Wait(1)
            end

            local prop = CreateObject(propHash, 0, 0, 0, true, true, true)
            AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, pedConfig.propBone), pedConfig.propPlacement.x, pedConfig.propPlacement.y, pedConfig.propPlacement.z, pedConfig.propRotation.x, pedConfig.propRotation.y, pedConfig.propRotation.z, true, true, false, true, 1, true)
        end

        local interactionOptions = {
            {
                event = 'qb-policelockers:client:RequestOpenLocker',
                icon = 'fas fa-lock',
                label = 'Open Locker',
            }
        }

        if Config.QBTarget then
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
