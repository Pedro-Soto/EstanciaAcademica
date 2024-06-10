#!/bin/bash
ulimit -s unlimited
bash Change_data.sh
rm *.sh.*
gcc -o Prep_cap capillary.c -lm
./Prep_cap > Capillary.dat

mpirun -np 16 ./Ludwig.exe input  > Output.out
mpirun -np 16 ./Ludwig.exe input2  > Output2.out
#mpirun -np 16 ./Ludwig.exe input3  > Output3.out
#mpirun -np 16 ./Ludwig.exe input4  > Output4.out
#mpirun -np 16 ./Ludwig.exe input5  > Output5.out
#mpirun -np 16 ./Ludwig.exe input6  > Output6.out
#mpirun -np 16 ./Ludwig.exe input7  > Output7.out
#mpirun -np 16 ./Ludwig.exe input8  > Output8.out
#mpirun -np 16 ./Ludwig.exe input9  > Output9.out
#mpirun -np 16 ./Ludwig.exe input10  > Output10.out



rm rho*
python3 vtk_Interface.py  ;
python3 Drop_position.py;
rm Interface_stat_y_*.dat Capillary.dat *.vtk
echo "DONE"

