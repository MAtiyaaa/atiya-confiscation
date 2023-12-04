Config = {}

Config.Commands = {
    openLocker = {
        name = 'openlocker',  -- Name of the command.
        description = 'Open a player\'s locker',  -- Commands description
        usage = 'ID/CID' -- Describes what's needed for input
    },
    lockLocker = {
        name = 'locklocker',
        description = 'Lock player\'s locker',
    }
}

Config.QBTarget = true -- Set to true to use qb-target, false to use ox_target

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

Config.AccessControl = {
    jobName = { 
        'police',  -- Change the name of the job/type that can access the lockers (like 'police' or 'sheriff' or 'leo')
        -- 'sherrif',
        -- 'leo',
        -- 'bcso'
    },    
    checkType = 'job',   -- 'job' for jobName, 'type' for jobType (if you're using jobtype = 'leo' due to multiple departments, set to 'type', if only using the default police job, set to 'job')
}

Config.Locker = {
    slots = 50,     -- Slots in the locker
    maxWeight = 50000 -- Maximum weight (10000 = 10kg)
}

return Config
