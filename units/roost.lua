unitDef = {
  unitname          = "roost",
  name              = "Roost",
  description       = "Spawns Chicken",
  acceleration      = 0,
  activateWhenBuilt = true,
  bmcode            = "0",
  brakeRate         = 0,
  buildCostEnergy   = 25000,
  buildCostMetal    = 400,
  builder           = false,
  buildTime         = 7000,
  category          = "NOTAIR NOTSUB NOTSHIP NOTHOVER ALL SURFACE",
  explodeAs         = "ROOST_DEATH",
  footprintX        = 2,
  footprintZ        = 2,
  iconType          = "special",
  idleAutoHeal      = 10,
  idleTime          = 90,
  autoHeal			= 1.8,
  levelGround       = false,
  mass              = 165.75,
  energystorage     = 1000,
  maxDamage         = 1800,
  maxVelocity       = 0,
  seismicSignature  = 4,
  noAutoFire        = false,
  objectName        = "roost.s3o",
  selfDestructAs    = "ROOST_DEATH",
  
  builder  		    = true,
  workertime		= 1500,
  isAirbase 		= true,
  builddistance     = 90,

  sfxtypes          = {

    explosiongenerators = {
      "custom:dirt2",
      "custom:dirt3",
    },

  },

  side              = "ARM",
  sightDistance     = 450,
  radardistance     = 900,
  smoothAnim        = true,
  TEDClass          = "ENERGY",
  turnRate          = 0,
  upright           = false,
  waterline         = 0,
  workerTime        = 0,
  yardMap           = "ooooooooo",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 0 0",
  collisionVolumeScales = "56 11 56",
  
  weapons             = {

    {
      def                = "WEAPON",
    },

  },

  weaponDefs          = {

    WEAPON = {
      name = "Asteroid",
	  rendertype=1,
	  lineofsight=0,
	  turret=1,

	  model = "greyrock2.s3o",

	  range=29999,
	  reloadtime=5.0,
	  weapontimer=10,
	  weaponvelocity=2000,
	  startvelocity=2000,
	  weaponacceleration=120,
	  edgeeffectiveness=0,
	  areaofeffect=450,
	  metalpershot=0,
	  wobble=0,
      craterBoost             = 0,
      craterMult              = 0,

	  soundhit="xplonuk4",
	  explosionGenerator      = "custom:COMM_EXPLOSION",

	  firestarter=70,
	  smokedelay=0.1,
	  selfprop=1,
	  smoketrail=1,
	  flighttime=100,

	  startsmoke=1,
	  CollideFriendly=0,
	  AvoidFriendly=0,
	  cegTag="ASTEROIDTRAIL_Expl",

      damage                  = {
        default = 6000,
        CHICKEN = 10,
      },

    },
  },

  featureDefs       = {
  },

}

return lowerkeys({ roost = unitDef })
