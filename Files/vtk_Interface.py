########################################################################
#			   					       #
#  vtk_Droplet.py 					               #
#			   					       #
#  Script for creating data files in vtk-format for visualisation in   #
#  Paraview.						               #
#  Requires vtk_Droplet.c with corresponding flags set and	       #
#  an executable 'extract_colloids' for colloid processing. 	       #				
#								       #				
#  Usage: $> python vtk_Droplet.py			               #
#								       #
#  $Id: vtk_Droplet.py 2522 2014-11-05 15:20:06Z ohenrich $$           #
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
ngroup=1	# Number of output groups

vel=1		# Switch for velocity 
q=0			# Switch for Q-tensor postprocessing
phi=1		# Switch for binary fluid
psi=0		# Switch for electrokinetics
fed=0		# Switch for free energy
colloid=0	# Switch for colloid postprocessing
pthermo=0	# Switch for pthermo postprocessing
rho=1		# Switch for rho postprocessing

# Set lists for analysis
metafile=[]
filelist_interface=[]

if vel==1:
	metafile.append('vel.00%d-001.meta' % ngroup)
	filelist_interface.append('filelist_interface_vel')
	os.system('rm filelist_interface_vel')
	for i in range(nstart,nend+nint,nint):
		os.system('ls -t1 vel-%08.0d.00%d-001 >> filelist_interface_vel' % (i,ngroup))

if q==1:
	metafile.append('q.00%d-001.meta' % ngroup)
	filelist_interface.append('filelist_interface_q')
	os.system('rm filelist_interface_q')
	for i in range(nstart,nend+nint,nint):
		os.system('ls -t1 q-%08.0d.00%d-001 >> filelist_interface_q' % (i,ngroup))

if phi==1:
	metafile.append('phi.%03.0d-001.meta' % ngroup)
	filelist_interface.append('filelist_interface_phi')
	os.system('rm filelist_interface_phi')
	for i in range(nstart,nend+nint,nint):
		os.system('ls -t1 phi-%08.0d.%03.0d-001 >> filelist_interface_phi' % (i,ngroup))

if psi==1:
        metafile.append('psi.%03.0d-001.meta' % ngroup)
        filelist_interface.append('filelist_interface_psi')
        os.system('rm filelist_interface_psi')
        for i in range(nstart,nend+nint,nint):
                os.system('ls -t1 psi-%08.0d.%03.0d-001 >> filelist_interface_psi' % (i,ngroup))

if fed==1:
        metafile.append('fed.%03.0d-001.meta' % ngroup)
        filelist_interface.append('filelist_interface_fed')
        os.system('rm filelist_interface_fed')
        for i in range(nstart,nend+nint,nint):
                os.system('ls -t1 fed-%08.0d.%03.0d-001 >> filelist_interface_fed' % (i,ngroup))

os.system('gcc -o vtk_Interface.exe vtk_Interface.c -lm')

if colloid==1:
	metafile.append('')
	filelist_interface.append('filelist_interface_colloid')
	os.system('rm filelist_interface_colloid')
	for i in range(nstart,nend+nint,nint):
		os.system('ls -t1 config.cds%08.0d.001-001 >> filelist_interface_colloid' % i)

if pthermo==1:
	metafile.append('pthermo.%03.0d-001.meta' % ngroup)
	filelist_interface.append('filelist_pthermo')
	os.system('rm filelist_pthermo')
	for i in range(nstart,nend+nint,nint):
		os.system('ls -t1 pthermo-%08.0d.%03.0d-001 >> filelist_pthermo' % (i,ngroup))


if rho==1:
	metafile.append('rho.%03.0d-001.meta' % ngroup)
	filelist_interface.append('filelist_rho')
	os.system('rm filelist_rho')
	for i in range(nstart,nend+nint,nint):
		os.system('ls -t1 rho-%08.0d.%03.0d-001 >> filelist_rho' % (i,ngroup))


# Create vtk-files
for i in range(len(filelist_interface)):
	if filelist_interface[i] != 'filelist_interface_colloid':
		datafiles=open(filelist_interface[i],'r') 

		while 1:
			line=datafiles.readline()
			if not line: break

			print ('\n# Processing %s' % line )

			stub=line.split('.',1)
			os.system('./vtk_Interface.exe %s %s' % (metafile[i],stub[0]))

		datafiles.close

	if filelist_interface[i] == 'filelist_interface_colloid':
		datafiles=open(filelist_interface[i],'r') 

		while 1:
			line=datafiles.readline()
			if not line: break

			print ('\n# Processing %s' % line )

			stub=line.split('.',2)
			datafilename = ('%s.%s' % (stub[0], stub[1]))
			outputfilename = ('col-%s.csv' % stub[1])
			os.system('./extract_colloids %s %d %s' % (datafilename,ngroup,outputfilename))
	
os.system('rm filelist_interface*')
os.system('rm vtk_Interface.exe')

print('# Done')
