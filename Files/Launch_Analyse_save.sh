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
python3 vtk_Interface.py  ;
python3 Drop_position.py > Output_Analyse.out ;

grep "Pegado" Output_Analyse.out > Pegado.dat ;

grep "Got Interface position wall low time" Output_Analyse.out > Posicion_Interface_low.dat
sed -i -e "s/Got Interface position wall low time//g" Posicion_Interface_low.dat
sed -i -e "s/and center//g" Posicion_Interface_low.dat
sed -i -e "s/-> length//g" Posicion_Interface_low.dat

grep "Got Interface position wall large time" Output_Analyse.out > Posicion_Interface_large.dat
sed -i -e "s/Got Interface position wall large time//g" Posicion_Interface_large.dat
sed -i -e "s/and center//g" Posicion_Interface_large.dat
sed -i -e "s/-> length//g" Posicion_Interface_large.dat

rm Interface_stat_y_*.dat Capillary.dat *.vtk
echo "DONE"

mkdir Finished ; 
mv * Fini*/
