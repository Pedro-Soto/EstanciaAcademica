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
        plot "phi-00024000.vtk" u  3:( ( $4 >0 &&  $2> 72.0/2.0 - (32.0 / 2) - 10.0 * cos(2 * 3.14157 * $3 / 4008.0) && $2< 72.0/2.0 + (32.0 / 2) + 10.0 * cos(2 * 3.14157 * $3 / 4008  ) ) ? $2 : NaN)  ,  "phi-00024000.vtk" u 3: ( ( $4 <=0 &&  $2> 72.0/2.0 - (32.0 / 2) - 10.0 * cos(2 * 3.14157 * $3 / 4008.0) && $2< 72.0/2.0 + (32.0 / 2) + 10.0 * cos(2 * 3.14157 * $3 / 4008  ) ) ? $2 : NaN) , 72.0/2.0 + (32.0 / 2) + 10.0 * cos(2 * 3.14157 * x / 4008.0) lw 3, 72.0/2.0 - (32.0 / 2) - 10.0 * cos(2 * 3.14157 * x / 4008.0) lw 3
        pause 5  # Display each plot for 5 seconds
    }
EOF
