#!/bin/bash
echo "Tamaño promedio de canal"
echo "Inciando en 16"; declare start=16
echo "Terminando en "; read end
ymax=$((end+32))
echo "ymax=$ymax"
echo "zmax? "; read zmax
block=$(echo "scale=2; $zmax/2" | bc)
echo "block=$block"
x1=$(echo "scale=2; $block/$zmax" | bc)
echo "x1=$x1"
x2=$(echo "scale=2; ($zmax-$block)/$zmax" | bc)
echo "x2=$x2"
echo "force? recommended 0.00002";read force
echo "Ludwig Cycles? "; read lud_step
declare step=8
declare jcentre=$ymax/2
declare mu1=1
for ((i=$start; i<=$end; i+=$step))
do
    declare amp_max=$jcentre-$i/2
    for ((j=1; j<=amp_max; j+=1))
    do
        if [ $(($i-2*$j)) -gt 10]; then
            for ((k=1; k<=6; k+=1))
            do
            mu2=$(awk "BEGIN {printf \"6f\", 10^-$k}")
            i2=$((i*i))
            echo "i2=$i2"
            xeta1=$(echo "scale=2; $mu1*$x1" | bc)
            echo "xeta1=$xeta1"
            xeta2=$(echo "scale=2; $mu2*$x2" | bc)
            echo "xeta2=$xeta2"
            sum_xeta=$xeta1+$xeta2
            K=$(echo "scale=2; $i2/($xeta1+$xeta2)" | bc)
            echo "K=$K"
            vel=$(awk "BEGIN {printf \"%2f\", $K*$force}")
            echo "vel=$vel"
            tim=$(echo "scale=2; (2*$zmax)/$vel" | bc)
            echo "time=$tim"
            freq_data=$(echo "scale=2; $tim/$lud_step" | bc)
            echo "freq_data=$freq_data"
            dir=Tam_Prom_$i/Amp_$j/Visc_$k
            mkdir -p ~/Escritorio/Vacaciones/$dir
            cd ~/Escritorio/Vacaciones/$dir/
            cp -R ~/Escritorio/Vacaciones/Files/* ~/Escritorio/Vacaciones/$dir
            sed -i "s/EPAISSEUR/$ymax/g" ~/Escritorio/Vacaciones/$dir/capillary.c
            sed -i "s/LONGUEUR/$zmax/g" ~/Escritorio/Vacaciones/$dir/capillary.c
            sed -i "s/double a = J;/double a = $j;/g" ~/Escritorio/Vacaciones/$dir/capillary.c