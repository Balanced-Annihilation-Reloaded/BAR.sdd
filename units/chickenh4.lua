unitDef = {
  unitname            = "chickenh4",
  name                = "Chicken",
  description         = "Hatchling Swarmer",
  acceleration        = 0.56,
  bmcode              = "1",
  brakeRate           = 0.2,
  buildCostEnergy     = 250,
  buildCostMetal      = 20,
  builder             = false,
  buildTime           = 1500,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  corpse              = "DEAD",
  defaultmissiontype  = "Standby",
  explodeAs           = "BUG_DEATH",
  floater             = false,
  footprintX          = 1,
  footprintZ          = 1,
  iconType            = "chicken",
  leaveTracks         = true,
  maneuverleashlength = 640,
  mass                = 100,
  maxDamage           = 490,
  maxSlope            = 18,
  maxVelocity         = 8.2,
  collide             = 0,
  maxWaterDepth       = 15,
  turninplace         = 0,
  movementClass       = "KBOT2",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "s_chicken_white.s3o",
  selfDestructAs      = "BUG_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 -1 0",
  collisionVolumeScales = "10 14 22",
  
  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 300,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 18,
  turnRate            = 800,
  upright             = false,
  waterline           = 8,
  workerTime          = 0,

  weapons             = {

    {
      def                = "WEAPON",
      mainDir            = "0 0 1",
      maxAngleDif        = 120,
      onlyTargetCategory = "NOTAIR",
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = "Claws",
      areaOfEffect            = 24,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 70,
        CHICKEN = 0.001,
        TINYCHICKEN = 0.001,
      },

      endsmoke                = "0",
      explosionGenerator      = "custom:NONE",
      impulseBoost            = 2.2,
      impulseFactor           = 1,
      avoidFriendly           = 0,
      avoidFeature            = 0,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 90,
      reloadtime              = 0.4,
      soundStart              = "smallchickenattack",
      size                    = 0,
      startsmoke              = "0",
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponTimer             = 0.1,
      weaponType              = "Cannon",
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

return lowerkeys({ chickenh4 = unitDef })
