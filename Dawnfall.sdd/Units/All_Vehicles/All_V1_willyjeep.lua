local unitName = "all_v1_willyjeep"

local unitDef = {
    -- Identification
    name = "Willys Jeep",
    description = "Fast Recon and Raiding Vehicle",
    objectName = "Stumpy.s3o",
    script = "Stumpyscript.lua",
    buildPic = "buildpic_filename.png",
    category = "LAND RAIDER NOTAIR NOTSUB LIGHT",
    side = "Allies",
    upright = false, -- true for Infantry, false for Tanks

    -- Economy
    buildCostMetal = 35,
    buildCostEnergy = 400,
    buildTime = 450,
    builder = false,
    workerTime = 0, -- Set if unit builds things

    -- Combat & Health
    health = 150,
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
    speed = 200,
    Acceleration = 0.3,
    BrakeRate = 0.2,
    turnRate = 650,
    turnInPlace = true,
    turnInPlaceAngleLimit = 90,
    movementClass = "2x2",
    footprintX = 2,
    footprintZ = 2,
    maxSlope = 22,
    maxWaterDepth = 5,
    leaveTracks = true,

    -- Sensors & Stealth
    losRadius = 650,
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