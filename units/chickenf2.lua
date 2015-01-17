unitDef = {
  unitname            = "chickenf2",
  name                = "Buzzard",
  description         = "Flying Chicken Scout",
  acceleration        = 1,
  airHoverFactor      = 0,
  bmcode              = "1",
  brakeRate           = 0.4,
  buildCostEnergy     = 50,
  buildCostMetal      = 50,
  builder             = false,
  buildTime           = 4000,
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
  cruiseAlt           = 325,
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
  maxDamage           = 1800,
  idleAutoHeal        = 15,
  idleTime            = 900,
  collide             = false,
  maxVelocity         = 4.6,
  moverate1           = "32",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chickenf1.s3o",
  selfDestructAs      = "TALON_DEATH",
  steeringmode        = 1,
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 8 -2",
  collisionVolumeScales = "70 14 48",

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
  sightDistance       = 1400,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "VTOL",
  turnRate            = 900,
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
      areaOfEffect            = 200,
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 1,
      burstrate               = 1,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
         default=250,
	    	 CHICKEN=100,
         TINYCHICKEN=100,
      },

      dropped                 = true,
      edgeEffectiveness       = 0,
      explosionGenerator      = "",
      impulseBoost            = 1,
      impulseFactor           = 1,
      interceptedByShieldType = 0,
      manualBombSettings      = true,
      soundhit			      = "junohit2edit",
      model                   = "chickeneggred.s3o",
      noSelfDamage            = true,
      range                   = 800,
      mygravity               = 0.5,
      reloadtime              = 30,
      renderType              = 6,
      accuracy                = 300,
      sprayAngle              = 400,
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

return lowerkeys({ chickenf2 = unitDef })
