unitDef = {
  unitname            = "chickenh2",
  name                = "Progenitor",
  description         = "Chicken Spawner",
  acceleration        = 0.56,
  bmcode              = "1",
  brakeRate           = 0.2,
  buildCostEnergy     = 5200.8,
  buildCostMetal      = 250.8,
  builder             = false,
  buildTime           = 6000,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  corpse              = "DEAD",
  defaultmissiontype  = "Standby",
  explodeAs           = "BIGBUG_DEATH",
  floater             = false,
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = "chicken",
  leaveTracks         = true,
  maneuverleashlength = 640,
  mass                = 1500,
  maxDamage           = 6000,
  maxSlope            = 18,
  maxVelocity         = 3,
  maxWaterDepth       = 15,
  turninplace         = 0,
  hidedamage          = 1,
  movementClass       = "AKBOT2",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "s_chickenboss_white.s3o",
  selfDestructAs      = "BUG_DEATH",
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
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 700,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 18,
  turnRate            = 400,
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
        default = 400,
        CHICKEN = 0.001,
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
      range                   = 165,
      reloadtime              = 1,
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

return lowerkeys({ chickenh2 = unitDef })
