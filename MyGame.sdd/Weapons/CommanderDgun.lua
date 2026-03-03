local weaponName = "CommanderDgun"
local weaponDef = {
	      name                    = "DGUN (press D to fire)",
	      weaponType              = [[DGun]],
	      --damage
		  damage = {
				default = 99999,
				},	      
		  --physics
		  areaOfEffect			  = 35,
		  weaponVelocity          = 500,
		  reloadtime              = 2,
		  range                   = 325,
		  sprayAngle              = 300,
	      tolerance               = 8000,
		  lineOfSight             = true,
 		  avoidfriendly 	= true,
		  avoidGround 		= false,
		  gravityAffected = true,	  
	      turret                  = true,
		  avoidFeature			= false,
		  craterMult              = 5,
		  commandFire 			= true,
		  groundBounce 			= true,
		   collideEnemy 		= false,
		   collidefriendly		= false,
		   collidefeature		= false,
		  bounceRebound 		= 0,
		  energyPerShot			= 200,
		  --soundStart            = [[]],
		  --soundStartVolume        = 4,	      
		  --apperance
		  rgbColor                = [[1 0.6 0.3]],		  	      
          size                    = 4,
	      stages                  = 20,
		  separation              = 1,
		  cegTag = [[DGUN_trail]],
		  }
return lowerkeys({[weaponName] = weaponDef})