#!/bin/bash
validate_number() {
    local input=$1
    local default=$2
    local var_name=$3
    
    # If input is empty, return default
    if [[ -z "$input" ]]; then
        echo "$default"
        return 0
    fi    # Changed '}' to 'fi'
    
    # Check if the input is a valid number (including decimals)
    if [[ "$input" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        echo "$input"
        return 0
    else
        echo "Error: Invalid input for $var_name. Must be a number. Using default value: $default" >&2
        echo "$default"
        return 1
    fi
}

# Get the current directory
current_dir=$(pwd)
echo "Current directory is: $current_dir"
echo "Is this correct? (Press Enter for yes, or type 'n' for no)"
read agree_dir

# Allow user to change directory if needed
if [[ "$agree_dir" == "n" ]]; then
    echo "Please enter the correct directory path:"
    read base_dir
else
    base_dir=$current_dir
fi

# Display title (in Spanish)
echo "Tamaño promedio de canal"

# Prompt user for input values
echo "Iniciando en "
read input_start
start=$(validate_number "$input_start" "0" "start")

echo "Terminando en: "
read input_end
end=$(validate_number "$input_end" "0" "end")
if [[ "$end" -le "$start" ]]; then
    echo "Error: End value must be greater than start value"
    exit 1
fi

# Set default values
default_force=0.00002
default_zmax=4000
default_lud_export=100  

# Prompt user for confirmation on default force value
echo "Default force is set to $default_force. Press Enter to accept, or enter a new value:"
read force
force=$(validate_number "$input_force" "$default_force" "force")

# Prompt user for confirmation on default zmax value
echo "Default zmax is set to $default_zmax. Press Enter to accept, or enter a new value:"
read zmax
zmax=$(validate_number "$input_zmax" "$default_zmax" "zmax")

# Check if zmax is a multiple of 8 and adjust if necessary
if (($zmax % 8 > 0)); then
    echo "This value is not multiple of 8, and will be made so"
    remainder=$(($zmax % 8))
    add=$((8-remainder))
    zmax=$zmax+$add
    echo "Updated zmax value: $zmax"
fi

# Calculate block size and other parameters
block=$((zmax/2))
x1=$((block/zmax))
x2=$((zmax-block/zmax))

# Prompt for additional parameters
echo "Default lud_export is set to $default_lud_export. Press Enter to accept, or enter a new value:"
read lud_export
lud_export=$(validate_number "$input_lud_export" "$default_lud_export" "lud_export")

# Declare constants    
declare step_elongueur=8
declare mu1=1
declare arbit=4
pi=$(echo "scale=10; 4*a(1)" | bc -l)

# Calculate amp_max
amp_max=$(echo "($zmax / 8 * $pi + 0.999999)" | bc)  # Add a small value to round up
amp_max=$(printf "%.0f" "$amp_max")  # Convert to integer

# Main loop over the range from start to end with a step size
for ((i=$start; i<=$end; i+=$step_elongueur))
do
    # Inner loop for amplitude
    for (( j=1; j<=amp_max; j+=1))
    do
        # Skip iterations where i <= 2*j+10
        if (($i <= $((2 * j + 10)))); then
            continue
        fi

        # Calculate ymax and ensure it's a multiple of 8
        declare ymax=$((i + (2 * j) + arbit))
        if (($ymax % 8 > 0)); then
            echo "ymax value is not multiple of 8, and will be made so"
            remainder=$(($ymax % 8))
            echo "Remainder is $remainder"
            add=$((8-remainder))
            echo "Adding $add"
            ymax=$(($ymax + $add))
        fi
        echo "Updated ymax value: $ymax"

        # Only proceed if the condition is met
        if [ $(($i-2*$j)) -gt 10 ]; then
            
            # Loop over viscosity values
            for (( k=0; k<=3; k+=1))
            do
                start_time=$(date +%s%N) # Record start time

                # Calculate viscosity and other parameters
                declare mu2=$(echo "10^-$k" | bc)
                declare i2=$((i*i))
                declare xeta1=$mu1*0.5
                declare xeta2=$mu2*0.5
                declare sum_xeta=$(echo "$xeta1+$xeta2" | bc)
                declare K=$(echo "$i2/$sum_xeta" | bc)
                declare v=$(echo "$K*$force" | bc)
                declare t=$(printf "%d" $(echo "2*$zmax/$v" | bc))
                declare data_div=$(echo "scale=2; $t / $lud_export" | bc)
                declare freq_data=$(printf "%.0f" "$data_div") # Frequency data for output
                echo "Data output every $freq_data steps"

                # Set up directory structure for results
                dir=Tam_Prom_$i/Amp_$j/Visc_$k
                full_dir="$base_dir/$dir"

                # Check if the directory exists and skip if it does
                if [ -d "$full_dir" ]; then
                    echo "Directory $full_dir already exists, skipping..."
                    continue
                fi

                # Create the directory if it does not exist
                mkdir -p ~/Escritorio/Resultados/$dir
                cd ~/Escritorio/Resultados/$dir/
                cp -R ~/Escritorio/Resultados/Files/* ~/Escritorio/Resultados/$dir

                # Modify files with calculated parameters
				
					#Modify capillary.c
				echo "Updating capillary.c"
                sed -i "s/EPAISSEUR/$ymax/g" ~/Escritorio/Resultados/$dir/capillary.c
                sed -i "s/LONGUEUR/$zmax/g" ~/Escritorio/Resultados/$dir/capillary.c
                sed -i "s/double a = J;/double a = $j;/g" ~/Escritorio/Resultados/$dir/capillary.c
                sed -i "s/double b = I;/double b = $i;/g" ~/Escritorio/Resultados/$dir/capillary.c

					#Modify vtk_Interface.c
				echo "Updating vtk_Interface.c"
                sed -i "s/double a = J;/double a = $j;/g" ~/Escritorio/Resultados/$dir/vtk_Interface.c
                sed -i "s/double b = I;/double b = $i;/g" ~/Escritorio/Resultados/$dir/vtk_Interface.c

					#Modify Drop_position.c
				echo "Updating Drop_position.c"
				sed -i "s/EPAISSEUR/$ymax/g" ~/Escritorio/Resultados/$dir/Drop_position.c
                sed -i "s/LONGUEUR/$zmax/g" ~/Escritorio/Resultados/$dir/Drop_position.c

					#Modify input
                echo "Updating input"
				sed -i "s/size 3_EPAISSEUR_LONGUEUR/size 3_${ymax}_${zmax}/g" ~/Escritorio/Resultados/$dir/input
                sed -i "s/freq_phi FREQPHI/freq_phi $freq_data/g" ~/Escritorio/Resultados/$dir/input
                sed -i "s/freq_vel FREQVEL/freq_vel $freq_data/g" ~/Escritorio/Resultados/$dir/input
                sed -i "s/block_dimension    BLOCK/block_dimension    $block/g" ~/Escritorio/Resultados/$dir/input
                sed -i "s/fP_amplitude 0.00_0.00_FORCE/fP_amplitude 0.00_0.00_$force/g" ~/Escritorio/Resultados/$dir/input
                sed -i "s/VISC1/$mu1/g" ~/Escritorio/Resultados/$dir/input
                sed -i "s/VISC2/1e-$k/g" ~/Escritorio/Resultados/$dir/input
                sed -i "s/N_cycles CYCLES/N_cycles $t/g" ~/Escritorio/Resultados/$dir/input 

                # Compile capillary.c
                gcc capillary.c -o capillary.exe -lm

                # Run capillary
                ./capillary.exe

				# Run Ludwig
				#ulimit -s unlimited
				#mpirun -np 8 ./Ludwig.exe input
                
				
				end_time=$(date +%s%N)

                # Calculate and display execution time
                execution_time=$(echo "scale=2; ($end_time - $start_time) / 1e9" | bc)
                echo "Execution time: $execution_time seconds"

                # Move back to the base directory
                cd ~/Escritorio/Resultados/
            done
        fi
    done
	echo "///////////////////////////////////// \n Moving Tam_Prom_$i to external drive"
	mv ~/Escritorio/Resultados/Tam_Prom_$i /run/media/pedro/Frida/PSR		
done