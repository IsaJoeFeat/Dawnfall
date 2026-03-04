local unitName  =  "extractor"

local unitDef  =  {
--Internal settings
BuildPic = "EFilename.png",
    Category = "BUILDING LAND SMALL NOTAIR NOTSUB",
    ObjectName = "Extractor1.s3o",
    name = "Extractor",
    Side = "Zoomers",
    TEDClass = "Building",
    UnitName = "Extractor",
    script = "extractorscript.lua",

--Unit limitations and properties
    Description = "Extracts Metal",
    MaxDamage =500,
    idleTime = 0,
    idleAutoHeal = 0,
    RadarDistance = 0,
    SightDistance = 400,
    SoundCategory = "Building",
    Upright = 0,
    floater = true,
	--corpse = [[extractor_dead]]--,
--Energy and metal related
    BuildCostEnergy = 325,
    BuildCostMetal = 65,
    Buildtime = 65,
	extractsMetal = 0.001,
	EnergyUse = 3,
	metalStorage = 50,
--Size and Abilites
   MaxSlope = 33,
   FootprintX = 3,
   FootprintZ = 3,
   canSelfDestruct = 1,
   repairable = 1,
   CanMove = 0,
   CanPatrol = 0,
   onOffable = 1,
   activateWhenBuilt = 1, 


--Hitbox
 collisionVolumeOffsets    =  "0 -35 0",
 collisionVolumeScales     =  "30.5 100 30.5",
 collisionVolumeType       =  "box",
	YardMap = "ooooooooo",
--Weapons and related
--explodeAs = [[SmallBuildingExplosion]],
	--selfDestructAs = [[SmallBuildingExplosion]],
    


}

return lowerkeys({ [unitName]  =  unitDef })
