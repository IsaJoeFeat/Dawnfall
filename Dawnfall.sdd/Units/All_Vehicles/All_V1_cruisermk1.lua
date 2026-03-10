local unitName = "all_v1_cruisermk1"

local unitDef = {
    -- Identification
    name = "Cruiser Mk.1",
    description = "Fast Assault and Raiding Tank",
    objectName = "Stumpy.s3o",
    script = "Stumpyscript.lua",
    buildPic = "buildpic_filename.png",
    category = "LAND RAIDER NOTAIR NOTSUB LIGHT",
    side = "Allies",
    upright = false, -- true for Infantry, false for Tanks

    -- Economy
    buildCostMetal = 110,
    buildCostEnergy = 900,
    buildTime = 500,
    builder = false,
    workerTime = 0, -- Set if unit builds things

    -- Combat & Health
    health = 750,
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
    speed = 100,
    Acceleration = 0.1,
    BrakeRate = 0.2,
    turnRate = 540,
    turnInPlace = true,
    turnInPlaceAngleLimit = 90,
    movementClass = "2x2",
    footprintX = 2,
    footprintZ = 2,
    maxSlope = 15,
    maxWaterDepth = 10,
    leaveTracks = true,

    -- Sensors & Stealth
    losRadius = 350,
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
            def = "QF 2-POUNDER",
            onlyTargetCategory = "LAND",
        },
        [2] = {
            def = "VICKERS MACHINE GUN",
            onlyTargetCategory = "LAND",
        },
    },
}

return lowerkeys({ [unitName] = unitDef })