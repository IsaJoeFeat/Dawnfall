local unitName  =  "commander"

local unitDef  =  {
--Internal settings
BuildPic = "filename.png",
    Category = "LAND BUILDER NOTAIR NOTSUB LIGHT",
    ObjectName = "Commander1.s3o",
    name = "Constructor",
    Side = "Beffys",
    TEDClass = "Vech",
    UnitName = "Constructor",
    script = "commanderscript.lua",

--Unit limitations and properties
    Description = "Commander, Make sure not to lose it!.",
    MaxDamage = 3500,
    idleTime = 600,
    idleAutoHeal = 10,
    RadarDistance = 1000,
    SightDistance = 500,
    SoundCategory = "TANK",
    Upright = 0,
	--corpse = [[constructor_dead]]--,
--Energy and metal related
    BuildCostEnergy = 6000,
    BuildCostMetal = 1500,
	Buildtime = 1500,
--Pathfinding and related
    maxAcc = 0.35,
    BrakeRate = 0.1,
    FootprintX = 3,
    FootprintZ = 3,
    MaxSlope = 45,
    speed = 48,
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
    onOffable =0,
    activateWhenBuilt = 1,
    canManualFire = 1,
	
--building
Builder = true,
ShowNanoSpray = true,
CanBeAssisted = true,	
workerTime = 10,
repairSpeed = 10,
buildDistance = 250,
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


	weapons = {
[1]={name  = "CommanderLaserBlaster",

	},
	[2]={name  = "CommanderDgun",

	},
},



}

return lowerkeys({ [unitName]  =  unitDef })