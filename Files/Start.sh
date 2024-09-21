ulimit -s unlimited
bash Change_data.sh
gcc -o Prep_cap capillary.c -lm 
./Prep_cap > Capillary.dat 

mpirun -np 8 ./Ludwig.exe input  > Output.out
mpirun -np 8 ./Ludwig.exe input2 > Output_2.out


python vtk_Interface.py
python Drop_position.py

rm Interface_stat*dat
rm dist*001  
rm pthermo*
rm *001
rm *vtk

mkdir Finished
mv * Finished

