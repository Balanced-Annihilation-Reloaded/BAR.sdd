-- this should just be a simple muzzle flash. 
return {
  ["BAR_MUZZLEFLASH_CANNON_1"] = {
    engine = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1.0 0.8 0.2 1.0	0.5 0.4 0.3 0.5	0.1 0.1 0.1 0.0]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[flash4]],
        -- fronttexture       = [[muzzlefront]],
        length             = 18,
        sidetexture        = [[flashside2]],
        -- sidetexture        = [[muzzleside]],
        size               = 4.0,
        sizegrowth         = 0.9,
        ttl                = 15,
      },
    },
  },
}
