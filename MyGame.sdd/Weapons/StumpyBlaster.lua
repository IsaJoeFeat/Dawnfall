local weaponName = "StumpyLaserBlaster"
weaponDef = {
	weaponType              = "LaserCannon",
	name                    = "Laser Blaster",
	beamlaser               = 0,
	--physics / aiming--
	duration                = 0.018,
	 weaponVelocity         = 500,
	lineOfSight             = true,
	minIntensity            = 1,      
	range                   = 235,
	reloadtime              = 0.26,
	sweepfire               = false,
	targetMoveError         = 0.1,
	turret                  = true,
	tolerance               = 5000,
	hardStop				= true,
	--damage--
	damage                  = {
		default = 11.3, --11.3    
		},
	areaOfEffect            = 0,
	craterBoost             = 0,
	craterMult              = 0,
	--apperance--	
	thickness               = 2,
	coreThickness           = 0.25,
	largeBeamLaser          = true,
	laserFlareSize          = 2,
	renderType              = 0,
	rgbColor                = [[0.8 0.8 0.4]],
	--soundStart = [[]],
	--soundStartVolume = 4,
	--soundHit = [[]],
	--soundHitVolume = 4,
	explosionGenerator = [[custom:stumpyhit]],
	--soundStart              = "some sound file",
	--soundTrigger            = true,	
	--texture1                = [[largelaser]],
	--texture2                = [[flare]],
	--texture3                = [[flare]],
	--texture4                = [[smallflare]],		
	}
return lowerkeys({[weaponName] = weaponDef})