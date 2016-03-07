return {
	chickend1 = {
		acceleration = 0.01,
		activatewhenbuilt = true,
		autoheal = 1,
		brakerate = 0.01,
		buildcostenergy = 3000,
		buildcostmetal = 120,
		builddistance = 200,
		builder = true,
		buildpic = "CHICKEND1.DDS",
		buildtime = 1800,
		canattack = true,
		canreclaim = true,
		canrestore = false,
		canstop = "1",
		category = "WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 15 0",
		collisionvolumescales = "14 50 14",
		collisionvolumetype = "box",
		corpse = "DEAD",
		description = "Defense",
		energystorage = 500,
		explodeas = "custom:blood_explode",
		footprintx = 1,
		footprintz = 1,
		icontype = "defense",
		idleautoheal = 15,
		idletime = 300,
		levelground = false,
		mass = 700,
		maxdamage = 1125,
		maxslope = 255,
		maxvelocity = 0,
		maxwaterdepth = 0,
		movementclass = "NANO",
		name = "Chicken Tube",
		noautofire = false,
		nochasecategory = "MOBILE",
		objectname = "tube.s3o",
		reclaimspeed = 200,
		repairspeed = 125,
		seismicsignature = 0,
		selfdestructas = "custom:blood_explode",
		sightdistance = 370,
		turnrate = 1,
		upright = false,
		waterline = 1,
		workertime = 125,
		customparams = {
			faction = "chicken",
			normalmaps = "yes",
			normaltex = "unittextures/chicken_normal.tga",
		},
		featuredefs = {
			dead = {},
			heap = {},
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
				areaofeffect = 32,
				avoidfriendly = false,
				collidefriendly = false,
				craterboost = 0,
				cratermult = 0,
				dance = 20,
				explosiongenerator = "custom:NONE",
				firestarter = 0,
				flighttime = 5,
				groundbounce = 1,
				heightmod = 0.5,
				impulseboost = 0,
				impulsefactor = 0.4,
				interceptedbyshieldtype = 2,
				metalpershot = 0,
				model = "AgamAutoBurst.s3o",
				name = "Missiles",
				noselfdamage = true,
				range = 420,
				reloadtime = 2.2,
				smoketrail = true,
				startvelocity = 100,
				texture1 = "",
				texture2 = "sporetrail",
				tolerance = 10000,
				tracks = true,
				trajectoryheight = 2,
				turnrate = 24000,
				turret = true,
				waterweapon = true,
				weaponacceleration = 100,
				weapontype = "MissileLauncher",
				weaponvelocity = 500,
				wobble = 32000,
				damage = {
					bombers = 500,
					default = 400,
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
