--thanks xta for always has nice effects!
--default
local cegs = {
  ["Rocket_trail"] = {
    usedefaultexplosions = false,
    exhale = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[0.7 0.5 0.4 0.01 0.1 0.1 0.1 0.18 0.0 0.0 0.0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 20,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 2,
        particlelife       = 30,
        particlelifespread = 4.2,
        particlesize       = 3,
        particlesizespread = 1,
        particlespeed      = 1,
        particlespeedspread = 2,
        pos                = [[0, 1, 0]],
        sizegrowth         = 0.65,
        sizemod            = 1.0,
        texture            = [[newsmoke]],
      },
    },
    groundflash = {
      air                = true,
      circlealpha        = 0,
      circlegrowth       = 0,
      flashalpha         = 0.40,
      flashsize          = 15,
      ground             = true,
      ttl                = 5,
      water              = true,
      color = {
        [1]  = 0.8,
        [2]  = 0.8,
        [3]  = 0.4,
      },
    },
    largeflash = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1.0 0.3 0.2 0.01 0.4 0.2 0.1 0.01 0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[muzzlefront]],
        length             = -24,
        sidetexture        = [[muzzleside]],
        size               = -5,
        sizegrowth         = 0.75,
        ttl                = 1,
      },
    },
   },
   ["DGUN_trail"] = {
    usedefaultexplosions = false,
 
    groundflash = {
      air                = true,
      circlealpha        = 0,
      circlegrowth       = 0,
      flashalpha         = 0.9,
      flashsize          = 15,
      ground             = true,
      ttl                = 40,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 0.6,
        [3]  = 0.3,
      },
    },
}
}
return cegs