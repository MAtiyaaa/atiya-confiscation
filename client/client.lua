QBCore = exports['qb-core']:GetCoreObject()

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
                event = 'qb-confiscation:client:RequestOpenLocker',
                icon = 'fas fa-lock',
                label = 'Open Locker',
            },
        }

        if Config.Target == 'QB' then
            exports['qb-target']:AddTargetEntity(ped, {
                options = interactionOptions,
                distance = 2.0
            })
        elseif Config.Target == 'OX' then
            exports['qb-target']:AddTargetEntity(ped, {
                options = interactionOptions,
                distance = 2.0
            })
        elseif Config.Target == '3D' then
            Citizen.CreateThread(function()
                while true do
                    Citizen.Wait(0)
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    for _, v in pairs(Config.Peds) do
                        local distance = #(playerCoords - vector3(v.location.x, v.location.y, v.location.z))
                        
                        if distance < 2.5 then
                            DrawText3Ds(v.location.x, v.location.y, v.location.z + 1.0, "Press ~r~[E]~s~ to Open ~y~Locker~s~")
                            if IsControlJustReleased(0, 38) then
                                TriggerEvent('qb-confiscation:client:RequestOpenLocker')
                            end
                        end
                    end
                end
            end)
        end
    end

    for _, locationConfig in pairs(Config.InputMenu.locations) do
        if Config.InputMenu.Enabled then
            local jobs = Config.AccessControl.jobName

            local interactionOptions = {}

            for _, job in pairs(jobs) do
                table.insert(interactionOptions, {
                    event = 'qb-confiscation:client:locker-input',
                    icon = 'fas fa-key',
                    label = 'Open a Player\'s Locker',
                    job = job,
                })
            end

            if Config.Target == 'QB' then
                exports['qb-target']:AddBoxZone("locker-input", locationConfig.coords, 2, 2, {
                    name = "locker-input",
                    heading = 0,
                    debugPoly = false,
                    minZ = locationConfig.coords.z - 1,
                    maxZ = locationConfig.coords.z + 1,
                }, {
                    options = interactionOptions,
                    distance = 2.0,
                })
            elseif Config.Target == 'OX' then
                exports['qb-target']:AddBoxZone("locker-input", locationConfig.coords, 2, 2, {
                    name = "locker-input",
                    heading = 0,
                    debugPoly = false,
                    minZ = locationConfig.coords.z - 1,
                    maxZ = locationConfig.coords.z + 1,
                }, {
                    options = interactionOptions,
                    distance = 2.0,
                })
            elseif Config.Target == '3D' then
                Citizen.CreateThread(function()
                    while true do
                        Citizen.Wait(0)
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        for _, location in pairs(Config.InputMenu.locations) do
                            local distance = #(playerCoords - location.coords)

                            if distance < 2.5 then
                                DrawText3Ds(location.coords.x, location.coords.y, location.coords.z + 1.0, "Press ~r~[E]~s~ to open a player's locker")
                                if IsControlJustReleased(0, 38) then
                                    TriggerEvent('qb-confiscation:client:locker-input')
                                end
                            end
                        end
                    end
                end)
            end
        else
            return
        end
    end
end)

