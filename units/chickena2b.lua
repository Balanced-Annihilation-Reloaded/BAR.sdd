unitDef = {
  unitname            = "chickena2b",
  name                = "Alpha Cockatrice",
  description         = "Advanced Assault",
  acceleration        = 0.36,
  bmcode              = "1",
  brakeRate           = 0.4,
  buildCostEnergy     = 3520,
  buildCostMetal      = 302,
  builder             = false,
  buildTime           = 22500,
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
  mass                = 3000,
  maxDamage           = 39000,
  autoheal			  = 40,
  maxSlope            = 18,
  maxVelocity         = 0.925,
  maxWaterDepth       = 15,
  seismicSignature    = 0,
  turninplace         = 0,
  movementClass       = "CHICKENHKBOT4",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  onlytargetcategory2 = "VTOL",
  objectName          = "chickena2b.s3o",
  selfDestructAs      = "BIGBUG_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 10 2",
  collisionVolumeScales = "37 55 90",

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
  sightDistance       = 600,
  airSightDistance    = 1800,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 7,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 38,
  turnRate            = 468,
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
        default = 300,
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
      range                   = 165,
      reloadtime              = 0.8,
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
      areaOfEffect            = 200,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      edgeeffectiveness       = 0.05,

      damage                  = {
        default = 400,
        bombers = 1100,
        vtol = 1300,
        fighters = 1500,
      },

      dance                   = 20,
      explosionGenerator      = "custom:blood_explode_blue",
      fireStarter             = 0,
      flightTime              = 2.5,
      guidance                = true,
      heightmod               = 0.5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      toAirWeapon             = 1,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = "AgamAutoBurst.s3o",
      noSelfDamage            = true,
      range                   = 900,
      reloadtime              = 8,
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
      ProximityPriority 	  = -4,
    },


  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickena2b = unitDef })
