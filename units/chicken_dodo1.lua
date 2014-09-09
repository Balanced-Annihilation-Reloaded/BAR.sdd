unitDef = {
  unitname              = "chicken_dodo1",
  name                  = "Dodo",
  description           = "Chicken Bomb",
  acceleration          = 6,
  activateWhenBuilt     = true,
  bmcode                = "1",
  brakeRate             = 0.2,
  buildCostEnergy       = 3000,
  buildCostMetal        = 128,
  builder               = false,
  buildTime             = 3000,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  canHover              = "1",
  canstop               = "1",
  category              = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP NOTHOVER ALL SURFACE",
  corpse                = "DEAD",
  defaultmissiontype    = "Standby",
  explodeAs             = "DODO_DEATH1",
  floater               = false,
  footprintX            = 1,
  footprintZ            = 1,
  iconType              = "chicken",
  kamikaze              = true,
  kamikazeDistance      = 40,
  leaveTracks           = true,
  maneuverleashlength   = "640",
  mass                  = 5000,
  maxDamage             = 200,
  autoHeal				= 50,
  maxSlope              = 18,
  maxVelocity           = 7,
  maxWaterDepth         = 0,
  hidedamage            = 1,
  turninplace           = 0,
  movementClass         = "CHICKENHOVERDODO",
  noAutoFire            = false,
  noChaseCategory       = "VTOL SINK HOVER",
  objectName            = "chicken_dodo.s3o",
  seismicSignature      = 2,
  selfDestructAs        = "DODO_DEATH1",
  selfDestructCountdown = 0,
  stealth				= 1,
  collide               = false,
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 -1 0",
  collisionVolumeScales = "10 14 22",

  sfxtypes              = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                  = "THUNDERBIRDS",
  sightDistance         = 36,
  smoothAnim            = true,
  steeringmode          = "2",
  TEDClass              = "KBOT",
  trackOffset           = 1,
  trackStrength         = 6,
  trackStretch          = 1,
  trackType             = "ChickenTrack",
  trackWidth            = 10,
  turnRate              = 2000,
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

return lowerkeys({ chicken_dodo1 = unitDef })
