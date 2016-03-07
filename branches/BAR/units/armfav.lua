return {
	armfav = {
		acceleration = 0.12,
		brakerate = 0.495,
		buildcostenergy = 365,
		buildcostmetal = 31,
		buildpic = "ARMFAV.DDS",
		buildtime = 912,
		canmove = true,
		category = "ALL TANK MOBILE WEAPON NOTSUB NOTSHIP NOTAIR NOTHOVER SURFACE GROUNDSCOUT",
		corpse = "DEAD",
		description = "Light Scout Vehicle",
		energymake = 0.2,
		energyuse = 0.2,
		explodeas = "SMALL_UNITEX",
		footprintx = 2,
		footprintz = 2,
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 80,
		maxslope = 26,
		maxvelocity = 6.4,
		maxwaterdepth = 12,
		movementclass = "TANK2",
		name = "Jeffy",
		nochasecategory = "VTOL",
		objectname = "ARMFAV.s3o",
		seismicsignature = 0,
		selfdestructas = "SMALL_UNIT",
		sightdistance = 585,
		turninplace = 0,
		turninplaceanglelimit = 140,
		turninplacespeedlimit = 4.224,
		turnrate = 1144,
		customparams = {
			faction = "arm",
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
		featuredefs = {
			dead = {
				blocking = false,
				category = "corpses",
				collisionvolumeoffsets = "0.351249694824 -0.179103781738 -0.672737121582",
				collisionvolumescales = "26.3068695068 15.9473724365 28.9309844971",
				collisionvolumetype = "Box",
				damage = 111,
				description = "Jeffy Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 4,
				hitdensity = 100,
				metal = 15,
				object = "armfav_dead.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 56,
				description = "Jeffy Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 4,
				hitdensity = 100,
				metal = 6,
				object = "arm2x2f.s3o",
				reclaimable = true,
				resurrectable = 0,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
		},
		sounds = {
			canceldestruct = "cancel2",
			underattack = "warning1",
			cant = {
				[1] = "cantdo4",
			},
			count = {
				[1] = "count6",
				[2] = "count5",
				[3] = "count4",
				[4] = "count3",
				[5] = "count2",
				[6] = "count1",
			},
			ok = {
				[1] = "varmmove",
			},
			select = {
				[1] = "varmsel",
			},
		},
		weapondefs = {
			arm_laser = {
				areaofeffect = 8,
				avoidfeature = false,
				beamtime = 0.18,
				burstrate = 0.2,
				corethickness = 0.3,
				craterareaofeffect = 0,
				craterboost = 0,
				cratermult = 0,
				duration = 0.02,
				energypershot = 2,
				explosiongenerator = "custom:SMALL_YELLOW_BURN",
				firestarter = 50,
				hardstop = true,
				impactonly = 1,
				impulseboost = 0,
				impulsefactor = 0,
				laserflaresize = 5,
				name = "Laser",
				noselfdamage = true,
				range = 180,
				reloadtime = 0.95,
				rgbcolor = "1 1 0.4",
				soundhitdry = "",
				soundhitwet = "sizzle",
				soundhitwetvolume = 0.5,
				soundstart = "lasrfir1",
				soundtrigger = 1,
				targetmoveerror = 0.2,
				thickness = 0.75,
				tolerance = 10000,
				turret = true,
				weapontype = "BeamLaser",
				weaponvelocity = 800,
				damage = {
					bombers = 2,
					default = 35,
					fighters = 2,
					subs = 2,
					vtol = 2,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "VTOL",
				def = "ARM_LASER",
				onlytargetcategory = "NOTSUB",
			},
		},
	},
}
