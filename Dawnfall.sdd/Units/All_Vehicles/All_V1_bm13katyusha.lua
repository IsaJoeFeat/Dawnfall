local unitName = "all_v1_bm13katyusha"

local unitDef = {
    -- Identification
    name = "BM-13 Katyusha",
    description = "Medium Range Missle Vehicle",
    objectName = "Stumpy.s3o",
    script = "Stumpyscript.lua",
    buildPic = "buildpic_filename.png",
    category = "LAND RAIDER NOTAIR NOTSUB LIGHT",
    side = "Allies",
    upright = false, -- true for Infantry, false for Tanks

    -- Economy
    buildCostMetal = 150,
    buildCostEnergy = 2100,
    buildTime = 3420,
    builder = false,
    workerTime = 0, -- Set if unit builds things

    -- Combat & Health
    health = 820,
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
    speed = 55,
    Acceleration = 0.1,
    BrakeRate = 0.1,
    turnRate = 370,
    turnInPlace = true,
    turnInPlaceAngleLimit = 90,
    movementClass = "3x3",
    footprintX = 3,
    footprintZ = 3,
    maxSlope = 16,
    maxWaterDepth = 12,
    leaveTracks = true,

    -- Sensors & Stealth
    losRadius = 620,
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
            def = "KATYUSHA_ROCKET_LAUNCHER",
            onlyTargetCategory = "LAND",
        },
    },
}

return lowerkeys({ [unitName] = unitDef })