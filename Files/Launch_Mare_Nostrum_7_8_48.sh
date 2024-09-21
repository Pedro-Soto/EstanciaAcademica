#!/bin/sh

#BSUB -J   Sim_7_8
#SBATCH --ntasks=48
#BSUB -o output_%J.out
#BSUB -e output_%J.err
#BSUB -x # Exclusive use
#SBATCH --time=00-23:59:00

module load intel/2017.4 
module load impi/2017.4 
module load mkl/2017.4 
module load hdf5/1.8.19


cp   ../Base_files/* .

bash Change*sh 

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/Update_2018_01_11_Positive_only/trunk/src/petsc/arch-linux2-c-debug/lib

gcc -o Prep_cap capillary.c -lm
./Prep_cap > Capillary.dat

srun ./Ludwig.exe input7 > Output_7.out
srun ./Ludwig.exe input8 > Output_8.out

rm Capillary.dat
rm rho*001 rho*vtk

sbatch Launch_Analyse.sh
