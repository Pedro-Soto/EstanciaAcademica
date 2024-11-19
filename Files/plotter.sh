#!/bin/bash

if ! command -v gnuplot &> /dev/null
then
    echo "Gnuplot could not be found. Please install it first."
    exit
fi

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
        plot file u 3:((\$4>0)?\$2:NaN), file u 3:((\$4<0)?\$2:NaN)
        }
    do for [i=1:*]{
    pause 5
    replot
    }
EOF
