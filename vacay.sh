#!/bin/bash
validate_number() {
    local input=$1
    local default=$2
    local var_name=$3
    
    # If input is empty, return default
    if [[ -z "$input" ]]; then
        echo "$default"
        return 0
    fi
    
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
if [[ "$end" -lt "$start" ]]; then
    echo "Error: End value must be greater than start value"
    exit 1
fi

# Set default values
default_force=0.00002
default_zmax=4000
default_lud_export=100  
total_processors=$(nproc)

read -p "Enter the number of processors to run Ludwig (default is 1): " user_input
num_processors=$(validate_number "$user_input" 1 "Number of processors")
echo "Number of processors to run Ludwig: $num_processors"
if (( num_processors > total_processors )); then
    echo "Error: Number of processors cannot exceed the total number of processors on the system"
    exit 1
fi

# Ask the user if they wish to move results to an external disk
read -p "Do you wish to move results to an external disk? (y/n): " move_results

if [[ "$move_results" == "y" ]]; then
    # Check which disks are mounted and their mount points
    echo "Checking for mounted disks..."
    mounted_disks=$(lsblk -o NAME,MOUNTPOINT | grep -v "^\s*loop" | grep -v "^\s*$")

    if [[ -z "$mounted_disks" ]]; then
        echo "No disks are currently mounted."
        echo ""
    else
        echo "Mounted disks and their mount points:"
        echo ""
        echo "$mounted_disks"
        echo ""
    fi

    # Prompt user for the destination directory with tab completion
    read -e -p "Please enter the destination directory (e.g., /media/username/disk_name): " dest_dir

    # Create Ludwig_Results directory in the specified destination
    move_dir=$dest_dir/Ludwig_Results
    mkdir -p "$move_dir"
    echo "Directory Ludwig_Results created at $dest_dir"
    echo ""
else
    
    dest_dir="."  # Default to current directory if not moving results
    echo "Using the default destination directory"
    echo ""
    echo "Directory Ludwig_Results created at $dest_dir"
    move_dir=$dest_dir/Ludwig_Results
    mkdir -p "$move_dir"
fi




# Prompt user for confirmation on default force value
echo "Default force is set to $default_force. Press Enter to accept, or enter a new value:"
read force
force=$(validate_number "$input_force" "$default_force" "force")

echo ""

# Prompt user for confirmation on default zmax value
echo "Default zmax is set to $default_zmax. Press Enter to accept, or enter a new value:"
read zmax
zmax=$(validate_number "$input_zmax" "$default_zmax" "zmax")

# Check if zmax is a multiple of number of processors and adjust if necessary
if (($zmax % $num_processors > 0)); then
    echo "This value is not multiple of $num_processors, and will be made so"
    remainder=$(($zmax % $num_processors));
    add=$((num_processors-remainder))
    zmax=$((zmax+add))
    echo "Updated zmax value: $zmax"
    echo ""
fi

echo ""

# Calculate block size and other parameters
block=$((zmax/2))
x1=$((block/zmax))
x2=$((zmax-block/zmax))

# Prompt for additional parameters
echo "Default lud_export is set to $default_lud_export. Press Enter to accept, or enter a new value:"
read lud_export
lud_export=$(validate_number "$input_lud_export" "$default_lud_export" "lud_export")
echo ""

# Declare constants    
declare step_elongueur=8
declare mu1=1
declare arbit=4
pi=$(echo "scale=10; 4*a(1)" | bc -l)
echo ""

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

        # Calculate ymax and ensure it's a multiple of num processors
        declare ymax=$((i + (2 * j) + arbit))
        if (($ymax % $num_processors > 0)); then
            echo "ymax value is not multiple of $num_processors, and will be made so"
            echo ""
            remainder=$(($ymax % $num_processors))
            echo "Remainder is $remainder"
            echo ""
            add=$((num_processors-remainder))
            echo "Adding $add"
            echo ""
            ymax=$(($ymax + $add))
        fi
        
        echo ""
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
                echo ""
                # Set up directory structure for results
                dir=Tam_Prom_$i/Amp_$j/Visc_$k
                full_dir="$base_dir/$dir"

                # Check if the directory exists and skip if it does
                if [ -d "$full_dir" ]; then
                    echo "Directory $full_dir already exists, skipping..."
                    continue
                fi

                # Create the directory if it does not exist
                mkdir -p $base_dir/$dir
                cd $base_dir/$dir/
                cp -R $base_dir/Files/* $base_dir/$dir

                # Modify files with calculated parameters

					#Modify capillary.c
                echo ""
				echo "Updating capillary.c"
                sed -i "s/EPAISSEUR/$ymax/g" $base_dir/$dir/capillary.c
                sed -i "s/LONGUEUR/$zmax/g" $base_dir/$dir/capillary.c
                sed -i "s/double a = J;/double a = $j;/g" $base_dir/$dir/capillary.c
                sed -i "s/double b = I;/double b = $i;/g" $base_dir/$dir/capillary.c

					#Modify vtk_Interface.c
				echo ""
                echo "Updating vtk_Interface.c"
                sed -i "s/double a = J;/double a = $j;/g" $base_dir/$dir/vtk_Interface.c
                sed -i "s/double b = I;/double b = $i;/g" $base_dir/$dir/vtk_Interface.c

					#Modify Drop_position.c
				echo ""
                echo "Updating Drop_position.c"
				sed -i "s/EPAISSEUR/$ymax/g" $base_dir/$dir/Drop_position.c
                sed -i "s/LONGUEUR/$zmax/g" $base_dir/$dir/Drop_position.c

					#Modify input
                echo ""
                echo "Updating input"
                
				sed -i "s/size 3_EPAISSEUR_LONGUEUR/size 3_${ymax}_${zmax}/g" $base_dir/$dir/input
                sed -i "s/grid 1_1_PROCESSOR/grid 1_1_$num_processors/g" $base_dir/$dir/input
                sed -i "s/freq_phi FREQPHI/freq_phi $freq_data/g" $base_dir/$dir/input
                sed -i "s/freq_vel FREQVEL/freq_vel $freq_data/g" $base_dir/$dir/input
                sed -i "s/block_dimension    BLOCK/block_dimension    $block/g" $base_dir/$dir/input
                sed -i "s/fP_amplitude 0.00_0.00_FORCE/fP_amplitude 0.00_0.00_$force/g" $base_dir/$dir/input
                sed -i "s/VISC1/$mu1/g" $base_dir/$dir/input
                sed -i "s/VISC2/1e-$k/g" $base_dir/$dir/input
                sed -i "s/N_cycles CYCLES/N_cycles $t/g" $base_dir/$dir/input 

                # Compile capillary.c
                gcc capillary.c -o capillary.exe -lm

                echo ""
                # Run capillary
                ./capillary.exe

				echo ""
                # Run Ludwig
				#chmod +x ./Ludwig.exe
                #ulimit -s unlimited
				#mpirun -np $num_processors ./Ludwig.exe input
                
				
				end_time=$(date +%s%N)

                # Calculate and display execution time
                execution_time=$(echo "scale=2; ($end_time - $start_time) / 1e9" | bc)
                echo "Execution time: $execution_time seconds"

                # Move back to the base directory
                cd $base_dir/
            done
        fi
    done
	echo "/////////////////////////////////////"
    echo ""
    echo "Moving Tam_Prom_$i to $move_dir"
    echo ""
    echo "/////////////////////////////////////"
	# Use rsync to move the directory with a progress bar
    rsync -a --remove-source-files --info=progress2 ~/Escritorio/Resultados/Tam_Prom_$i "$move_dir"
    
    # After rsync, remove the empty source directory if needed
    rmdir ~/Escritorio/Resultados/Tam_Prom_$i 2>/dev/null	
done
