unitDef = {
  unitname            = "chickens3",
  name                = "Fang",
  description         = "Spiker Air Assault",
  acceleration        = 0.5,
  brakeRate           = 3.5,
  buildCostEnergy     = 2200,
  buildCostMetal      = 72,
  builder             = false,
  buildPic            = "chicken_pidgeon.png",
  buildTime           = 1700,
  canFly              = true,
  canGuard            = true,
  canLand             = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = true,
  category            = "VTOL MOBILE WEAPON NOTSUB NOTSHIP NOTHOVER ALL",
  collide             = false,
  cruiseAlt           = 150,
  defaultmissiontype  = "VTOL_standby",
  explodeAs           = "TALON_DEATH",
  floater             = true,
  footprintX          = 1,
  footprintZ          = 1,
  idleAutoHeal        = 2,
  idleTime            = 0,
  seismicSignature    = 0,
  iconType            = "chickenf",
  mass                = 280,
  hidedamage          = 1,
  autoheal            = 7,
  maxDamage           = 1900,
  maxVelocity         = 7,
  hoverattack 		  = true,
  airStrafe           = true,
  noChaseCategory     = "VTOL",
  objectName          = "spiker_gunship.s3o",
  selfDestructAs      = "TALON_DEATH",
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
  sightDistance       = 550,
  smoothAnim          = true,
  steeringmode        = "1",
  TEDClass            = "VTOL",
  turnRate            = 900,

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
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 200,
      },

      explosionGenerator      = "custom:dirt",
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      model                   = "spike.s3o",
      noSelfDamage            = true,
      range                   = 350,
      soundStart              = "talonattack",
      reloadtime              = 1.95,
      renderType              = 1,
      selfprop                = true,
      startVelocity           = 200,
      subMissile              = 1,
      turret                  = true,
      accuracy		          = 1100,
      weaponAcceleration      = 100,
      weaponTimer             = 1,
      weaponVelocity          = 350,
    },

  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickens3 = unitDef })
