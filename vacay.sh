#!/bin/bash
## Code brought to you by PeSesito

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

echo ""

# Display title (in Spanish)
echo "Tamaño promedio de canal"

# Prompt user for input values
echo "Iniciando en "
read input_start
start=$(validate_number "$input_start" "0" "start")
if ((start % 8 != 0 )); then
    echo "start is not multiple of 8, and will be rounded to the nearest upper multiple"
    start=$((start + (8 - (start % 8))))
    echo "Adjusted start value to the nearest upper multiple of 8: $start"
fi
echo ""

echo "Terminando en: "
read input_end
end=$(validate_number "$input_end" "0" "end")
if ((end % 8 != 0 )); then
    echo "end is not multiple of 8, and will be rounded to the nearest upper multiple"
    end=$((end + (8 - (end % 8))))
    echo "Adjusted end value to the nearest upper multiple of 8: $end"
fi
echo ""

# Ask user for the direction of the simulation
echo "Do you want the simulations to go from start to end or from end to start? (Enter 's' for start to end or 'e' for end to start): "
read direction

# Validate user input
while [[ "$direction" != "s" && "$direction" != "e" ]]; do
    echo "Invalid input. Please enter 's' for start to end or 'e' for end to start:"
    read direction
done

echo ""

if [[ "$end" -lt "$start" ]]; then
    echo "Error: End value must be greater than start value"
    exit 1
fi
echo ""

# Set default values
default_force=0.00002
default_zmax=4000
default_lud_export=100  
total_processors=$(nproc)

echo "Enter the number of processors to run Ludwig (default is 1):" 
read user_input
num_processors=$(validate_number "$user_input" 1 "Number of processors")
echo ""
echo "Number of processors to run Ludwig: $num_processors"
echo ""
if (( num_processors > total_processors )); then
    echo "Error: Number of processors cannot exceed the total number of processors on the system"
    exit 1
fi

# Ask the user if they wish to move results to an external disk
echo "Do you wish to move results to an external disk? (y/n): " 
read move_results
while (( "$move_results"!= "y" && "$move_results"!= "n")); do
    echo "Invalid input. Please enter y or n."
    read move_results
done

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
    echo "Directory Ludwig_Results created at $base_dir"
    echo ""
    move_dir=$dest_dir/Ludwig_Results
    mkdir -p "$move_dir"
fi

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


