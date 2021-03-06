return {
	chickenf1 = {
		acceleration = 0.8,
		airhoverfactor = 0,
		attackrunlength = 32,
		brakerate = 0.4,
		buildcostenergy = 4550,
		buildcostmetal = 212,
		builder = false,
		buildpic = "CHICKENF1.DDS",
		buildtime = 6250,
		canattack = true,
		canfly = true,
		canguard = true,
		canland = true,
		canmove = true,
		canpatrol = true,
		canstop = "1",
		cansubmerge = true,
		category = "VTOL MOBILE WEAPON NOTSUB NOTSHIP NOTHOVER ALL",
		collide = false,
		collisionvolumeoffsets = "0 8 -2",
		collisionvolumescales = "70 14 48",
		collisionvolumetype = "box",
		corpse = "DEAD",
		cruisealt = 240,
		description = "Flying Chicken Bomber",
		explodeas = "TALON_DEATH",
		footprintx = 3,
		footprintz = 3,
		hidedamage = 1,
		icontype = "chickenf",
		idleautoheal = 5,
		idletime = 0,
		maneuverleashlength = "20000",
		mass = 227.5,
		maxdamage = 1350,
		maxvelocity = 6.2,
		moverate1 = "32",
		name = "Talon",
		noautofire = false,
		nochasecategory = "VTOL",
		objectname = "chickenf.s3o",
		seismicsignature = 0,
		selfdestructas = "TALON_DEATH",
		sightdistance = 1000,
		turninplace = 0,
		turnrate = 900,
		workertime = 0,
		customparams = {
			faction = "chicken",
			normalmaps = "yes",
			normaltex = "unittextures/chicken_normal.tga",
		},
		featuredefs = {
			dead = {
				customparams = {
					faction = "chicken",
				},
			},
			heap = {
				customparams = {
					faction = "chicken",
				},
			},
		},
		sfxtypes = {
			explosiongenerators = {
				[1] = "custom:blood_spray",
				[2] = "custom:blood_explode",
				[3] = "custom:dirt",
			},
		},
		weapondefs = {
			weapon = {
				accuracy = 1000,
				areaofeffect = 128,
				avoidfeature = false,
				avoidfriendly = false,
				burst = 8,
				burstrate = 0.24,
				collidefriendly = false,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0.15,
				explosiongenerator = "custom:gundam_MISSILE_EXPLOSION",
				impulseboost = 1,
				impulsefactor = 1,
				interceptedbyshieldtype = 0,
				model = "chickeneggyellow.s3o",
				name = "GooBombs",
				noselfdamage = true,
				range = 800,
				reloadtime = 7,
				soundhit = "junohit2edit",
				sprayangle = 2000,
				weapontype = "AircraftBomb",
				damage = {
					antibomber = 155,
					chicken = 100,
					default = 310,
					tinychicken = 100,
				},
			},
		},
		weapons = {
			[1] = {
				def = "WEAPON",
			},
		},
	},
}
