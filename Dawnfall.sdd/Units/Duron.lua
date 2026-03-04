local unitName  =  "duron"

local unitDef  =  {
--Internal settings
    BuildPic = "filename.png",
    Category = "LAND ASSAULT NOTAIR NOTSUB LIGHT",
    ObjectName = "Duron.s3o",
    name = "Duron",
    Side = "Beefys",
    TEDClass = "Vech",
    UnitName = "Duron",
    script = "Duronscript.lua",
    
--Unit limitations and properties
    Description = "A Fast Raider Unit",
    MaxDamage = 1100,
    RadarDistance = 0,
    SightDistance = 500,
    SoundCategory = "Vech",
    Upright = false,
    
--Energy and metal related
    BuildCostEnergy = 925,
    BuildCostMetal = 185,
    BuildTime = 185, --100
--Pathfinding and related
    Acceleration = 0.15,
    BrakeRate = 0.1,
    FootprintX = 2,
    FootprintZ = 2,
    MaxSlope = 20,
    MaxVelocity = 1.83, 
    MaxWaterDepth = 10,
    MovementClass = "3x3",
    TurnRate = 1400,
    
--Abilities
    Builder = false,
    CanAttack = true,
    CanGuard = true,
    CanMove = true,
    CanPatrol = true,
    CanStop = true,
    LeaveTracks = false,
    Reclaimable = false,
    
--Hitbox
collisionVolumeOffsets    =  "0 0 0",
collisionVolumeScales     =  "33 29 46",
collisionVolumeType       =  "box",
    
--Weapons and related
    BadTargetCategory = "",
    ExplodeAs = "SmallDeath",
    NoChaseCategory = "AIR",
	
	weapons = {
[1]={name  = "DuronPlasmaGun",

	},
},

}

return lowerkeys({ [unitName]  =  unitDef })