RegisterNetEvent('qb-confiscation:client:locker-input', function()
    local inputMethod = Config.InputMenu.method
    local inputResult = nil

    if inputMethod == 'QB' then
        inputResult = exports['qb-input']:ShowInput({
            header = 'Locker Management',
            submitText = 'Submit',
            inputs = {
                {
                    type = 'select',
                    isRequired = true,
                    name = 'action',
                    text = 'Select Action',
                    options = {
                        { value = 'open', text = 'Open Locker' },
                        { value = 'lock', text = 'Lock Locker' },
                        { value = 'unlock', text = 'Unlock Locker' },
                    },
                },
            },
        })
        
        if not inputResult then
            TriggerEvent('QBCore:Notify', 'No valid action selected.', 'error')
            return
        end
        
        local action = inputResult["action"]
        
        if action == 'lock' then
            local lockResult = exports['qb-input']:ShowInput({
                header = 'Lock Locker',
                submitText = 'Lock',
                inputs = {
                    {
                        type = 'text',
                        isRequired = true,
                        name = 'targetId',
                        text = 'Enter Player ID or Citizen ID',
                    },
                    {
                        type = 'number',
                        isRequired = true,
                        name = 'lockDuration',
                        text = 'Lock Duration (in minutes)',
                    },
                },
            })
            
            if not lockResult then
                TriggerEvent('QBCore:Notify', 'No valid input for locking.', 'error')
                return
            end
            
            local targetId = lockResult["targetId"]
            local lockDuration = tonumber(lockResult["lockDuration"])
            
            if not targetId or targetId == "" then
                TriggerEvent('QBCore:Notify', 'No valid ID entered.', 'error')
                return
            end
            
            TriggerServerEvent('qb-confiscation:server:lockLocker', targetId, lockDuration)
        
        elseif action == 'unlock' then
            local unlockResult = exports['qb-input']:ShowInput({
                header = 'Unlock Locker',
                submitText = 'Unlock',
                inputs = {
                    {
                        type = 'text',
                        isRequired = true,
                        name = 'targetId',
                        text = 'Enter Player ID or Citizen ID',
                    },
                },
            })
            
            if not unlockResult then
                TriggerEvent('QBCore:Notify', 'No valid input for unlocking.', 'error')
                return
            end
            
            local targetId = unlockResult["targetId"]
            
            if not targetId or targetId == "" then
                TriggerEvent('QBCore:Notify', 'No valid ID entered.', 'error')
                return
            end
            
            TriggerServerEvent('qb-confiscation:server:unlockLocker', targetId)
        
        elseif action == 'open' then
            local openResult = exports['qb-input']:ShowInput({
                header = 'Open Locker',
                submitText = 'Open',
                inputs = {
                    {
                        type = 'text',
                        isRequired = true,
                        name = 'targetId',
                        text = 'Enter Player ID or Citizen ID',
                    },
                },
            })
            
            if not openResult then
                TriggerEvent('QBCore:Notify', 'No valid input for opening.', 'error')
                return
            end
            
            local targetId = openResult["targetId"]
            
            if not targetId or targetId == "" then
                TriggerEvent('QBCore:Notify', 'No valid ID entered.', 'error')
                return
            end
            
            TriggerServerEvent('qb-confiscation:server:OpenLocker', targetId)
        end
    
    elseif inputMethod == 'OX' and GetResourceState('ox_lib') == 'started' then
        local baseInput = lib.inputDialog('Locker Management', {
            {
                type = 'select',
                label = 'Select Action',
                options = {
                    { value = 'Open', text = 'Open Locker' },
                    { value = 'Lock', text = 'Lock Locker' },
                    { value = 'Unlock', text = 'Unlock Locker' },
                },
            },
        })
        
        if not baseInput then
            TriggerEvent('QBCore:Notify', 'No valid action selected.', 'error')
            return
        end
        
        local action = baseInput[1]
        
        if action == 'Lock' then
            local lockInput = lib.inputDialog('Lock Locker', {
                {
                    type = 'input',
                    label = 'Enter Player ID or Citizen ID',
                    required = true,
                },
                {
                    type = 'number',
                    label = 'Lock Duration (in minutes)',
                    required = true,
                },
            })
            
            if not lockInput then
                TriggerEvent('QBCore:Notify', 'No valid input for locking.', 'error')
                return
            end
            
            local targetId = lockInput[1]
            local lockDuration = tonumber(lockInput[2])
            
            if not targetId or targetId == "" then
                TriggerEvent('QBCore:Notify', 'No valid ID entered.', 'error')
                return
            end
            
            TriggerServerEvent('qb-confiscation:server:lockLocker', targetId, lockDuration)
        
        elseif action == 'Unlock' then
            local unlockInput = lib.inputDialog('Unlock Locker', {
                {
                    type = 'input',
                    label = 'Enter Player ID or Citizen ID',
                    required = true,
                },
            })
            
            if not unlockInput then
                TriggerEvent('QBCore:Notify', 'No valid input for unlocking.', 'error')
                return
            end
            
            local targetId = unlockInput[1]
            
            if not targetId or targetId == "" then
                TriggerEvent('QBCore:Notify', 'No valid ID entered.', 'error')
                return
            end
            
            TriggerServerEvent('qb-confiscation:server:unlockLocker', targetId)
        
        elseif action == 'Open' then
            local openInput = lib.inputDialog('Open Locker', {
                {
                    type = 'input',
                    label = 'Enter Player ID or Citizen ID',
                    required,
                },
            })
            
            if not openInput then
                TriggerEvent('QBCore:Notify', 'No valid input for opening.', 'error')
                return
            end
            
            local targetId = openInput[1]
            
            if not targetId or targetId == "" then
                TriggerEvent('QBCore:Notify', 'No valid ID entered.', 'error')
                return
            end
            
            TriggerServerEvent('qb-confiscation:server:OpenLocker', targetId)
        end
    end
end)

RegisterNetEvent('qb-confiscation:client:RequestOpenLocker', function()
    local Player = QBCore.Functions.GetPlayerData()
    TriggerServerEvent('qb-confiscation:server:CheckLockerStatus', Player.citizenid)
end)

RegisterNetEvent('qb-confiscation:client:LockerStatus', function(isLocked, remainingTime)
    if isLocked then
        QBCore.Functions.Notify('Locker is locked for ' .. remainingTime .. ' more minutes.', 'error')
    else
        TriggerServerEvent('qb-confiscation:server:OpenLocker', QBCore.Functions.GetPlayerData().citizenid)
    end
end)

RegisterNetEvent('qb-confiscation:client:open-locker-custom', function(lockerId)
    TriggerServerEvent('inventory:server:OpenInventory', 'stash', lockerId)
    TriggerEvent('inventory:client:SetCurrentStash', lockerId)
end)

function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 500
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 80)
end
