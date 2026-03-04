local weaponName = "CommanderLaserBlaster"
weaponDef = {
	weaponType              = "LaserCannon",
	name                    = "Laser Blaster",
	beamlaser               = 0,
	--physics / aiming--
	duration                = 0.112,
	 weaponVelocity         = 750,
	lineOfSight             = true,
	minIntensity            = 1,      
	range                   = 350,
	reloadtime              = 0.75,
	sweepfire               = false,
	targetMoveError         = 0.1,
	turret                  = true,
	tolerance               = 5000,
	hardStop				= true,
	--damage--
	damage                  = {
		default = 125,   
		},
	areaOfEffect            = 0,
	craterBoost             = 0,
	craterMult              = 0,
	--apperance--	
	thickness               = 2.5,
	coreThickness           = 0.35,
	largeBeamLaser          = true,
	laserFlareSize          = 2,
	renderType              = 0,
	rgbColor                = [[0.35 1 0.45]],
	--soundStart = [[]],
	--soundStartVolume = 4,
	--soundHit = [[]],
	--soundHitVolume = 4,
	explosionGenerator = [[custom:commanderhit]],
	--soundStart              = "some sound file",
	--soundTrigger            = true,	
	--texture1                = [[largelaser]],
	--texture2                = [[flare]],
	--texture3                = [[flare]],
	--texture4                = [[smallflare]],		
	}
return lowerkeys({[weaponName] = weaponDef})