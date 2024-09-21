########################################################################
#			   					       #
#  vtk_extract_script.py 					       #
#			   					       #
#  Script for creating data files in vtk-format for visualisation in   #
#  Paraview.						               #
#  Requires vtk_extract.c with corresponding flags set and	       #
#  an executable 'extract_colloids' for colloid processing. 	       #				
#								       #				
#  Usage: $> python vtk_extract_script.py			       #
#								       #
#  $Id: vtk_extract_script.py 2522 2014-11-05 15:20:06Z ohenrich $$    #
#								       #	
#  Edinburgh Soft Matter and Statistical Physics Group and	       #
#  Edinburgh Parallel Computing Centre				       #
#								       #	
#  Oliver Henrich (ohenrich@epcc.ed.ac.uk)			       #
#  (c) 2014 The University of Edinburgh				       #
#			   					       #
########################################################################

import sys, os, re, math

nstart = 0        # Start timestep
nint = FREQ2       # Increment
nend = (CYCLES1+CYCLES2)     # End timestep

phi=1		# Switch for binary fluid

# Set lists for analysis
DropList=[]






os.system('rm Interface_*visc*dat')
os.system('rm Drop_position.exe')
os.system('bash Extract_fP.sh')


if phi==1:
	DropList.append('DropList_phi')
	os.system('rm DropList_phi')
	for i in range(nstart,nend+nint,nint):
		os.system('ls -t1 phi-%08.0d.vtk >> DropList_phi' % i)

os.system('gcc -O2 -o Drop_position.exe Drop_position.c -lm')
os.system('gcc -O2 -o Drop_position2.exe Drop_position2.c -lm')


for i in range(len(DropList)):
	datafiles=open(DropList[i],'r') 

	while 1:
		line=datafiles.readline()


		if not line: break

#		print '\n# Processing %s' % line 

		os.system('echo "%s" > Phi.temp' % line)
		os.system('cp Phi.temp Time.temp')
		os.system('sed -i -e "s/phi-/-/g" Time.temp')	

		os.system('cp Phi.temp Time2.temp')
		os.system('sed -i -e "s/phi-/ /g" Time2.temp')	
		os.system('sed -i -e "s/.vtk/ /g" Time2.temp')	

		os.system('./Drop_position.exe %s' % line)
                os.system('./Drop_position2.exe %s' % line)

		

		datafiles.close




os.system('sed -i -e "s/phi-/ /g" *.dat')
os.system('sed -i -e "s/.vtk/ /g" *.dat')
os.system('rename "s/.vtk.dat/.dat/g" *.dat')
os.system('rename "s/_phi-/_/g" *.dat')

print('# Now starting the final processing')

os.system('rm Drop_position.exe')
os.system('rm Drop_position2.exe')

os.system('rm Time2.temp')
os.system('rm Time.temp')

#os.system('wc -l Average_position_temp.dat > Nb_line.temp ')
#os.system('sed -i -e "s/Average_position_temp.dat/ /g" Nb_line.temp ')

#os.system('wc -l Drop_stat.dat > Nb_line_drop.temp ')
#os.system('sed -i -e "s/Drop_stat.dat/ /g" Nb_line_drop.temp ')




#os.system('gcc -O2 -o Exec_Interface_final.exe Interface_position_final.c -lm  ')
#os.system('./Exec_Interface_final.exe %s' % line)
#os.system('rm DropList_phi')
#os.system('rm Exec_Interface.exe')
#os.system('rm Exec_Interface_final.exe')
#os.system('rm filelist_psi')
#os.system('rm filelist_phi')
#os.system('rm filelist_vel')
#os.system('rm *vtk')
#os.system('rm Time.temp')
#os.system('rm Time2.temp')
#os.system('rm Phi.temp')

#os.system('rm Nb_line.temp')
#os.system('rm Average_position_temp.dat')
#os.system('rm Interface_stat*.dat')

#print('# Done')
