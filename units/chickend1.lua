unitDef = {
  unitname           = "chickend1",
  name               = "Chicken Tube",
  description        = "Defense",
  acceleration       = 0.01,
  activateWhenBuilt  = true,
  bmcode             = "0",
  brakeRate          = 0.01,
  buildCostEnergy    = 3000,
  buildCostMetal     = 120,
  buildTime          = 1800,
  canAttack          = true,
  canstop            = "1",
  category           = "WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  corpse             = "DEAD",
  energyStorage		 = 500,
  explodeAs          = "custom:blood_explode",
  extractsMetal      = 0.001,
  footprintX         = 1,
  footprintZ         = 1,
  iconType           = "defense",
  idleAutoHeal       = 15,
  idleTime           = 300,
  autoHeal			 = 1,
  levelGround        = false,
  mass               = 700,
  maxDamage          = 1125,
  maxSlope           = 255,
  maxVelocity        = 0,
  seismicSignature   = 0,
  maxWaterDepth      = 0,
  noAutoFire         = false,
  movementclass 	 = "NANO",
  noChaseCategory    = "MOBILE",
  objectName         = "tube.s3o",
  selfDestructAs     = "custom:blood_explode",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 15 0",
  collisionVolumeScales = "14 50 14",
  
  builder			= true,
  workertime		= 125,
  buildDistance     = 200,
  reclaimSpeed		= 200,
  repairSpeed		= 125,
  canReclaim        = true,
  canRestore        = false,

  customparams = { 
    normalmaps = "yes", 
    normaltex = "unittextures/chicken_normal.tga", 
  },

  sfxtypes           = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
    },

  },

  side               = "THUNDERBIRDS",
  sightDistance      = 370,
  smoothAnim         = true,
  TEDClass           = "METAL",
  turnRate           = 1,
  upright            = false,
  waterline          = 1,

  weapons            = {

    {
      def = "WEAPON",
    },

  },


  weaponDefs         = {

    WEAPON = {
      name                    = "Missiles",
      areaOfEffect            = 32,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 400,
        bombers = 500,
      },

      dance                   = 20,
      explosionGenerator      = "custom:NONE",
      fireStarter             = 0,
      flightTime              = 5,
      groundbounce            = 1,
      guidance                = true,
      heightmod               = 0.5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = "AgamAutoBurst.s3o",
      noSelfDamage            = true,
      range                   = 420,
      reloadtime              = 2.2,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = "0.1",
      smokeTrail              = true,
      startsmoke              = "1",
      startVelocity           = 100,
      texture1                = "",
      texture2                = "sporetrail",
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 2,
      turnRate                = 24000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 100,
      weaponType              = "MissileLauncher",
      weaponVelocity          = 500,
      wobble                  = 32000,
    },

  },


  featureDefs        = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickend1 = unitDef })
