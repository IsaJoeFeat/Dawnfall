local weaponName = "DuronPlasmaGun"
local weaponDef = {
	      name                    = "Plasma Gun",
	      weaponType              = [[Cannon]],
	      --damage
		  damage = {
				default = 102,
				},	      
	      areaOfEffect            = 32,
		  --physics
		  weaponVelocity          = 233,
		  reloadtime              = 2.75,
		  range                   = 360,
		  sprayAngle              = 0,
		  myGravity 		  	  = 0.11,
		  lineOfSight             = false,
 		  avoidfriendly 	= true,
		  avoidGround 		= true,      
	      turret                  = true,
		  avoidFeature			= false,
		  craterMult              = 0,
		 -- soundStart = [[]],
		  --soundHit = [[]],
		  --soundStartVolume = 4,
		  --soundHitVolume = 4,	      
		  --apperance
		  rgbColor                = [[0.9 0.7 0.5]],		  	      
          size                    = 4,
	      stages                  = 20,
		  separation              = 1,
		  explosionGenerator = [[custom:duronflash]],
		  }
		
return lowerkeys({[weaponName] = weaponDef})