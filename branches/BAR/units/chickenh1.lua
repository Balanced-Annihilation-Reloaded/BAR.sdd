return {
	chickenh1 = {
		acceleration = 0.05,
		activatewhenbuilt = true,
		autoheal = 32,
		bmcode = 1,
		brakerate = 0.2,
		buildcostenergy = 600,
		buildcostmetal = 40,
		builddistance = 200,
		builder = 1,
		buildpic = "chickenh1.dds",
		buildtime = 500,
		canassist = 0,
		canbuild = 1,
		canguard = 1,
		canmove = 1,
		canpatrol = 1,
		canrepair = 1,
		canstop = 1,
		category = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
		collide = 0,
		collisionvolumeoffsets = "0 -1 0",
		collisionvolumescales = "10 14 22",
		collisionvolumetype = "box",
		defaultmissiontype = "Standby",
		description = "Chicken Healer",
		energymake = 25,
		explodeas = "WEAVER_DEATH",
		floater = false,
		footprintx = 1,
		footprintz = 1,
		hidedamage = 1,
		icontype = "builder",
		kamikaze = true,
		kamikazedistance = 60,
		leavetracks = true,
		maneuverleashlength = 640,
		mass = 50,
		maxdamage = 225,
		maxslope = 18,
		maxvelocity = 2.6,
		maxwaterdepth = 5000,
		metalstorage = 1000,
		mobilestandorders = 1,
		movementclass = "KBOT2",
		name = "Weaver",
		noautofire = 0,
		objectname = "chicken_drone.s3o",
		reclaimspeed = 400,
		repairspeed = 200,
		seismicsignature = 1,
		selfdestructas = "WEAVER_DEATH",
		side = "THUNDERBIRDS",
		sightdistance = 256,
		smoothanim = true,
		standingmoveorder = 1,
		stealth = 1,
		steeringmode = "2",
		tedclass = "KBOT",
		trackoffset = 1,
		trackstrength = 6,
		trackstretch = 1,
		tracktype = "ChickenTrack",
		trackwidth = 10,
		turninplace = 0,
		turnrate = 568,
		unitname = "chickenh1",
		upright = false,
		waterline = 8,
		workertime = 200,
		customparams = {
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
	},
}