if [[ "$direction" == "s" ]]; then
    for ((i=$start; i<=$end; i+=$step_elongueur))
        do
            # Inner loop for amplitude
            for (( j=1; j<=amp_max; j+=1))
            do
                # Skip iterations where i <= 2*j+10
                if (($i <= $((2 * j + 10)))); then
                    continue
                fi

                if (($j<10)); then
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
                        declare restart_step=0
                        declare remaining_cycles=0

                        # Set up directory structure for results
                        dir=Tam_Prom_$i/Amp_$j/Visc_$k
                        full_dir="$base_dir/$dir"

                        # Check if the directory exists and skip if it does
                        if [ -d "$full_dir" ]; then
                            echo "Directory $full_dir already exists, checking for phi files..."

                            # Check for phi files
                            phi_files=("$full_dir"/phi-*.001-001)

                            if [ -e "${phi_files[0]}" ]; then
                                # Get the last phi file
                                last_phi_file="${phi_files[-1]}"
                                echo "Last phi file found: $last_phi_file"

                                # Extract the number from the filename
                                restart_step=$(basename "$last_phi_file" | sed 's/^phi-\([0-9]*\)\.001-001$/\1/')
                                restart_step=$((10#$restart_step))
                                echo "Extracted restart_step: $restart_step"
                                sleep 1
                            fi
                        else
                            echo "Creating directory $full_dir"
                            mkdir -p $full_dir
                        fi

                        
                        echo "Copying files to $full_dir"
                        cd $full_dir
                        cp -R $base_dir/Files/* $full_dir
                        
                        # Calculate viscosity and other parameters
                        declare mu2=$(echo "10^-$k" | bc)

                        # Run resistance_numerical solution, computes resistance
                        sed -i "s/LONGUEUR/$zmax/g" $base_dir/$dir/resistance_num.c
                        sed -i "s/J/$j/g" $base_dir/$dir/resistance_num.c
                        sed -i "s/I/$i/g" $base_dir/$dir/resistance_num.c
                        sed -i "s/eta1=mu1;/eta1=$mu1;/g" $base_dir/$dir/resistance_num.c
                        sed -i "s/eta2=mu2;/eta2=1e-$k;/g" $base_dir/$dir/resistance_num.c
                        gcc -o resistance_num.exe resistance_num.c -lm
                        output=$(./resistance_num.exe)
                        read -r Resistance K deltaP force <<< "$output"
                        echo "Resistance: $Resistance"
                        echo "K: $K"
                        echo "deltaP: $deltaP"
                        echo "Force: $force"
                        declare v=$(echo "$K*$force" | bc)
                        declare t=$(printf "%d" $(echo "2*$zmax/$v" | bc))
                        declare data_div=$(echo "scale=2; $t / $lud_export" | bc)
                        declare freq_data=$(printf "%.0f" "$data_div") # Frequency data for output
                        declare remaining_cycles=$((t - restart_step))

                        

                        # Write sim_config file
                        {
                        echo "Final configuration:"
                        echo "Number of processors: $num_processors"
                        echo "Force: $force"
                        echo "Xmax = 3"
                        echo "Zmax: $zmax"
                        echo "Ymax: $ymax"
                        echo "Width : $i"
                        echo "Length : $zmax"
                        echo "amplitude : $j"
                        echo "viscosity1 : $mu1"
                        echo "viscosity2 : 1e-$k"
                        echo "force : $force"
                        echo "Resistance : $Resistance"
                        echo "deltaP: $deltaP"
                        echo "block size : $block"
                        echo "data frequency : $freq_data"
                        echo "total cycles : $t"
                        echo "Remaining cycles : $remaining_cycles"
                        echo "Restart step : $restart_step"
                        echo "Results will be saved in: $move_dir"
                        } > sim_config.txt

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
                        
                        sed -i "s/N_start  CYCLE_START /N_start  $restart_step /g" $base_dir/$dir/input
                        sed -i "s/size 3_EPAISSEUR_LONGUEUR/size 3_${ymax}_${zmax}/g" $base_dir/$dir/input
                        sed -i "s/grid 1_1_PROCESSOR/grid 1_1_$num_processors/g" $base_dir/$dir/input
                        sed -i "s/freq_phi FREQPHI/freq_phi $freq_data/g" $base_dir/$dir/input
                        sed -i "s/freq_vel FREQVEL/freq_vel $freq_data/g" $base_dir/$dir/input
                        sed -i "s/block_dimension    BLOCK/block_dimension    $block/g" $base_dir/$dir/input
                        sed -i "s/fP_amplitude 0.00_0.00_FORCE/fP_amplitude 0.00_0.00_$force/g" $base_dir/$dir/input
                        sed -i "s/VISC1/$mu1/g" $base_dir/$dir/input
                        sed -i "s/VISC2/1e-$k/g" $base_dir/$dir/input
                        sed -i "s/N_cycles CYCLES/N_cycles $remaining_cycles/g" $base_dir/$dir/input 

                            #Modify Wall_Analysis.c
                        echo ""
                        echo "Updating Wall_Analysis.c"
                        sed -i "s/EPAISSEUR/$ymax/g" $base_dir/$dir/Wall_Analysis.c
                        sed -i "s/LONGUEUR/$zmax/g" $base_dir/$dir/Wall_Analysis.c
                        sed -i "s/double a = J;/double a = $j;/g" $base_dir/$dir/Wall_Analysis.c
                        sed -i "s/double b = I;/double b = $i;/g" $base_dir/$dir/Wall_Analysis.c
                        
                            #Modify plotter.sh
                        sed -i "s/LONGUEUR/$zmax/g" $base_dir/$dir/plotter.sh
                        sed -i "s/EPAISSEUR/$ymax/g" $base_dir/$dir/plotter.sh
                        sed -i "s/b=I/b=$i/g" $base_dir/$dir/plotter.sh
                        sed -i "s/a=J/a=$j/g" $base_dir/$dir/plotter.sh
                        
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
            rsync -a --remove-source-files --info=progress2 $base_dir/Tam_Prom_$i "$move_dir"
            
            # After rsync, remove the empty source directory if needed
            find $base_dir/Tam_Prom_$i -type d -empty -delete
        done
else
    for ((i=end; i>=start; i-=step_elongueur))
        do
            # Inner loop for amplitude
            for (( j=amp_max; j>=1; j-=1))
            do
                # Skip iterations where i <= 2*j+10
                if (($i <= $((2 * j + 10)))); then
                    continue
                fi

                if (($j<10)); then
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
                        declare restart_step=0
                        declare remaining_cycles=0

                        # Set up directory structure for results
                        dir=Tam_Prom_$i/Amp_$j/Visc_$k
                        full_dir="$base_dir/$dir"

                        # Check if the directory exists and skip if it does
                        if [ -d "$full_dir" ]; then
                            echo "Directory $full_dir already exists, checking for phi files..."

                            # Check for phi files
                            phi_files=("$full_dir"/phi-*.001-001)

                            if [ -e "${phi_files[0]}" ]; then
                                # Get the last phi file
                                last_phi_file="${phi_files[-1]}"
                                echo "Last phi file found: $last_phi_file"

                                # Extract the number from the filename
                                restart_step=$(basename "$last_phi_file" | sed 's/^phi-\([0-9]*\)\.001-001$/\1/')
                                restart_step=$((10#$restart_step))
                                echo "Extracted restart_step: $restart_step"
                                sleep 1
                            fi
                        else
                            echo "Creating directory $full_dir"
                            mkdir -p $full_dir
                        fi

                        
                        echo "Copying files to $full_dir"
                        cd $full_dir
                        cp -R $base_dir/Files/* $full_dir
                        
                        # Calculate viscosity and other parameters
                        declare mu2=$(echo "10^-$k" | bc)

                        # Run resistance_numerical solution, computes resistance
                        sed -i "s/LONGUEUR/$zmax/g" $base_dir/$dir/resistance_num.c
                        sed -i "s/J/$j/g" $base_dir/$dir/resistance_num.c
                        sed -i "s/I/$i/g" $base_dir/$dir/resistance_num.c
                        sed -i "s/eta1=mu1;/eta1=$mu1;/g" $base_dir/$dir/resistance_num.c
                        sed -i "s/eta2=mu2;/eta2=1e-$k;/g" $base_dir/$dir/resistance_num.c
                        gcc -o resistance_num.exe resistance_num.c -lm
                        output=$(./resistance_num.exe)
                        read -r Resistance K deltaP force <<< "$output"
                        echo "Resistance: $Resistance"
                        echo "K: $K"
                        echo "deltaP: $deltaP"
                        echo "Force: $force"
                        declare v=$(echo "$K*$force" | bc)
                        declare t=$(printf "%d" $(echo "2*$zmax/$v" | bc))
                        declare data_div=$(echo "scale=2; $t / $lud_export" | bc)
                        declare freq_data=$(printf "%.0f" "$data_div") # Frequency data for output
                        declare remaining_cycles=$((t - restart_step))

                        

                        # Write sim_config file
                        {
                        echo "Final configuration:"
                        echo "Number of processors: $num_processors"
                        echo "Force: $force"
                        echo "Xmax = 3"
                        echo "Zmax: $zmax"
                        echo "Ymax: $ymax"
                        echo "Width : $i"
                        echo "Length : $zmax"
                        echo "amplitude : $j"
                        echo "viscosity1 : $mu1"
                        echo "viscosity2 : 1e-$k"
                        echo "force : $force"
                        echo "Resistance : $Resistance"
                        echo "deltaP: $deltaP"
                        echo "block size : $block"
                        echo "data frequency : $freq_data"
                        echo "total cycles : $t"
                        echo "Remaining cycles : $remaining_cycles"
                        echo "Restart step : $restart_step"
                        echo "Results will be saved in: $move_dir"
                        } > sim_config.txt

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
                        
                        sed -i "s/N_start  CYCLE_START /N_start  $restart_step /g" $base_dir/$dir/input
                        sed -i "s/size 3_EPAISSEUR_LONGUEUR/size 3_${ymax}_${zmax}/g" $base_dir/$dir/input
                        sed -i "s/grid 1_1_PROCESSOR/grid 1_1_$num_processors/g" $base_dir/$dir/input
                        sed -i "s/freq_phi FREQPHI/freq_phi $freq_data/g" $base_dir/$dir/input
                        sed -i "s/freq_vel FREQVEL/freq_vel $freq_data/g" $base_dir/$dir/input
                        sed -i "s/block_dimension    BLOCK/block_dimension    $block/g" $base_dir/$dir/input
                        sed -i "s/fP_amplitude 0.00_0.00_FORCE/fP_amplitude 0.00_0.00_$force/g" $base_dir/$dir/input
                        sed -i "s/VISC1/$mu1/g" $base_dir/$dir/input
                        sed -i "s/VISC2/1e-$k/g" $base_dir/$dir/input
                        sed -i "s/N_cycles CYCLES/N_cycles $remaining_cycles/g" $base_dir/$dir/input 

                            #Modify Wall_Analysis.c
                        echo ""
                        echo "Updating Wall_Analysis.c"
                        sed -i "s/EPAISSEUR/$ymax/g" $base_dir/$dir/Wall_Analysis.c
                        sed -i "s/LONGUEUR/$zmax/g" $base_dir/$dir/Wall_Analysis.c
                        sed -i "s/double a = J;/double a = $j;/g" $base_dir/$dir/Wall_Analysis.c
                        sed -i "s/double b = I;/double b = $i;/g" $base_dir/$dir/Wall_Analysis.c
                        
                            #Modify plotter.sh
                        sed -i "s/LONGUEUR/$zmax/g" $base_dir/$dir/plotter.sh
                        sed -i "s/EPAISSEUR/$ymax/g" $base_dir/$dir/plotter.sh
                        sed -i "s/b=I/b=$i/g" $base_dir/$dir/plotter.sh
                        sed -i "s/a=J/a=$j/g" $base_dir/$dir/plotter.sh
                        
                        # Compile capillary.c
                        gcc capillary.c -o capillary.exe -lm

                        echo ""
                        # Run capillary
                        ./capillary.exe
                        echo "LINE AFTER RUN CAPILLARY.EXE"

                        echo ""
                        # Run Ludwig
                        #chmod +x ./Ludwig.exe
                        #ulimit -s unlimited
                        #mpirun -np $num_processors ./Ludwig.exe input
                        #echo "This line precedes the RUN LUDWIG"
                        
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
            rsync -a --remove-source-files --info=progress2 $base_dir/Tam_Prom_$i "$move_dir"
            
            # After rsync, remove the empty source directory if needed
            find $base_dir/Tam_Prom_$i -type d -empty -delete
        done
fi

