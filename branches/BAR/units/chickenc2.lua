unitDef = {
  unitname            = "chickenc2",
  name                = "Manticore",
  description         = "All-Terrain Assault",
  acceleration        = 1.25,
  bmcode              = "1",
  brakeRate           = 2,
  buildCostEnergy     = 5280,
  buildCostMetal      = 170,
  builder             = false,
  buildTime           = 15000,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  corpse              = "DEAD",
  defaultmissiontype  = "Standby",
  explodeAs           = "BIGBUG_DEATH",
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = "chickenr",
  leaveTracks         = true,
  maneuverleashlength = "640",
  mass                = 900,
  maxDamage           = 10000,
  turninplace         = 0,
  maxSlope            = 18,
  maxVelocity         = 4.25,
  maxWaterDepth       = 15,
  movementClass       = "TKBOT3",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chickenc2.s3o",
  seismicSignature    = 3,
  selfDestructAs      = "BIGBUG_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 11 3",
  collisionVolumeScales = "25 38 64",

  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 512,
  smoothAnim          = true,
  sonarDistance       = 450,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 0.5,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = "ChickenTrackPointy",
  trackWidth          = 70,
  turnRate            = 1200,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = "WEAPON",
      mainDir            = "0 0 1",
      maxAngleDif        = 110,
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = "Blob",
      areaOfEffect            = 160,
      craterBoost             = 0,
      craterMult              = 0,
      edgeeffectiveness       = 0.15,
      camerashake             = 0,

      damage                  = {      
        default=1300, 
      },

      endsmoke                = "0",
      explosionGenerator      = "custom:gundam_MISSILE_EXPLOSION",
      impulseBoost            = 0.22,
      impulseFactor           = 0.22,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      avoidFeature            = 0,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 350,
      reloadtime              = 1.8,
      renderType              = 4,
      rgbColor                = "0.0 0.6 0.6",
      size                    = 8,
      sizeDecay               = -0.3,
      sprayAngle              = 256,
      cegTag="ROCKTRAILsm",
      model = "SGreyRock1.S3O",
      soundhit = "xplomed2",
      accuracy				  = 128,
      startsmoke              = "0",
      tolerance               = 5000,
      targetmoveerror         = 0.2,
      turret                  = true,
      weaponTimer             = 0.2,
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickenc2 = unitDef })
