unitDef = {
  unitname            = "chickena1c",
  name                = "Cockatrice",
  description         = "Assault",
  acceleration        = 0.36,
  bmcode              = "1",
  brakeRate           = 0.4,
  buildCostEnergy     = 3520,
  buildCostMetal      = 152,
  builder             = false,
  buildTime           = 5000,
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
  iconType            = "chickena",
  leaveTracks         = true,
  maneuverleashlength = "640",
  mass                = 1500,
  maxDamage           = 4250,
  maxSlope            = 18,
  maxVelocity         = 1.15,
  maxWaterDepth       = 15,
  seismicSignature    = 0,
  turninplace         = 0,
  movementClass       = "CHICKENHKBOT4",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chickenac.s3o",
  selfDestructAs      = "BIGBUG_DEATH",
  onlytargetcategory2 = "VTOL",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 2 0",
  collisionVolumeScales = "27 38 60",

  customparams = { 
    normalmaps = "yes", 
    normaltex = "unittextures/chicken_normal.tga", 
  },

  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
      "custom:blob_fire",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 430,
  airSightDistance    = 650,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 7,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 34,
  turnRate            = 568,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = "WEAPON",
      mainDir            = "0 0 1",
      maxAngleDif        = 125,
      onlyTargetCategory = "NOTAIR",
      badTargetCategory  = "VTOL",
    },
    
    {
      def                = "AAWEAPON",
      onlyTargetCategory = "VTOL",
      badTargetCategory  = "NOTAIR",
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = "Claws",
      areaOfEffect            = 42,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 165,
        CHICKEN = 0.001,
        TINYCHICKEN = 0.001,
      },

      endsmoke                = "0",
      explosionGenerator      = "custom:NONE",
      impulseBoost            = 1,
      impulseFactor           = 2.2,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      soundStart              = "smallchickenattack",
      range                   = 130,
      reloadtime              = 0.9,
      size                    = 0,
      avoidFriendly           = 0,
      avoidFeature            = 0,
      startsmoke              = "0",
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = "Cannon",
      weaponVelocity          = 700,
    },

    AAWEAPON = {
      name                    = "BlobMissile",
      areaOfEffect            = 124,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      edgeeffectiveness       = 0.33,

      damage                  = {
        default = 175,
      },

      dance                   = 20,
      explosionGenerator      = "custom:blood_explode_blue",
      fireStarter             = 0,
      flightTime              = 5,
      guidance                = true,
      heightmod               = 0.5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      toAirWeapon             = 1,
      lineOfSight             = true,
      model                   = "AgamAutoBurst.s3o",
      noSelfDamage            = true,
      range                   = 550,
      reloadtime              = 7,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = "0.1",
      smokeTrail              = true,
      startsmoke              = "1",
      startVelocity           = 200,
      soundhit                = "junohit2edit",
      texture1                = "",
      texture2                = "sporetrail",
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 2,
      turnRate                = 24000,
      turret                  = true,
      weaponAcceleration      = 75,
      weaponType              = "MissileLauncher",
      weaponVelocity          = 700,
      wobble                  = 32000,
    },


  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickena1c = unitDef })
