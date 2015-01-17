unitDef = {
  unitname            = "chickens1",
  name                = "Spiker",
  description         = "Spike Spitter",
  acceleration        = 1.5,
  bmcode              = "1",
  brakeRate           = 1.25,
  buildCostEnergy     = 174,
  buildCostMetal      = 174,
  builder             = false,
  buildTime           = 2500,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP NOTHOVER ALL SURFACE",
  corpse              = "DEAD",
  defaultmissiontype  = "Standby",
  explodeAs           = "BUG_DEATH",
  floater             = false,
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = "chickens",
  idleAutoHeal        = 18,
  idleTime            = 20,
  leaveTracks         = true,
  maneuverleashlength = "750",
  mass                = 900,
  maxDamage           = 820,
  maxSlope            = 18,
  maxVelocity         = 5,
  maxWaterDepth       = 15,
  seismicSignature    = 0,
  turninplace         = 0,
  movementClass       = "AKBOT2",
  noChaseCategory     = "VTOL",
  noAutoFire          = false,
  objectName          = "chickens.s3o",
  selfDestructAs      = "BUG_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 -3 0",
  collisionVolumeScales = "21 30 46",

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
  sightDistance       = 390,
  sonardistance       = 720,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "AKBOT2",
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 28,
  turnRate            = 1800,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def         = "WEAPON",
      mainDir     = "0 0 1",
      maxAngleDif = 120,
      badTargetCategory  = "VTOL",
    },
    
    {
      def         = "WATERWEAPON",
      mainDir     = "0 0 1",
      maxAngleDif = 160,
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = "Spike",
      areaOfEffect            = 16,
      avoidFeature            = true,
      avoidFriendly           = false,
      burnblow                = true,
      collideFeature          = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      edgeeffectiveness       = 0,

      damage                  = {
        default = 325,
        bombers = 500,
        fighters = 500,
        vtol = 500,
      },

      explosionGenerator      = "custom:dirt",
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      lineOfSight             = true,
      model                   = "spike.s3o",
      noSelfDamage            = true,
      propeller               = "1",
      avoidFeature            = 0,
      range                   = 375,
      reloadtime              = 2,
      renderType              = 1,
      selfprop                = true,
      startVelocity           = 300,
      subMissile              = 1,
      turret                  = true,
      waterWeapon             = false,
      targetMoveError         = 0.5,
      weaponAcceleration      = 70,
      interceptedByShieldType = 0,
      weaponTimer             = 1,
      weaponType              = "Cannon",
      weaponVelocity          = 325,
      avoidfriendly           = 0,
    },
  
  	WATERWEAPON = { 
  	name="Sea Spike",
	rendertype=1,
	lineofsight=1,
	turret=1,
	model = "spike.s3o",
	propeller=1,
	range=690,
	reloadtime=9,
	weapontimer=4,
	
	damage =
	{
		default=775,
	},
	
	weaponvelocity=220,
	startvelocity=150,
	weaponacceleration=25,
	turnrate=1500,
	areaofeffect=16,
	soundstart=torpedo1,
	soundhit=xplodep1,
	guidance=1,
	tracks=1,
	selfprop=1,
	waterweapon=true,
	fireSubmersed=true,
	burnblow=1,
	tolerance=32767,
	explosiongenerator="custom:dirt",
	impulsefactor=0.123,
	impulseboost=0.123,
	cratermult=0,
	craterboost=0,
	noselfdamage=1,
	avoidfriendly=0,
	collidefriendly=0,
	interceptedByShieldType = 0,
	},
	
  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickens1 = unitDef })
