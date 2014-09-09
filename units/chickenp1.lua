unitDef = {
  unitname            = "chickenp1",
  name                = "Bombardier",
  description         = "Chicken Flamer",
  acceleration        = 1,
  activateWhenBuilt   = true,
  bmcode              = "1",
  brakeRate           = 0.6,
  buildCostEnergy     = 6000,
  buildCostMetal      = 200,
  builder             = false,
  buildPic            = "",
  buildTime           = 5000,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  defaultmissiontype  = "Standby",
  explodeAs           = "FLAMEBUG_DEATH",
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = "chicken",
  autoHeal            = 27,
  leaveTracks         = true,
  maneuverleashlength = "640",
  mass                = 1800,
  maxDamage           = 2700,
  maxVelocity         = 3,
  seismicSignature    = 0,
  turninplace         = 0,
  movementClass       = "CHICKENHKBOT3",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chicken_listener.s3o",
  selfDestructAs      = "FLAMEBUG_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 2 0",
  collisionVolumeScales = "30 38 60",
  
  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 300,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 50,
  turnRate            = 950,
  upright             = false,
  workerTime          = 0,

  weapons             = {
    
    {
      def                = "CHASEWEAPON",
      mainDir            = "0 0 1",
      onlyTargetCategory = "NOTAIR", 
    }, 
    
    {
      def                = "FLAMER",
      mainDir            = "0 0 1",
      maxAngleDif        = 120,
      badTargetCategory  = "VTOL",
      
    },

  },


  weaponDefs          = {

    CHASEWEAPON = {
		name="Claws",
        craterBoost             = 0,
        craterMult              = 0,

        damage                  = {
          default = 0.001,
        },
      
      endsmoke                = "0",
      explosionGenerator      = "custom:NONE",
      impulseBoost            = 0,
      toAirWeapon             = 0,
      impulseFactor           = 0,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 150,
      reloadtime              = 30,
      size                    = 0.00001,
      startsmoke              = "0",
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = "true",
      weaponType              = "Cannon",
      weaponVelocity          = 500,
      proximityPriority       = -4,
    },

    FLAMER = {
		name="FlameThrower",
		rendertype=5,
		lineofsight="true",
		turret="true",
		range= 410,
		reloadtime=0.7,
        avoidFriendly=0,
        avoidFeature=0,
		weapontimer=1,
		sizegrowth=1.2,
		intensity=0.9,
		rgbcolor="1 0.95 0.9",
		rgbcolor2="0.9 0.85 0.8",
		flamegfxtime=1.9,
		weaponvelocity=300,
		targetmoveerror=0.001,
		areaofeffect=64,
		burst=12,
		burstrate=0.01,
		toAirWeapon = 0,
		sprayangle=1800,
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
			default=32,
			COMMANDERS=20,
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

return lowerkeys({ chickenp1 = unitDef })
