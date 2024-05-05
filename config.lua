Config = {}

Config.Commands = {
    openLocker = {
        enabled = true,  -- Option to enable/disable the command
        name = 'openlocker',  -- Name of the command
        description = 'Open a player\'s locker',  -- Command description
        usage = 'ID/CID',  -- Command usage        
        locationOnly = true,  -- Disable if you want to be able to use this command anywhere (not recommended to disable, exploitable)
        locations = {
            { coords = vector3(442.39, -981.911, 29.69), radius = 50.0 },  -- Only Works if locationOnly is set to true
            -- { coords = vector3(200.0, 300.0, 40.0), radius = 15.0 },
        },
    },
    lockLocker = {
        enabled = true,
        name = 'locklocker',
        description = 'Lock player\'s locker',
    },
    unlockLocker = {
        enabled = true,
        name = 'unlocklocker',
        description = 'Unlock player\'s locker',
        usage = 'ID/CID'
    }
}

Config.Inventory = 'QB' -- 'QB' for qb-inventory, 'OX' for ox_inventory
Config.Target = 'OX' -- 'QB' for qb-target, 'OX' for ox_target, '3D' for 3D Text

Config.InputMenu = {
    Enabled = true, -- Want a menu to insert a player id? You could use this, or the openLocker command, or both!
    method = 'QB', -- QB for qb-input, 'OX' for ox_lib
    locations = {
        { coords = vector3(444.51, -984.911, 30.00), radius = 10.0 }, -- GABZ MRPD
        -- { coords = vector3(200.0, 300.0, 40.0), radius = 15.0 },
    },
}

Config.Peds = {
    {
        model = 's_m_y_cop_01', -- Get ped names from https://wiki.rage.mp/index.php?title=Peds
        location = vector4(442.39, -981.911, 29.69, 85.0), -- GABZ MRPD
        animDict = 'missheistdockssetup1clipboard@base',  -- Get animations from https://alexguirre.github.io/animations-list/
        animName = 'base',  -- Get animations from https://alexguirre.github.io/animations-list/
        prop = 'prop_notepad_01',  -- Find Prop here https://gist.github.com/leonardosnt/53faac01a38fc94505e9
        propBone = 18905, -- Find Bones here https://wiki.rage.mp/index.php?title=Bones
        propPlacement = vector3(0.1, 0.02, 0.05),
        propRotation = vector3(10.0, 0.0, 0.0) 
    },    
    {
        model = 'csb_cop',
        location = vector4(1844.57, 2581.75, 45.01, 76.00), -- GABZ BOILINGBROKE PEN.
        animDict = 'missheistdockssetup1clipboard@base',
        animName = 'base',
        prop = 'prop_notepad_01',
        propBone = 18905,
        propPlacement = vector3(0.1, 0.02, 0.05),
        propRotation = vector3(10.0, 0.0, 0.0) 
    },
}

Config.HospitalConfiscate = true -- Useless config, if you don't want it to confiscate in hospital, don't add the ambulancejob snippet.
Config.JailConfiscate = true -- Useless config, if you don't want it to confiscate in jail, don't add the policejob snippet.

Config.Confiscation = {
    Mode = 'blacklist',  -- 'blacklist' to take ONLY the items below, 'whitelist' to take everything BUT the items below
    Items = {
        "weapon_knife",
        "weapon_pistol",
    }
}
Config.AccessControl = {
    jobName = {
        ['leo'] = true, 
        --['ems'] = true,
    },    
    checkType = 'type',   -- 'job' for jobName, 'type' for jobType (if you're using jobtype = 'leo' due to multiple departments, set to 'type', if only using the default police job, set to 'job')
}

Config.Unlocking = {
    allowedGrade = 2,  -- What grades can unlock the lockers
    adminCanUnlock = true,  -- True = admin can unlock lockers
}


Config.Locker = {
    slots = 100,     -- Slots in the locker
    weight = 250000 -- Maximum weight (10000 = 10kg)
}

return Config
