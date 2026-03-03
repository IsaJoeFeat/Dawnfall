--duron
return {

   --duron
	["duronflash"] = {
	usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 1,
      flashalpha         = 0.9,
      flashsize          = 40,
      ttl                = 18,
      color = {
        [1]  = 0.9,
        [2]  = 0.7,
        [3]  = 0.5,
      },
    },
	 mainhit = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        heat               = 13, --8
        heatfalloff        = 1,
        maxheat            = 13, --8
        pos                = [[0, 1, 0]],
        size               = 17, 
        sizegrowth         = 1.1, 
        speed              = [[0, 1, 0]],
        texture            = [[heatcloud]],
      },
	},
	speckdirt = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 0.95,
        colormap           = [[0.02 0.015 0.01 0.075  0.2 0.15 0.1 0.75  0.02 0.015 0.01 0.075]],
        directional        = false,
        emitrot            = 25,
        emitrotspread      = 5,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.1, 0]],
        numparticles       = 3,
        particlelife       = 24,
        particlelifespread = 4.5,
        particlesize       = 4.25,
        particlesizespread = 3.1,
        particlespeed      = 3,
        particlespeedspread = 1,
        pos                = [[0, 0, 0]],
        sizegrowth         = 4,
        sizemod            = 0.75,
        texture            = [[randdots]],
    },
  },
   },
}