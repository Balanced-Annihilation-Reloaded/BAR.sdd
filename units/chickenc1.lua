unitDef = {
  unitname            = "chickenc1",
  name                = "Basilisk",
  description         = "All-Terrain Assault",
  acceleration        = 1.25,
  bmcode              = "1",
  brakeRate           = 2,
  buildCostEnergy     = 5280,
  buildCostMetal      = 170,
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
  explodeAs           = "BIGBUG_DEATH",
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = "chickenr",
  leaveTracks         = true,
  maneuverleashlength = "640",
  mass                = 700,
  maxDamage           = 4250,
  turninplace         = 0,
  maxSlope            = 18,
  maxVelocity         = 2.5,
  maxreversevelocity  = 2,
  maxWaterDepth       = 15,
  movementClass       = "TKBOT3",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "chickenc.s3o",
  seismicSignature    = 3,
  selfDestructAs      = "BIGBUG_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 11 3",
  collisionVolumeScales = "25 38 64",

  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 512,
  smoothAnim          = true,
  sonarDistance       = 450,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 0.5,
  trackStrength       = 9,
  trackStretch        = 1,
  trackType           = "ChickenTrackPointy",
  trackWidth          = 70,
  turnRate            = 400,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = "WEAPON",
      mainDir            = "0 0 1",
      maxAngleDif        = 110,
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = "Blob",
      areaOfEffect            = 96,
      burst                   = 3,
      burstrate               = 0.01,
      craterBoost             = 0,
      craterMult              = 0,
      edgeeffectiveness       = 0,
      camerashake             = 0,

      damage                  = {      
        default=1250,
        bombers = 400,
        fighters = 400,
        vtol = 400,
		L1SUBS=335,
		L2SUBS=335,
		L3SUBS=335,
		SEADRAGON=335,
		BLACKHYDRA=335,
		TL=335,
		ATL=335,
		KROGOTH=335,
		ORCONE=335,
		MECHS=335,
		AMPHIBIOUS=335,
		COMMANDERS=335,
		CRAWLINGBOMBS=335,
		FLAMETHROWERS=335,
		MINES=335,
		PLASMAGUNS=335,
		ANTIRAIDER=335,
		ANTIBOMBER=335,
		ANTIFIGHTER=335,
		ANNIDDM=335,
		VULCBUZZ=335,
		NANOS=335,
		DL=335,
		FLAKS=335,
		FLAKBOATS=335,
		OTHERBOATS=335,
		ELSE=335,
		HEAVYUNITS=335,
		RADAR=335,
		CHICKEN=105,
		TINYCHICKEN=105,  
      },

      endsmoke                = "0",
      explosionGenerator      = "custom:blood_explode_blue",
      impulseBoost            = 0.22,
      impulseFactor           = 0.22,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      avoidFeature            = 0,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 3.6,
      renderType              = 4,
      rgbColor                = "0.0 0.6 0.6",
      size                    = 8,
      sizeDecay               = -0.3,
      sprayAngle              = 512,
      soundhit                = "junohit2edit",
      accuracy				  = 256,
      startsmoke              = "0",
      tolerance               = 5000,
      targetmoveerror         = 0.4,
      turret                  = true,
      weaponTimer             = 0.2,
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickenc1 = unitDef })
