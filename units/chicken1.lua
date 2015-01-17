unitDef = {
  unitname            = "chicken1",
  name                = "Chicken",
  description         = "Swarmer",
  acceleration        = 0.15,
  bmcode              = "1",
  brakeRate           = 0.3,
  buildCostEnergy     = 52.8,
  buildCostMetal      = 25,
  builder             = false,
  buildTime           = 600,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP NOTHOVER ALL SURFACE",
  corpse              = "DEAD",
  defaultmissiontype  = "Standby",
  explodeAs           = "BUG_DEATH",
  floater             = false,
  footprintX          = 1.5,
  footprintZ          = 1.5,
  iconType            = "chicken",
  leaveTracks         = true,
  maneuverleashlength = 640,
  mass                = 30,
  maxDamage           = 475,
  maxSlope            = 18,
  maxVelocity         = 2.7,
  maxWaterDepth       = 15,
  seismicSignature    = 0,
  turninplace         = 0,
  movementClass       = "KBOT2",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chicken.s3o",
  selfDestructAs      = "BUG_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 -3 -3",
  collisionVolumeScales = "18 26 40",

  customparams = { 
    normalmaps = "yes", 
    normaltex = "unittextures/chicken_normal.tga", 
  },

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
  turnRate            = 700,
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
        default = 54,
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
      noSelfDamage            = true,
      range                   = 100,
      reloadtime              = 1.2,
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

return lowerkeys({ chicken1 = unitDef })
