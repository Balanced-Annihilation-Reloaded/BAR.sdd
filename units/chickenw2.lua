unitDef = {
  unitname            = "chickenw2",
  name                = "Crow",
  description         = "Fighter",
  acceleration        = 2,
  amphibious          = true,
  bankscale           = "1",
  bmcode              = "1",
  brakeRate           = 0.2,
  buildCostEnergy     = 2200,
  buildCostMetal      = 72,
  builder             = false,
  buildPic            = "chicken_pidgeon.png",
  buildTime           = 1300,
  canFly              = true,
  canGuard            = true,
  canLand             = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = true,
  canSubmerge         = false,
  canCrash            = false,
  category            = "VTOL MOBILE WEAPON NOTSUB NOTSHIP NOTHOVER ALL",
  collide             = false,
  cruiseAlt           = 150,
  defaultmissiontype  = "VTOL_standby",
  explodeAs           = "TALON_DEATH",
  floater             = true,
  footprintX          = 1,
  footprintZ          = 1,
  turninplace         = 0,
  seismicSignature    = 0,
  iconType            = "chickenf",
  maneuverleashlength = "1280",
  mass                = 200,
  hidedamage          = 1,
  maxDamage           = 1100,
  autoHeal            = 10,
  maxVelocity         = 11,
  moverate1           = "32",
  noAutoFire          = false,
  noChaseCategory     = "NOTAIR",
  objectName          = "chicken_crow.s3o",
  selfDestructAs      = "TALON_DEATH",
  separation          = "0.2",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 7 -6",
  collisionVolumeScales = "48 12 22",

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
  sightDistance       = 0,
  airSightDistance    = 1500,
  smoothAnim          = true,
  steeringmode        = "1",
  TEDClass            = "VTOL",
  turnRate            = 7000,
  workerTime          = 0,

    weapons             = {

    {
      def               = "WEAPON",
      mainDir           = "0 0 1",
      maxAngleDif       = 90,
      badTargetCategory = "NOTAIR",
      onlyTargetCategory = "VTOL",
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = "Spike",
      areaOfEffect            = 32,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      edgeffectiveness        = 0,

      damage                  = {
        default = 200,
        bombers = 450,
        vtol = 600,
        fighters = 700,
      },

      explosionGenerator      = "custom:dirt",
      impulseBoost            = 1,
      impulseFactor           = 1,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      model                   = "spike.s3o",
      smoketrail 			  = true,
      texture1                = "",
      texture2                = "sporetrail",
      noSelfDamage            = true,
      propeller               = "1",
      range                   = 600,
      soundStart              = "talonattack",
      reloadtime              = 1.6,
      renderType              = 1,
      startVelocity           = 600,
      turret                  = true,
      weaponAcceleration      = 250,
      weaponTimer             = 1,
      weaponVelocity          = 1000,
      predictBoost            = 1,
    },

  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickenw2 = unitDef })
