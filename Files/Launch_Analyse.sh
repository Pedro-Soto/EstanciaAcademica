#!/bin/sh

#BSUB -J   Autom_Analyse
#SBATCH --ntasks=1
#BSUB -o output_%J.out
#BSUB -e output_%J.err
#BSUB -x # Exclusive use
#SBATCH --time=00-23:59:00




module load intel/2017.4 
module load impi/2017.4 
module load mkl/2017.4 
module load hdf5/1.8.19


bash Change*sh 

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/Update_2018_01_11_Positive_only/trunk/src/petsc/arch-linux2-c-debug/lib

rm rho*

gcc -o vtk_Interface.exe vtk_Interface.c -lm
gcc -O2 -o Drop_position.exe Drop_position.c -lm
gcc -O2 -o Drop_position2.exe Drop_position2.c -lm

for f in phi*001 ; do echo $f; ./vtk_Interface.exe phi.001-001.meta $f; done
for f in vel*001 ; do echo $f; ./vtk_Interface.exe vel.001-001.meta $f; done

for f in phi*vtk; 
	do echo $f; 
	ls -v $f > Phi.temp; 
	cp Phi.temp Time.temp; 
	sed -i -e "s/phi-/-/g" Time.temp; 
	cp Phi.temp Time2.temp;  
	sed -i -e "s/phi-/ /g" Time2.temp; 
	sed -i -e "s/.vtk/ /g" Time2.temp; 
	tail Time*temp Phi.temp ; 
	./Drop_position.exe $f ; 
	./Drop_position2.exe $f; 
done


rm Interface_stat_y_*.dat Capillary.dat *.vtk
echo "DONE"

mkdir Finished ; 
mv * Fini*/
