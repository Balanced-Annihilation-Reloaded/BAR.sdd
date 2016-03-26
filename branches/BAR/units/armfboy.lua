return {
	armfboy = {
		acceleration = 0.12,
		brakerate = 0.375,
		buildcostenergy = 11939,
		buildcostmetal = 1513,
		buildpic = "ARMFBOY.DDS",
		buildtime = 22397,
		canmove = true,
		category = "KBOT WEAPON ALL NOTSUB NOTAIR NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 0 0",
		collisionvolumescales = "26 37 38",
		collisionvolumetype = "Box",
		corpse = "DEAD",
		description = "Heavy Plasma Kbot",
		energymake = 5.1,
		energyuse = 5,
		explodeas = "BIG_UNITEX",
		footprintx = 3,
		footprintz = 3,
		idleautoheal = 5,
		idletime = 1800,
		mass = 5001,
		maxdamage = 7000,
		maxslope = 20,
		maxvelocity = 1,
		maxwaterdepth = 25,
		movementclass = "HKBOT3",
		name = "Fatboy",
		nochasecategory = "VTOL",
		objectname = "ARMFBOY.s3o",
		pushresistant = true,
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 510,
		turninplaceanglelimit = 140,
		turninplacespeedlimit = 0.66,
		turnrate = 320,
		customparams = {
			faction = "arm",
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "1.35855102539 -5.79698309326 2.2872467041",
				collisionvolumescales = "33.431427002 25.3690338135 53.5839233398",
				collisionvolumetype = "Box",
				damage = 4200,
				description = "Fatboy Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 9,
				hitdensity = 100,
				metal = 1008,
				object = "armfboy_dead.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "all",
				customparams = {
					faction = "arm",
				},
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 2100,
				description = "Fatboy Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				hitdensity = 100,
				metal = 403,
				object = "arm2x2a.s3o",
				reclaimable = true,
				resurrectable = 0,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "all",
				customparams = {
					faction = "arm",
				},
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
				[1] = "mavbot1",
			},
			select = {
				[1] = "capture2",
			},
		},
		weapondefs = {
			arm_fatboy_notalaser = {
				areaofeffect = 240,
				avoidfeature = false,
				craterareaofeffect = 240,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0.7,
				energypershot = 0,
				explosiongenerator = "custom:FLASH224",
				gravityaffected = "true",
				impulseboost = 0.4,
				impulsefactor = 0.4,
				name = "HeavyPlasma",
				noselfdamage = true,
				range = 700,
				reloadtime = 6.75,
				soundhit = "bertha6",
				soundhitwet = "splslrg",
				soundhitwetvolume = 0.5,
				soundstart = "BERTHA1",
				turret = true,
				weapontype = "Cannon",
				weaponvelocity = 307.40851,
				customparams = {
					lups_shockwave = "1",
				},
				damage = {
					bombers = 111,
					default = 800,
					fighters = 111,
					subs = 5,
					vtol = 111,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "VTOL",
				def = "ARM_FATBOY_NOTALASER",
				onlytargetcategory = "SURFACE",
			},
		},
	},
}
