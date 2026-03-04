local weaponName = "SwordsmanSword"
weaponDef = {
	weaponType              = "Sword",
	name                    = "Shortsword",
	beamlaser               = 0,
	--physics / aiming--
	duration                = 0.018,
	 weaponVelocity         = 500,
	lineOfSight             = true,
	minIntensity            = 1,      
	range                   = 25,
	reloadtime              = 0.75,
	sweepfire               = false,
	targetMoveError         = 0.1,
	turret                  = false,
	tolerance               = 5000,
	hardStop				= true,
	--damage--
	damage                  = {
		default = 11.3, --11.3    
		},
	areaOfEffect            = 0.50,
	craterBoost             = 0,
	craterMult              = 0,
	--apperance--	
	thickness               = 2,
	coreThickness           = 0.25,
	largeBeamLaser          = false,
	laserFlareSize          = 2,
	renderType              = 0,
	rgbColor                = [[0.8 0.8 0.4]],
	--soundStart = [[]],
	--soundStartVolume = 4,
	--soundHit = [[]],
	--soundHitVolume = 4,
	explosionGenerator = [[custom:stumpyhit]],
	--soundStart              = "swordhit.wav",
	--soundTrigger            = true,	
	--texture1                = [[largelaser]],
	--texture2                = [[flare]],
	--texture3                = [[flare]],
	--texture4                = [[smallflare]],		
	}
return lowerkeys({[weaponName] = weaponDef})