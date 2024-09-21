echo "#Beginning analysis"

wc -l Interface_low_viscosity.dat > Nb_lines_Interface_low_viscosity.temp
wc -l Interface_large_viscosity.dat > Nb_lines_Interface_large_viscosity.temp

cp ../../Base_files/Analyse_CaPe.c .
bash Change_data.sh 
gcc -o Analyse_CaPe.exe Analyse_CaPe.c -lm
./Analyse_CaPe.exe > Analyse.out


echo "#Done Analysing"

rm Nb_lines_Interface_low_viscosity.temp
rm Nb_lines_Interface_large_viscosity.temp

