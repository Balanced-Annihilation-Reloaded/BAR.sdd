import os
info={}

def blocksize(bosfile, start):
	depth=1
	offset=start+2
	while (depth>0):
		if '{' in bosfile[offset]:
			depth+=1
		if '}' in bosfile[offset]:
			depth-=1
		offset+=1
	return offset-start
	

for filename in os.listdir(os.getcwd()):
	#try to open the lua def
	
	if '.bos' in filename:
		fpx=3
		try:
		bosfile=open(filename).readlines()
		info[filename]=[0,0]
		for i in range(len(bosfile)):
			line=bosfile[i]
			if 'RockUnit' in line:
				info[filename][0]=blocksize(bosfile,i)
			if 'HitByWeapon' in line:
				info[filename][1]=blocksize(bosfile,i)
for key in sorted(info.keys()):
	print '%s	%i	%i'%(key, info[key][0],info[key][1])
	
	
	
	'''
//////////////AIR HITBY
HitByWeapon(anglex, anglez)
{
	turn base to z-axis <0> - anglez speed <105.000000>;
	turn base to x-axis <0> - anglex speed <105.000000>;
	wait-for-turn base around z-axis;
	wait-for-turn base around x-axis;
	turn base to z-axis <0.000000> speed <15.000000>;
	turn base to x-axis <0.000000> speed <15.000000>;
}


////// ground hitby
HitByWeapon(anglex, anglez)
{
	turn base to z-axis <0> - anglez speed <105.000000>;
	turn base to x-axis <0> - anglex speed <105.000000>;
	wait-for-turn base around z-axis;
	wait-for-turn base around x-axis;
	turn base to z-axis <0.000000> speed <30.000000>;
	turn base to x-axis <0.000000> speed <30.000000>;
}

//pelvis hitby:

HitByWeapon(anglex, anglez)
{
	turn pelvis to z-axis <0> - anglez speed <105.000000>;
	turn pelvis to x-axis <0> - anglex speed <105.000000>;
	wait-for-turn pelvis around z-axis;
	wait-for-turn pelvis around x-axis;
	turn pelvis to z-axis <0.000000> speed <30.000000>;
	turn pelvis to x-axis <0.000000> speed <30.000000>;
}
HitByWeapon(anglex, anglez)
{
	turn torso to z-axis <0> - anglez speed <105.000000>;
	turn torso to x-axis <0> - anglex speed <105.000000>;
	wait-for-turn torso around z-axis;
	wait-for-turn torso around x-axis;
	turn torso to z-axis <0.000000> speed <30.000000>;
	turn torso to x-axis <0.000000> speed <30.000000>;
}
HitByWeapon(anglex, anglez)
{
	turn body to z-axis <0> - anglez speed <105.000000>;
	turn body to x-axis <0> - anglex speed <105.000000>;
	wait-for-turn body around z-axis;
	wait-for-turn body around x-axis;
	turn body to z-axis <0.000000> speed <30.000000>;
	turn body to x-axis <0.000000> speed <30.000000>;
}

HitByWeapon(anglex, anglez)
{
	turn hip to z-axis <0> - anglez speed <105.000000>;
	turn hip to x-axis <0> - anglex speed <105.000000>;
	wait-for-turn hip around z-axis;
	wait-for-turn hip around x-axis;
	turn hip to z-axis <0.000000> speed <30.000000>;
	turn hip to x-axis <0.000000> speed <30.000000>;
}



//cannon rockunit:

RockUnit(anglex, anglez)
{
	turn base to x-axis anglex speed <50.000000>;
	turn base to z-axis anglez speed <50.000000>;
	wait-for-turn base around z-axis;
	wait-for-turn base around x-axis;
	turn base to z-axis <0.000000> speed <20.000000>;
	turn base to x-axis <0.000000> speed <20.000000>;
}


//cannon rockunit PELVIS:

RockUnit(anglex, anglez)
{
	turn pelvis to x-axis anglex speed <50.000000>;
	turn pelvis to z-axis anglez speed <50.000000>;
	wait-for-turn pelvis around z-axis;
	wait-for-turn pelvis around x-axis;
	turn pelvis to z-axis <0.000000> speed <20.000000>;
	turn pelvis to x-axis <0.000000> speed <20.000000>;
}


RockUnit(anglex, anglez)
{
	turn body to x-axis anglex speed <50.000000>;
	turn body to z-axis anglez speed <50.000000>;
	wait-for-turn body around z-axis;
	wait-for-turn body around x-axis;
	turn body to z-axis <0.000000> speed <20.000000>;
	turn body to x-axis <0.000000> speed <20.000000>;
}
RockUnit(anglex, anglez)
{
	turn torso to x-axis anglex speed <50.000000>;
	turn torso to z-axis anglez speed <50.000000>;
	wait-for-turn torso around z-axis;
	wait-for-turn torso around x-axis;
	turn torso to z-axis <0.000000> speed <20.000000>;
	turn torso to x-axis <0.000000> speed <20.000000>;
}

'''