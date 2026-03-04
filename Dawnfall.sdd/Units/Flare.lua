local unitName  =  "flare"

local unitDef  =  {
--Internal settings
    BuildPic = "filename.png",
    Category = "LAND RANGER NOTAIR NOTSUB LIGHT",
    ObjectName = "Flare.s3o",
    name = "Flare",
    Side = "Beefys",
    TEDClass = "Vech",
    UnitName = "Stumpy",
    script = "Flarescript.lua",
    
--Unit limitations and properties
    Description = "An slow and weak but long range unit.",
    MaxDamage = 750,
    RadarDistance = 0,
    SightDistance = 500,
    SoundCategory = "Vech",
    Upright = false,
    
--Energy and metal related
    BuildCostEnergy = 725,
    BuildCostMetal = 145,
    BuildTime = 145,
--Pathfinding and related
    Acceleration = 0.15,
    BrakeRate = 0.1,
    FootprintX = 2,
    FootprintZ = 2,
    MaxSlope = 20,
    MaxVelocity = 1.6,
	--speed = 76
    MaxWaterDepth = 10,
    MovementClass = "2x2",
    TurnRate = 1600,
    
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
collisionVolumeScales     =  "21 21 36",
collisionVolumeType       =  "box",
    
--Weapons and related
    BadTargetCategory = "",
    ExplodeAs = "SmallDeath",
    NoChaseCategory = "AIR",
	
	weapons = {
[1]={name  = "FlareMissle",

	},
},

}

return lowerkeys({ [unitName]  =  unitDef })