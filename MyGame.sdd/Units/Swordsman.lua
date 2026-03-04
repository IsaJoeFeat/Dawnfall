local unitName  =  "swordsman"

local unitDef  =  {
--Internal settings
    BuildPic = "filename.png",
    Category = "LAND RAIDER NOTAIR NOTSUB LIGHT",
    ObjectName = "Humanoid.s3o",
    name = "Swordsman",
    Side = "Beefys",
    TEDClass = "Melee",
    UnitName = "Swordsman",
    script = "Swordsmanscript.lua",
    
--Unit limitations and properties
    Description = "A Fast Raider Unit",
    MaxDamage = 575,
    RadarDistance = 0,
    SightDistance = 500,
    SoundCategory = "Vech",
    Upright = false,
    
--Energy and metal related
    BuildCostEnergy = 300,
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
    MovementClass = "1x1",
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
[1]={name  = "SwordsmanSword",

	},
},

}

return lowerkeys({ [unitName]  =  unitDef })