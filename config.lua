Config = {}

Config.Command = {
    name = 'openlocker',  -- Name of the command.
    description = 'Open a player\'s locker',  -- Command's description
    usage = 'ID/CID',  -- What displays as a requirement
    help = 'Enter the player\'s server ID or CID' -- Description to help
}

Config.Peds = {
    {
        model = 's_m_y_cop_01', -- Default cop ped model
        location = vector4(442.39, -981.911, 29.69, 85.0), -- GABZ MRPD
        useQbTarget = true -- Set to true to use qb-target, false to use ox_target
    },
}

Config.AccessControl = {
    jobName = 'police',  -- Change the name of the job/type that can access the lockers (like 'police' or 'sheriff' or 'leo')
    checkType = 'job',   -- 'job' for jobName, 'type' for jobType (if you're using jobtype = 'leo' due to multiple departments, set to 'type', if only using the default police job, set to 'job')
}

Config.Locker = {
    slots = 50,     -- Slots in the locker
    maxWeight = 50000 -- Maximum weight (10000 = 10kg)
}

return Config
