#!/bin/bash
echo "Tamaño promedio de canal"
echo "Iniciando en "; read start
echo "Terminando en: "; read end
echo "zmax?"; read zmax
if (($zmax % 24 > 0)); then
	echo "This value is not multiple of 24, and will be made so"
	remainder=$(($zmax % 24))
	add=$((24-remainder))
	zmax=$zmax+$add
	echo "Upated zmax value: $zmax"
fi
	block=$((zmax/2))
	x1=$((block/zmax))
	x2=$((zmax-block/zmax))
	echo "force? recommended 0.00002"; read force
	echo "Ludwig Cycles? "; read lud_export
	declare step_elongueur=8
	declare mu1=1
	for ((i=$start; i<=$end; i+=$step_elongueur))
	do
		declare amp_max=$((($i-10)/2))
		echo "amp_max= $amp_max"
		for (( j=1; j<=amp_max; j+=1))
		do
			declare ymax=$(($i+2*$j+3))
			if [ $(($i-2*$j)) -gt 10 ]; then
				for (( k=0; k<=3; k+=1))
				do
				declare mu2=$(echo "10^-$k" | bc)
				declare i2=$((i*i))
				declare xeta1=$mu1*0.5
				declare xeta2=$mu2*0.5
				declare sum_xeta=$(echo "$xeta1+$xeta2" | bc)
				declare K=$(echo "$i2/$sum_xeta" | bc)
				declare v=$(echo "$K*$force" | bc)
				declare t=$(printf "%d" $(echo "2*$zmax/$v" | bc))
				declare freq_data=$(printf "%d" $(echo "scale=2; $t / $lud_export" | bc))
				dir=Tam_Prom_$i/Amp_$j/Visc_$k
				mkdir -p ~/Escritorio/Resultados/$dir
				cd ~/Escritorio/Resultados/$dir/
				cp -R ~/Escritorio/Resultados/Files/* ~/Escritorio/Resultados/$dir
				sed -i "s/EPAISSEUR/$ymax/g" ~/Escritorio/Resultados/$dir/capillary.c
				sed -i "s/LONGUEUR/$zmax/g" ~/Escritorio/Resultados/$dir/capillary.c
				sed -i "s/double a = J;/double a = $j;/g" ~/Escritorio/Resultados/$dir/capillary.c
				sed -i "s/double b = I;/double b = $i;/g" ~/Escritorio/Resultados/$dir/capillary.c
				sed -i "s/EPAISSEUR/$ymax/g" ~/Escritorio/Resultados/$dir/Drop_position.c
				sed -i "s/LONGUEUR/$zmax/g" ~/Escritorio/Resultados/$dir/Drop_position.c
				sed -i "s/size 3_EPAISSEUR_LONGUEUR/size 3_${ymax}_${zmax}/g" ~/Escritorio/Resultados/$dir/input
				sed -i "s/freq_phi FREQPHI/freq_phi $freq_data/g" ~/Escritorio/Resultados/$dir/input
				sed -i "s/freq_vel FREQVEL/freq_vel $freq_data/g" ~/Escritorio/Resultados/$dir/input
				sed -i "s/block_dimension    BLOCK/block_dimension    $block/g" ~/Escritorio/Resultados/$dir/input
				sed -i "s/fP_amplitude 0.00_0.00_FORCE/fP_amplitude 0.00_0.00_$force/g" ~/Escritorio/Resultados/$dir/input
				sed -i "s/VISC1/$mu1/g" ~/Escritorio/Resultados/$dir/input
				sed -i "s/VISC2/1e-$k/g" ~/Escritorio/Resultados/$dir/input
				sed -i "s/N_cycles CYCLES/N_cycles $t/g" ~/Escritorio/Resultados/$dir/input 

			   	##/////////////////////////////////////////////////////////////////////////////
				##From this point on, runs Ludwig and returns all the results to the same $dir

				gcc capillary.c -lm -o capillary.exe
				./capillary.exe
				ulimit -s unlimited
				./Ludwig.exe input
				
				##This part moves de $dir to storage
				mv ~/Escritorio/Resultados/Tam_Prom_$i /media/pedro/Frida/PSR/
				cd ~/Escritorio/Resultados
				done
			fi
				continue
		done
	echo "///////////////////////////////////// \n Moving Tam_Prom_$i to external drive"
	mv ~/Escritorio/Resultados/Tam_Prom_$i /run/media/pedro/Frida/PSR	
	done
