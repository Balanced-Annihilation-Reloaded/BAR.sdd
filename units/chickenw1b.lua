unitDef = {
  unitname            = "chickenw1b",
  name                = "Claw",
  description         = "Flying Spike Spitter",
  acceleration        = 2,
  amphibious          = true,
  bankscale           = "1",
  bmcode              = "1",
  brakeRate           = 0.2,
  buildCostEnergy     = 2200,
  buildCostMetal      = 72,
  builder             = false,
  buildPic            = "chicken_pidgeon.png",
  buildTime           = 1350,
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
  cruiseAlt           = 125,
  defaultmissiontype  = "VTOL_standby",
  explodeAs           = "TALON_DEATH",
  floater             = true,
  footprintX          = 1,
  footprintZ          = 1,
  idleAutoHeal        = 2,
  idleTime            = 0,
  turninplace         = 0,
  seismicSignature    = 0,
  iconType            = "chickenf",
  maneuverleashlength = "1280",
  mass                = 90,
  hidedamage          = 1,
  maxDamage           = 330,
  maxVelocity         = 9,
  moverate1           = "32",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chicken_pidgeonb.s3o",
  selfDestructAs      = "TALON_DEATH",
  separation          = "0.2",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 7 -6",
  collisionVolumeScales = "48 12 22",

  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 360,
  airSightDistance    = 600,
  smoothAnim          = true,
  steeringmode        = "1",
  TEDClass            = "VTOL",
  turnRate            = 3200,
  workerTime          = 0,

    weapons             = {

    {
      def               = "WEAPON",
      mainDir           = "0 0 1",
      maxAngleDif       = 120,
      badTargetCategory = "WEAPON",
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

      damage                  = {
        default = 120,
      },

      explosionGenerator      = "custom:dirt",
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      model                   = "spike.s3o",
      noSelfDamage            = true,
      propeller               = "1",
      range                   = 400,
      soundStart              = "talonattack",
      reloadtime              = 2,
      renderType              = 1,
      selfprop                = true,
      startVelocity           = 200,
      subMissile              = 1,
      turret                  = true,
      waterWeapon             = true,
      accuracy		          = 200,
      weaponAcceleration      = 100,
      weaponTimer             = 1,
      weaponVelocity          = 425,
    },

  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickenw1b = unitDef })
