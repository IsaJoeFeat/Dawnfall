local unitName  =  "energyreactor"

local unitDef  =  {
--Internal settings
BuildPic = "Filename.png",
    Category = "BUILDING LAND SMALL NOTAIR NOTSUB",
    ObjectName = "energyreactor1.s3o",
    name = "Energy Reactor",
    Side = "Vroomers",
    TEDClass = "Building",
    UnitName = "Energy Reactor",
    script = "energyreactorscript.lua",
	--corpse = [[fusionreactor_dead]]--,
--Unit limitations and properties
    Description =  "energy generator, only requires metal (20E).",
    MaxDamage = 375,
    idleTime = 0,
    idleAutoHeal = 0,
    RadarDistance = 0,
    SightDistance = 450,
    SoundCategory = "Building",
    Upright = 0,
	maxWaterDepth = 4,
--Energy and metal related
    BuildCostEnergy = 0,
    BuildCostMetal = 140,
    Buildtime = 140,
    energyMake = 20, 
	energySTorage = 75,
--Size and Abilites
   MaxSlope = 33,
   FootprintX = 3,
   FootprintZ = 3,
   canSelfDestruct = 1,
   repairable = 1,
   CanMove = 0,
   CanPatrol = 0,
	

--Hitbox
collisionVolumeOffsets    =  "0 0 0",
collisionVolumeScales     =  "38 46 38",
collisionVolumeType       =  "box",
YardMap = "oooo oooo oooo oooo",
--Weapons and related
	explodeAs = [[FusionExplosion]],
	selfDestructAs = [[FusionExplosion]],
    


}

return lowerkeys({ [unitName]  =  unitDef })
