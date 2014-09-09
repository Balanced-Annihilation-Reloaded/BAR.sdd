unitDef = {
  unitname            = "chickenh5",
  name                = "Patriarch",
  description         = "Chicken Overseer",
  acceleration        = 0.8,
  bmcode              = "1",
  brakeRate           = 0.8,
  
  builder             = true,
  workertime          = 450,
  buildDistance       = 425,
  repairspeed         = 450,
  canReclaim          = false,
  canRestore          = false,
  nanoColor 		  = "0.7 0.15 0.15",
  
  buildCostEnergy     = 5200.8,
  buildCostMetal      = 250.8,
  buildTime           = 12000,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  autoHeal            = 8,
  canstop             = "1",
  category            = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
  corpse              = "DEAD",
  defaultmissiontype  = "Standby",
  explodeAs           = "BIGBUG_DEATH",
  floater             = false,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = "chicken",
  leaveTracks         = true,
  maneuverleashlength = 640,
  mass                = 3000,
  maxDamage           = 8000,
  maxSlope            = 18,
  maxVelocity         = 3.7,
  maxWaterDepth       = 15,
  turninplace         = 0,
  hidedamage          = 1,
  movementClass       = "AKBOT2",
  noAutoFire          = false,
  noChaseCategory     = "VTOL",
  objectName          = "brain_bug.s3o",
  selfDestructAs      = "BUG_DEATH",
  collisionVolumeType = "box",
  collisionVolumeOffsets = "0 10 2",
  collisionVolumeScales = "37 55 90",
  
  sfxtypes            = {

    explosiongenerators = {
      "custom:blood_spray",
      "custom:blood_explode",
      "custom:dirt",
      "custom:BRAIN_SPHERE_EMIT",
    },

  },

  side                = "THUNDERBIRDS",
  sightDistance       = 760,
  smoothAnim          = true,
  steeringmode        = "2",
  TEDClass            = "KBOT",
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = "ChickenTrack",
  trackWidth          = 18,
  turnRate            = 1300,
  upright             = false,
  waterline           = 8,

  weapons             = {

    {
      def                = "WEAPON",
      mainDir            = "0 0 1",
      maxAngleDif        = 120,
      onlyTargetCategory = "NOTAIR",
    },
    
    {
      def                = "CONTROLBLOB",
      mainDir            = "0 0 1",
      maxAngleDif        = 120,
      onlyTargetCategory = "NOTAIR",
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = "Claws",
      areaOfEffect            = 72,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 900,
        CHICKEN = 200,
      },

      endsmoke                = "0",
      explosionGenerator      = "custom:NONE",
      impulseBoost            = 2.2,
      impulseFactor           = 1,
      avoidFriendly           = 0,
      avoidFeature            = 0,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 165,
      reloadtime              = 4,
      soundStart              = "smallchickenattack",
      size                    = 0,
      startsmoke              = "0",
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponTimer             = 0.1,
      weaponType              = "Cannon",
      weaponVelocity          = 500,
    },
    
    CONTROLBLOB = {
      name                    = "ControlBlob",
      areaOfEffect            = 80,
      craterBoost             = 0,
      craterMult              = 0,
      edgeeffectiveness       = 0.25,
      camerashake             = 0,
      predictboost			  = 1,
      proximitypriority       = -2,

      damage                  = {      
        default=225,
		CHICKEN=10,
		TINYCHICKEN=10,  
      },

      endsmoke                = "0",
      explosionGenerator      = "custom:control_explode",
      cegTag                  = "blood_trail",
      impulseBoost            = 0,
      impulseFactor           = 0,
      avoidFriendly           = 0,
      collideFriendly         = 0,
      intensity               = 0.7,
      interceptedByShieldType = 0,
      avoidFeature            = 0,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 590,
      reloadtime              = 9.5,
      renderType              = 4,
      rgbColor                = "0.7 0.15 0.15",
      size                    = 18,
      sizeDecay               = -0.3,
      soundhit                = "junohit2edit",
      startsmoke              = "0",
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 3,
      weaponVelocity          = 420,
    },

  },


  featureDefs         = {

    DEAD = {
    },


    HEAP = {
    },

  },

}

return lowerkeys({ chickenh5 = unitDef })
