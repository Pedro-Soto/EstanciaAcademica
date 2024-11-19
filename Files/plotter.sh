#!/bin/bash

if ! command -v gnuplot &> /dev/null
then
    echo "Gnuplot could not be found. Please install it first."
    exit
fi
PI=3.14159265358979323846
a=J
b=I
zmax=LONGUEUR
ymax=EPAISSEUR
j_centre=$ymax/2
# Start gnuplot in persistent mode and feed commands interactively
gnuplot -persist <<- EOF
    set xlabel 'X-axis'
    set ylabel 'Y-axis'
    set grid
    set title 'Plot of phi-*.vtk files'

    # Loop over each file and plot it in the same window
    files = system("ls phi-*.vtk")
    do for [file in files] {
        print "Processing ".file
        plot file u 3:((\$4>0)?\$2:NaN), \
             file u 3:((\$4<0)?\$2:NaN), \
             max(0, min(j_centre + (b / 2) + a * cos(2 * $PI * \$3 / zmax), zmax)) title 'Wall Right', \
             max(0, min(j_centre - (b / 2) - a * cos(2 * $PI * \$3 / zmax), zmax)) title 'Wall Left'
        }
    do for [i=1:*]{
    pause 5
    replot
    }
EOF
