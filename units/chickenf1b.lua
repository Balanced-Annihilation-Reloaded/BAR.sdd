unitDef = {
  unitname            = "chickenf1b",
  name                = "Talon",
  description         = "Flying Chicken Bomber",
  acceleration        = 0.8,
  airHoverFactor      = 0,
  bmcode              = "1",
  brakeRate           = 0.4,
  buildCostEnergy     = 4550,
  buildCostMetal      = 212,
  builder             = false,
  buildTime           = 6250,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canLand             = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  canSubmerge         = true,
  category            = "VTOL MOBILE WEAPON NOTSUB NOTSHIP NOTHOVER ALL",
  corpse              = "DEAD",
  cruiseAlt           = 270,
  defaultmissiontype  = "Standby",
  explodeAs           = "TALON_DEATH",
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = "chickenf",
  maneuverleashlength = "20000",
  mass                = 227.5,
  hidedamage          = 1,
  turninplace         = 0,
  seismicSignature    = 0,
  maxDamage           = 1600,
  idleAutoHeal        = 5,
  idleTime            = 0,
  collide             = false,
  maxVelocity         = 4.8,
  moverate1           = "32",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chickenf1b.s3o",
  selfDestructAs      = "TALON_DEATH",
  steeringmode        = 1,
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 8 -2",
  collisionVolumeScales = "70 14 48",

  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 1000,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "VTOL",
  turnRate            = 1100,
  workerTime          = 0,
  attackrunlength     = 32,
  weapons             = {

    {
      def               = "WEAPON",
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = "GooBombs",
      areaOfEffect            = 150,
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 11,
      burstrate               = 0.41,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
            default=250,
	    	ANTIBOMBER=125,
	    	CHICKEN=75,
            TINYCHICKEN = 75,
      },

      dropped                 = true,
      edgeEffectiveness       = 0.1,
      explosionGenerator      = "custom:gundam_MISSILE_EXPLOSION",
      impulseBoost            = 1,
      impulseFactor           = 1,
      interceptedByShieldType = 0,
      manualBombSettings      = true,
      soundhit			      = "junohit2edit",
      model                   = "chickeneggyellow.s3o",
      noSelfDamage            = true,
      range                   = 700,
      reloadtime              = 9,
      renderType              = 6,
      accuracy                = 1000,
      sprayAngle              = 2000,
      weaponType              = "AircraftBomb",
      },

  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickenf1b = unitDef })
