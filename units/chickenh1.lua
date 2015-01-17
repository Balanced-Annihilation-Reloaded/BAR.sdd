unitDef = {
  unitname            = "chickenh1",
  name                = "Weaver",
  description         = "Chicken Healer",
  acceleration        = 0.05,
  activateWhenBuilt   = true,
  bmcode              = 1,
  brakeRate           = 0.2,
  buildCostEnergy     = 600,
  buildCostMetal      = 40,
  builder             = 1,
  buildPic            = "chicken_drone.png",
  buildTime           = 500,
  metalstorage        = 1000,
  canbuild            = 1,
  canGuard            = 1,
  canMove             = 1,
  canPatrol           = 1,
  canRepair           = 1,
  reclaimSpeed        = 400,
  canassist           = 0,
  mobilestandorders   = 1,
  standingmoveorder   = 1,
  workertime          = 200,
  builddistance       = 200,
  repairspeed         = 200,
  canstop             = 1,
  collide             = 0,
  stealth             = 1,
  energymake          = 25,
  turninplace         = 0,
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  defaultmissiontype  = "Standby",
  explodeAs           = "WEAVER_DEATH",
  kamikaze            = true,
  kamikazeDistance    = 60,
  floater             = false,
  footprintX          = 1,
  hidedamage          = 1,
  footprintZ          = 1,
  iconType            = "builder",
  autoheal	          = 32,
  leaveTracks         = true,
  maneuverleashlength = 640,
  mass                = 50,
  maxDamage           = 225,
  maxSlope            = 18,
  maxVelocity         = 2.6,
  maxWaterDepth       = 5000,
  movementClass       = "KBOT2",
  noAutoFire          = 0,
  objectName          = "chicken_drone.s3o",
  seismicSignature    = 1,
  selfDestructAs      = "WEAVER_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 -1 0",
  collisionVolumeScales = "10 14 22",

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
  sightDistance       = 256,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 1,
  trackStrength       = 6,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 10,
  turnRate            = 568,
  upright             = false,
  waterline           = 8,

  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickenh1 = unitDef })
