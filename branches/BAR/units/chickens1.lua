unitDef = {
  unitname            = "chickens1",
  name                = "Spiker",
  description         = "Spike Spitter",
  acceleration        = 1.25,
  bmcode              = "1",
  brakeRate           = 1.25,
  buildCostEnergy     = 174,
  buildCostMetal      = 174,
  builder             = false,
  buildTime           = 2740,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL SURFACE",
  corpse              = "DEAD",
  defaultmissiontype  = "Standby",
  explodeAs           = "BUG_DEATH",
  floater             = false,
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = "chickens",
  idleAutoHeal        = 15,
  idleTime            = 90,
  leaveTracks         = true,
  maneuverleashlength = "750",
  mass                = 300,
  maxDamage           = 800,
  maxSlope            = 18,
  maxVelocity         = 2.9,
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

  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 370,
  sonardistance       = 720,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "AKBOT2",
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 30,
  turnRate            = 1000,
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
        default = 400,
        bombers = 600,
        fighters = 600,
        vtol = 600,
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
      reloadtime              = 2.2,
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
	waterweapon=1,
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
