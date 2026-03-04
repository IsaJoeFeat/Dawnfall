local unitName  =  "constructor"

local unitDef  =  {
--Internal settings
BuildPic = "filename.png",
    Category = "LAND BUILDER NOTAIR NOTSUB LIGHT",
    ObjectName = "Constructor1.s3o",
    name = "Constructor",
    Side = "Beffys",
    TEDClass = "Vech",
    UnitName = "Constructor",
    script = "constructorscript.lua",

--Unit limitations and properties
    Description = "Builder.",
    MaxDamage = 550,
    idleTime = 300,
    idleAutoHeal = 0,
    RadarDistance = 0,
    SightDistance = 500,
    SoundCategory = "TANK",
    Upright = 0,
	--corpse = [[constructor_dead]]--,
--Energy and metal related
    BuildCostEnergy = 600,
    BuildCostMetal = 120,
	Buildtime = 120,
--Pathfinding and related
    maxAcc = 0.35,
    BrakeRate = 0.1,
    FootprintX = 3,
    FootprintZ = 3,
    MaxSlope = 45,
    speed = 50,
    MaxWaterDepth = 5,
    MovementClass = "3x3",
    TurnRate = 1000,

    
--Abilities
    CanAttack = 1,
    CanGuard = 1,
    CanMove = 1,
    CanPatrol = 1,
    CanStop = 1,
    LeaveTracks = 0,
    Reclaimable = 0,
    canSelfDestruct = 1,
    repairable = 1,
    
--building
Builder = true,
ShowNanoSpray = true,
CanBeAssisted = true,	
workerTime = 5,
repairSpeed = 5,
buildDistance = 120,
terraformSpeed = 9001,
buildoptions = 
	{
	[[extractor]],
	[[energyreactor]],
	[[factory]],
	[[llt]],
	},

--Hitbox
 collisionVolumeOffsets    =  "0 -4 -2",
collisionVolumeScales     =  "28 28 35",
collisionVolumeType       =  "box",

   
--Weapons and related
    BadTargetCategory = "NOTAIR",
      	--explodeAs = [[MediumExplosion]],
	--selfDestructAs = [[MediumExplosion]],
    NoChaseCategory = "AIR",




}

return lowerkeys({ [unitName]  =  unitDef })