local unitName  =  "stumpy"

local unitDef  =  {
--Internal settings
    BuildPic = "filename.png",
    Category = "LAND RAIDER NOTAIR NOTSUB LIGHT",
    ObjectName = "Stumpy.s3o",
    name = "Stumpy",
    Side = "Beefys",
    TEDClass = "Vech",
    UnitName = "Stumpy",
    script = "Stumpyscript.lua",
    
--Unit limitations and properties
    Description = "A Fast Raider Unit",
    MaxDamage = 575,
    RadarDistance = 0,
    SightDistance = 500,
    SoundCategory = "Vech",
    Upright = false,
    
--Energy and metal related
    BuildCostEnergy = 325,
    BuildCostMetal = 75,
    BuildTime = 100, --100
--Pathfinding and related
    Acceleration = 0.15,
    BrakeRate = 0.1,
    FootprintX = 2,
    FootprintZ = 2,
    MaxSlope = 20,
    MaxVelocity = 2.53, --1.83
	--speed = 76 or 55
    MaxWaterDepth = 10,
    MovementClass = "2x2",
    TurnRate = 2000,
    
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
collisionVolumeScales     =  "14.7 14.7 25.2",
collisionVolumeType       =  "box",
    
--Weapons and related
    BadTargetCategory = "",
    --ExplodeAs = "SmallDeath",
    NoChaseCategory = "AIR",
	
	weapons = {
[1]={name  = "StumpyLaserBlaster",

	},
},

}

return lowerkeys({ [unitName]  =  unitDef })