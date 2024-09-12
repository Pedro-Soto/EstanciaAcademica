#!/bin/bash
# The name of the job, can be anything, simply used when displaying the list of running jobs
##$ -N Contrast001
# Giving the name of the output log file
##$ -o $JOB_NAME-$JOB_ID.log
# Combining output/error messages into one file
##$ -j y
# One needs to tell the queue system to use the current directory as the working directory
# Or else the script may fail as it will execute in your top level home directory /home/username
#$ -cwd
# With -V you pass the env variables, it's necessary. And the unset module is needed to remove some errors
#$ -V
# Uncomment the following line if you want to know in which host your job was executed
 echo "Running on " `hostname`
# Now comes the commands to be executed
# Copy exe and required input files to the local disk on the node
pwd > Local_folder.dat 
cp -r *  $TMPDIR
# Change to the execution directory
cd $TMPDIR/
# And run the exe
bash Change_data.sh
rm *.sh.*
gcc -o Prep_cap capillary.c -lm
./Prep_cap > Capillary.dat

mpirun -np 4 ./Ludwig.exe input  > Output.out
mpirun -np 4 ./Ludwig.exe input2  > Output2.out

python vtk_Interface.py  ;
python Interface_position.py ;
rm Interface_stat_y_*.dat


# Finally, we copy back all important output to the working directory
scp  -r *  nodo00:$SGE_O_WORKDIR

