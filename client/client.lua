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

        if pedConfig.useQbTarget then
            exports['qb-target']:AddTargetEntity(ped, {
                options = {
                    {
                        event = 'qb-policelockers:client:OpenLocker',
                        icon = 'fas fa-box-open',
                        label = 'Open Locker',
                    }
                },
                distance = 2.0
            })
        else
            exports['ox_target']:AddEntityZone('policelocker_' .. pedConfig.model, ped, {
                name='policelocker_' .. pedConfig.model,
                debugPoly=false,
                useZ=true
                }, {
                    options = {
                        {
                            event = 'qb-policelockers:client:OpenLocker',
                            icon = 'fas fa-box-open',
                            label = 'Open Locker',
                        }
                    },
                    distance = 2.0
                }
            )
        end
    end
end)

RegisterNetEvent('qb-policelockers:client:OpenLocker', function()
    local Player = QBCore.Functions.GetPlayerData()
    TriggerServerEvent('qb-policelockers:server:OpenLocker', Player.citizenid)
end)
