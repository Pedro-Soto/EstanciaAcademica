#Compile the extraction program
gcc -o vtk_Interface.exe vtk_Interface.c -lm 

#Apply the extraction program to all the simulation outputs
for f in phi*001 ; do echo $f; ./vtk_Interface.exe phi.001-001.meta $f; done
for f in vel*001 ; do echo $f; ./vtk_Interface.exe vel.001-001.meta $f; done


input_file="input"

# Initialize variables
ymax=""
zmax=""

# Read the file line by line
while IFS= read -r line
do
    # Check if the line starts with "size 3"
    if [[ $line == "size 3"* ]]; then
        # Extract the values
        IFS='_' read -ra ADDR <<< "${line#size 3_}"
        ymax="${ADDR[0]}"
        zmax="${ADDR[1]}"
        break  # Exit the loop once we've found the line
    fi
done < "$input_file"

# Print the values
echo "ymax: $ymax"
echo "zmax: $zmax"

sed -i "s|EPAISSEUR|$ymax|g" Drop_position.c
sed -i "s|LONGUEUR|$zmax|g" Drop_position.c

#Compile the analysis program
gcc -O2 -o Drop_position.exe Drop_position.c -lm

#Apply the analysis program to all the results and extract time
for f in phi*vtk; 
	do echo $f; 
	ls -v $f > Phi.temp; 
	cp Phi.temp Time.temp; 
	sed -i -e "s/phi-/-/g" Time.temp; 
	cp Phi.temp Time2.temp;  
	sed -i -e "s/phi-/ /g" Time2.temp; 
	sed -i -e "s/.vtk/ /g" Time2.temp; 
	tail Time*temp Phi.temp ; 
	./Drop_position.exe $f ; 
done

#Delete useless files
rm *.vtk






############ Extract data for gnuplot ###########
gcc -o vtk_extract_Gnuplot.exe vtk_extract_Gnuplot.c -lm 
for f in phi*001 ; do echo $f; ./vtk_extract_Gnuplot.exe phi.001-001.meta $f; done
for f in vel*001 ; do echo $f; ./vtk_extract_Gnuplot.exe vel.001-001.meta $f; done
