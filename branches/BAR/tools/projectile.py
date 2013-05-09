import os
import sys
out=open('projectile.txt','w')
for filename in os.listdir(os.getcwd()):
	if '.lua' in filename:
		lualn=open(filename).readlines();
		for l in lualn:
			if 'model =' in l:
				print filename, l.partition('=')[2].strip()
				out.write(filename+' '+l.partition('=')[2].strip()+'\n')