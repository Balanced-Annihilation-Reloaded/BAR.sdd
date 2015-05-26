return {
	armnanotc = {
		acceleration = 0,
		brakerate = 4.5,
		buildcostenergy = 3021,
		buildcostmetal = 197,
		builddistance = 400,
		builder = true,
		buildpic = "ARMNANOTC.DDS",
		buildtime = 5312,
		cantbetransported = false,
		category = "ALL NOTSUB CONSTR NOWEAPON NOTAIR NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 0 0",
		collisionvolumescales = "31 32 31",
		collisionvolumetype = "CylY",
		description = "Repairs and builds in large radius",
		energyuse = 30,
		explodeas = "NANOBOOM2",
		footprintx = 3,
		footprintz = 3,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		mass = 700,
		maxdamage = 500,
		maxslope = 10,
		maxwaterdepth = 0,
		movementclass = "NANO",
		name = "Nano Turret",
		objectname = "ARMNANOTC.s3o",
		seismicsignature = 0,
		selfdestructas = "TINY_BUILDINGEX",
		sightdistance = 380,
		terraformspeed = 1000,
		turnrate = 1,
		upright = true,
		workertime = 200,
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
		sounds = {
			build = "nanlath1",
			canceldestruct = "cancel2",
			repair = "repair1",
			underattack = "warning1",
			working = "reclaim1",
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
	},
}
