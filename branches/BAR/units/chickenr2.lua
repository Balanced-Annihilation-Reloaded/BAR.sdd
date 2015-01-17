unitDef = {
  unitname            = "chickenr2",
  name                = "Enraged Lobber",
  description         = "Chicken Assault",
  acceleration        = 0.9,
  activateWhenBuilt   = true,
  bmcode              = "1",
  brakeRate           = 0.7,
  buildCostEnergy     = 15000,
  buildCostMetal      = 250,
  builder             = false,
  buildTime           = 3000,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  defaultmissiontype  = "Standby",
  explodeAs           = "WEAVER_DEATH",
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = "chicken",
  leaveTracks         = true,
  maneuverleashlength = "640",
  mass                = 600,
  autoheal            = 50,
  maxDamage           = 4500,
  maxVelocity         = 4.5,
  turninplace         = 0,
  movementClass       = "CHICKENHKBOT3",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chickenr.s3o",
  seismicSignature    = 4,
  selfDestructAs      = "WEAVER_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 -2 0",
  collisionVolumeScales = "25 31 44",

  customparams = { 
    normalmaps = "yes", 
    normaltex = "unittextures/chicken_normal.tga", 
  },

  sfxtypes            = {

    explosiongenerators = {
      "custom:ANGRYLOBBERTRAIL",
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 200,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 0,
  trackStrength       = 6,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 35,
  turnRate            = 900,
  upright             = false,
  workerTime          = 0,

  weapons             = {
    
    {
      def                = "CHASEWEAPON",
      mainDir            = "0 0 1",
      onlyTargetCategory = "NOTAIR",
      badTargetCategory  = "VTOL",
    }, 
    
    {
      def                = "FLAMER",
      mainDir            = "0 0 1",
      maxAngleDif        = 120,
      badTargetCategory  = "VTOL",
      onlyTargetCategory = "NOTAIR",
    },

  },


  weaponDefs          = {

    CHASEWEAPON = {
		name="Claws",
        craterBoost             = 0,
        craterMult              = 0,
        toAirWeapon             = 0,

        damage                  = {
          default = 0.001,
        },
      
      endsmoke                = "0",
      explosionGenerator      = "custom:NONE",
      impulseBoost            = 0,
      impulseFactor           = 0,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 100,
      reloadtime              = 30,
      size                    = 0.001,
      startsmoke              = "0",
      targetborder            = 1,
      tolerance               = 5000,
      weaponType              = "Cannon",
      weaponVelocity          = 500,
      turret                  = "true",
      proximityPriority       = -4,
    },

    FLAMER = {
		name="PlasmaThrower",
		rendertype=5,
		lineofsight="true",
		turret="true",
		range= 310,
		reloadtime=0.7,
        avoidFriendly=0,
        avoidFeature=0,
		weapontimer=1,
		sizegrowth=1.2,
		intensity=0.9,
		colormap="0.3 0.5 1.0 0.7 0.6 0.9 1 0.01",
		flamegfxtime=0.7,
		weaponvelocity=300,
		targetmoveerror=0.001,
		areaofeffect=64,
		burst=12,
		burstrate=0.01,
		toAirWeapon = 0,
		sprayangle=1200,
		randomdecay=0.2,
		soundstart="Flamhvy1",
		soundtrigger=0,
		firestarter=100,
		groundbounce=1,
		smokedelay=1,
		startsmoke=0,
		endsmoke=0,
		impulsefactor=0,
		impulseboost=0,
		cratermult=0,
		proximityPriority=4,
		craterboost=0,
		noselfdamage=true,
		weapontype = "Flame",
		tolerance=2500,
		damage = {
			default=40,
			CHICKEN=4,
            TINYCHICKEN=2,
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

return lowerkeys({ chickenr2 = unitDef })
