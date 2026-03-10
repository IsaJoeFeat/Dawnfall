local unitName = "all_v1_shermandd"

local unitDef = {
    -- Identification
    name = "Sherman DD",
    description = "Fast Floating Assault Tank",
    objectName = "Stumpy.s3o",
    script = "Stumpyscript.lua",
    buildPic = "buildpic_filename.png",
    category = "LAND RAIDER NOTAIR NOTSUB LIGHT",
    side = "Allies",
    upright = false, -- true for Infantry, false for Tanks

    -- Economy
    buildCostMetal = 200,
    buildCostEnergy = 2000,
    buildTime = 2610,
    builder = false,
    workerTime = 0, -- Set if unit builds things

    -- Combat & Health
    health = 1340,
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
    speed = 63,
    Acceleration = 0.2,
    BrakeRate = 0.1,
    turnRate = 398,
    turnInPlace = true,
    turnInPlaceAngleLimit = 90,
    movementClass = "3x3",
    footprintX = 3,
    footprintZ = 3,
    maxSlope = 15,
    maxWaterDepth = 0, -- might need fixed
    leaveTracks = true,

    -- Sensors & Stealth
    losRadius = 500,
    airLosRadius = 800,
    radarRadius = 0,
    sonarRadius = 50, -- Set for Subs/Corvettes

    -- Hitbox
    collisionVolumeOffsets = "0 0 0",
    collisionVolumeScales = "20 20 30",
    collisionVolumeType = "box",

    -- Weapons
    noChaseCategory = "AIR",
    weapons = {
        [1] = {
            def = "75MM M1A1 GUN",
            onlyTargetCategory = "LAND",
        },
        [2] = {
            def = "BROWNING_M2_HB",
            onlyTargetCategory = "LAND",
        },
    },
}

return lowerkeys({ [unitName] = unitDef })