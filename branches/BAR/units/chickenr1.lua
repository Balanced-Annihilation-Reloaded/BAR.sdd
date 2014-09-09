unitDef = {
  unitname            = "chickenr1",
  name                = "Lobber",
  description         = "Artillery",
  acceleration        = 0.1,
  bmcode              = "1",
  brakeRate           = 0.36,
  buildCostEnergy     = 12320,
  buildCostMetal      = 396,
  builder             = false,
  buildTime           = 4500,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  corpse              = "DEAD",
  defaultmissiontype  = "Standby",
  explodeAs           = "LOBBER_MORPH",
  footprintX          = 3,
  footprintZ          = 3,
  highTrajectory      = 1,
  iconType            = "chickenr",
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = "640",
  mass                = 4000,
  maxDamage           = 2500,
  maxSlope            = 18,
  maxVelocity         = 1.4,
  maxWaterDepth       = 15,
  hidedamage          = 1,
  turninplace         = 0,
  movementClass       = "AKBOT2",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chickenr.s3o",
  seismicSignature    = 4,
  selfDestructAs      = "LOBBER_MORPH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 1 0",
  collisionVolumeScales = "25 34 44",

  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 1250,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 30,
  turnRate            = 360,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = "GOOLAUNCHER",
      badTargetCategory  = "MOBILE",
      mainDir            = "0 0 1",
      maxAngleDif        = 120,
      onlyTargetCategory = "NOTAIR",
    },

  },


  weaponDefs          = {

    GOOLAUNCHER = {
      name                    = "GOOLAUNCHER",
      areaOfEffect            = 128,
      burst                   = 3,
      burstrate               = 0.8,
      craterBoost             = 0,
      craterMult              = 0,
      edgeeffectiveness       = 0.33,

      damage                  = {
        default=600,
		COMMANDERS=300,
		KROGOTH=300,
		ORCONE=300,
		SEADRAGON=300,
		BLACKHYDRA=300,
      },

      endsmoke                = "0",
      explosionGenerator      = "custom:ELECTRIC_EXPLOSION",
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      avoidFriendly           = 0,
      avoidFeature            = 0,
      collideFriendly         = 0,
      range                   = 1250,
      reloadtime              = 36,
      renderType              = 4,
      cegTag                  = "blob_trail",
      rgbColor                = "0.2 0.5 0.9",
      soundhit			      = "junohit2edit",
      size                    = 9,
      sizeDecay               = 0,
      sprayAngle              = 512,
      startsmoke              = "1",
      tolerance               = 5000,
      turret                  = true,
	  proximityPriority       = -4,
      accuracy                = 512,
      weaponTimer             = 0.2,
      weaponVelocity          = 600,
    },

  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickenr1 = unitDef })
