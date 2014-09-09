unitDef = {
  unitname              = "chicken_dodo2",
  name                  = "Alpha Dodo",
  description           = "Chicken Bomb",
  acceleration          = 6,
  activateWhenBuilt     = true,
  bmcode                = "1",
  brakeRate             = 0.2,
  buildCostEnergy       = 9000,
  buildCostMetal        = 350,
  builder               = false,
  buildTime             = 15000,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  canHover              = "1",
  canstop               = "1",
  category              = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP NOTHOVER ALL SURFACE",
  corpse                = "DEAD",
  defaultmissiontype    = "Standby",
  explodeAs             = "DODO_DEATH2",
  floater               = false,
  footprintX            = 1,
  footprintZ            = 1,
  iconType              = "chicken",
  kamikaze              = true,
  kamikazeDistance      = 72,
  leaveTracks           = true,
  maneuverleashlength   = "640",
  mass                  = 10000,
  maxDamage             = 1350,
  autoHeal         		= 135,
  maxSlope              = 18,
  maxVelocity           = 8,
  maxWaterDepth         = 0,
  turninplace           = 0,
  hidedamage            = 1,
  movementClass         = "CHICKENHOVERDODO",
  noAutoFire            = false,
  noChaseCategory       = "VTOL SINK HOVER",
  objectName            = "big_chicken_dodo.s3o",
  seismicSignature      = 4,
  selfDestructAs        = "DODO_DEATH2",
  selfDestructCountdown = 0,
  stealth				= 1,
  collide               = 0,
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 3 0",
  collisionVolumeScales = "18 28 41",
  
  sfxtypes              = {

    explosiongenerators = {
      "custom:DODOTRAIL",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                  = "THUNDERBIRDS",
  sightDistance         = 100,
  smoothAnim            = true,
  steeringmode          = "2",
  TEDClass              = "KBOT",
  trackOffset           = 1,
  trackStrength         = 6,
  trackStretch          = 1,
  trackType             = "ChickenTrack",
  trackWidth            = 10,
  turnRate              = 1000,
  upright               = false,
  waterline             = 1,
  workerTime            = 0,

  featureDefs           = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chicken_dodo2 = unitDef })
