local unitName = "all_v1_cromwell"

local unitDef = {
    -- Identification
    name = "Cromwell",
    description = "Medium Assault Tank",
    objectName = "Stumpy.s3o",
    script = "Stumpyscript.lua",
    buildPic = "buildpic_filename.png",
    category = "LAND RAIDER NOTAIR NOTSUB MEDIUM",
    side = "Allies",
    upright = false, -- true for Infantry, false for Tanks

    -- Economy
    buildCostMetal = 225,
    buildCostEnergy = 2000,
    buildTime = 2900,
    builder = false,
    workerTime = 0, -- Set if unit builds things

    -- Combat & Health
    health = 1780,
    autoHeal = 0,
    idleAutoHeal = 5,
    --corpse = "unit_dead_feature",
    explodeAs = "TINY_EXPLOSION",
    selfDestructAs = "TINY_EXPLOSION",

--Abilities
    CanAttack = true,
    CanGuard = true,
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    LeaveTracks = true,
    Reclaimable = false,

    -- Movement (Physics)
    speed = 75,
    Acceleration = 0.2,
    BrakeRate = 0.1,
    turnRate = 398,
    turnInPlace = true,
    turnInPlaceAngleLimit = 90,
    movementClass = "2x2",
    footprintX = 2,
    footprintZ = 2,
    maxSlope = 10,
    maxWaterDepth = 12, -- might need fixed
    leaveTracks = true,

    -- Sensors & Stealth
    losRadius = 325,
    airLosRadius = 300,
    radarRadius = 0,
    sonarRadius = 0, -- Set for Subs/Corvettes

    -- Hitbox
    collisionVolumeOffsets = "0 0 0",
    collisionVolumeScales = "20 20 30",
    collisionVolumeType = "box",

    -- Weapons
    noChaseCategory = "AIR",
    weapons = {
        [1] = {
            def = "QF_6-POUNDER",
            onlyTargetCategory = "LAND",
        },
        [2] = {
            def = "BESA_MACHINE_GUN",
            onlyTargetCategory = "LAND",
        },
    },
}

return lowerkeys({ [unitName] = unitDef })