grep "fP_amplitude 0" input > Amplitude.dat
grep "fP_frequency 0" input > Frequency.dat

sed -i -e "s/fP_amplitude/ /g" Amplitude.dat
sed -i -e "s/_/ /g" Amplitude.dat
sed -i -e "s/fP_frequency/ /g" Frequency.dat



