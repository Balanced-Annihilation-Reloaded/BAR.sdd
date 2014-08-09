-- raven_rocket

return {
  ["raven_rocket"] = {
    engine = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1.0 0.8 0.2 0.01		1.0 0.2 0.1 0.01	0.6 0.1 0.1 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[none]],
        length             = 18,
        sidetexture        = [[flashside1]],
        size               = 4.3,
        sizegrowth         = 0.9,
        ttl                = 2,
      },
    },
  },
}