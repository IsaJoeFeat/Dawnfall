local unitName = "all_v1_m7priest"

local unitDef = {
    -- Identification
    name = "M7 Priest",
    description = "Light Artillery Vehicle",
    objectName = "Stumpy.s3o",
    script = "Stumpyscript.lua",
    buildPic = "buildpic_filename.png",
    category = "LAND ARTILLERY NOTAIR NOTSUB LIGHT",
    side = "Allies",
    upright = false, -- true for Infantry, false for Tanks

    -- Economy
    buildCostMetal = 135,
    buildCostEnergy = 2200,
    buildTime = 3000,
    builder = false,
    workerTime = 0, -- Set if unit builds things

    -- Combat & Health
    health = 620,
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
    LeaveTracks = false,
    Reclaimable = false,

    -- Movement (Physics)
    speed = 54,
    Acceleration = 0.1,
    BrakeRate = 0.2,
    turnRate = 390,
    turnInPlace = true,
    turnInPlaceAngleLimit = 90,
    movementClass = "3x3",
    footprintX = 3,
    footprintZ = 3,
    maxSlope = 15,
    maxWaterDepth = 8,
    leaveTracks = true,

    -- Sensors & Stealth
    losRadius = 370,
    airLosRadius = 800,
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
            def = "BROWNING_M2_HB",
            onlyTargetCategory = "LAND",
        },
    },
}

return lowerkeys({ [unitName] = unitDef })