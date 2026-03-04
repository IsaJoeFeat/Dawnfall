local weaponName = "LLTLaserBlaster"
weaponDef = {
	weaponType              = "LaserCannon",
	name                    = "Laser Blaster",
	beamlaser               = 0,
	--physics / aiming--
	duration                = 0.105,
	 weaponVelocity         = 750,
	lineOfSight             = true,
	minIntensity            = 1,      
	range                   = 550,
	reloadtime              = 0.78,
	sweepfire               = false,
	targetMoveError         = 0.1,
	turret                  = true,
	tolerance               = 5000,
	hardStop				= true,
	--damage--
	damage                  = {
		default = 86, --11.3    
		},
	areaOfEffect            = 0,
	craterBoost             = 0,
	craterMult              = 0,
	--apperance--	
	thickness               = 2.25,
	coreThickness           = 0.3,
	largeBeamLaser          = true,
	laserFlareSize          = 2,
	renderType              = 0,
	rgbColor                = [[1 0.5 0.5]],
	--soundStart = [[]],
	--soundStartVolume = 4,
	--soundHit = [[]],
	--soundHitVolume = 4,
	explosionGenerator = [[custom:llt1hit]],
	--soundStart              = "some sound file",
	--soundTrigger            = true,	
	--texture1                = [[largelaser]],
	--texture2                = [[flare]],
	--texture3                = [[flare]],
	--texture4                = [[smallflare]],		
	}
return lowerkeys({[weaponName] = weaponDef})