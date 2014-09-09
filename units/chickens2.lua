unitDef = {
  unitname            = "chickens2",
  name                = "Advanced Spiker",
  description         = "Ghost Spiker",
  acceleration        = 3,
  bmcode              = "1",
  brakeRate           = 3,
  buildCostEnergy     = 174,
  buildCostMetal      = 174,
  builder             = false,
  buildTime           = 7000,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  corpse              = "DEAD",
  defaultmissiontype  = "Standby",
  explodeAs           = "BUG_DEATH",
  floater             = false,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = "chickens",
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = "750",
  mass                = 300,
  maxDamage           = 5000,
  maxSlope            = 18,
  maxVelocity         = 9,
  maxWaterDepth       = 15,
  seismicSignature    = 0,
  turninplace         = 0,
  cloakable           = 1,
  initcloaked         = 1,
  cloakCost           = 0,
  cloakCostMoving     = 0,
  minCloakDistance    = 200,
  movementClass       = "AKBOT2",
  noChaseCategory     = "VTOL",
  noAutoFire          = false,
  objectName          = "chickens2.s3o",
  selfDestructAs      = "BUG_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 -1 0",
  collisionVolumeScales = "24 34 53",

  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 720,
  sonardistance       = 720,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "AKBOT2",
  trackOffset         = 6,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 30,
  turnRate            = 1900,
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
        default = 1130,		
        bombers = 1500,
        fighters = 1500,
        vtol = 1500,
      },

      explosionGenerator      = "custom:ASPIKER",
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      lineOfSight             = true,
      model                   = "spike.s3o",
      noSelfDamage            = true,
      guidance                = false,
      propeller               = "1",
      avoidFeature            = 0,
      range                   = 470,
      reloadtime              = 3.25,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = "0.1",
      smokeTrail              = true,
      startVelocity           = 600,
      startsmoke              = "1",
      texture1                = "",
      texture2                = "sporetrail",
      turret                  = true,
      waterWeapon             = false,
      interceptedByShieldType = 0,
      weaponTimer             = 1,
      weaponType              = "MissileLauncher",
      weaponVelocity          = 600,
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
	reloadtime=5,
	weapontimer=4,
	
	damage =
	{
		default=1500,
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

return lowerkeys({ chickens2 = unitDef })
