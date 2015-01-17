unitDef = {
  unitname            = "chickenr3",
  name                = "Chicken Colonizer",
  description         = "Meteor Launcher",
  acceleration        = 1,
  bmcode              = "1",
  brakeRate           = 8,
  buildCostEnergy     = 12320,
  buildCostMetal      = 396,
  builder             = false,
  buildTime           = 180000,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  corpse              = "DEAD",
  defaultmissiontype  = "Standby",
  explodeAs           = "LOBBER_MORPH",
  footprintX          = 4,
  footprintZ          = 4,
  highTrajectory      = 1,
  iconType            = "chickenr",
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = "640",
  mass                = 40000,
  maxDamage           = 90000,
  maxSlope            = 18,
  maxVelocity         = 2,
  maxWaterDepth       = 15,
  hidedamage          = 1,
  turninplace         = 0,
  movementClass       = "CHICKQUEEN",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chicken_colonizer.s3o",
  seismicSignature    = 4,
  selfDestructAs      = "LOBBER_MORPH",
  collisionVolumeScales		= [[84 215 84]],
  collisionVolumeOffsets	= [[0 -1 0]],
  collisionVolumeTest	    = 1,
  collisionVolumeType	    = [[CylY]],

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
  sightDistance       = 1250,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 70,
  turnRate            = 1500,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = "METEORLAUNCHER",
      badTargetCategory  = "MOBILE",
      mainDir            = "0 0 1",
      onlyTargetCategory = "NOTAIR",
    },

  },


  weaponDefs          = {

    METEORLAUNCHER = {
      name                    = "METEORLAUNCHER",
	  turret=1,
	  model = "greyrock2.s3o",
	  range=18000,
	  reloadtime=15,
	  weaponvelocity=1500,
	  edgeeffectiveness=0,
	  areaofeffect=750,
      craterBoost             = 0,
      craterMult              = 0,
	  soundhit="xplonuk4",
	  explosionGenerator      = "custom:COMM_EXPLOSION",
	  firestarter=70,
	  targetable = 1,
	  CollideFriendly=0,
	  AvoidFriendly=0,
	  highTrajectory=1,
	  ProximityPriority=-6,
	  cegTag="ASTEROIDTRAIL_Expl",
      damage                  = {
        default = 2900,
        CHICKEN = 1500,
      },

    },
  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickenr3 = unitDef })
