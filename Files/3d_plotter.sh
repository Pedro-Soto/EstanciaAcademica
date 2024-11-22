#!/bin/bash

if ! command -v gnuplot &> /dev/null
then
    echo "Gnuplot could not be found. Please install it first."
    exit
fi

# Start gnuplot in persistent mode and feed commands interactively
PI=3.14159265358979323846
a=J
b=I
zmax=LONGUEUR
ymax=EPAISSEUR
j_centre=$ymax/2
gnuplot -persist <<- EOF
    # Define min and max functions
    min(x, y) = (x < y) ? x : y
    max(x, y) = (x > y) ? x : y

    set xlabel 'Z-axis'
    set ylabel 'Y-axis'
    set title 'Map of phi-*_map.vtk files'
    num_files = system("ls phi-*_map.vtk | wc -l")

    # Loop over each file and plot it in the same window
    files = system("ls phi-*_map.vtk")
    do for [file in files] {
        print "Processing ".file
        set pm3d map
        set grid
        set isosamples 10000
        splot  file u 3:2:( (   \$2> $j_centre - ($b / 2) - $a * sin(2 * $PI * \$3 / $zmax) && \$2< $j_centre + ($b / 2) + $a * sin(2 * $PI * \$3 / $zmax) ) ? \$4 : NaN)
        
        
    }
    do for [i=1:num_files]{
        pause -1
        replot
    }
EOF
