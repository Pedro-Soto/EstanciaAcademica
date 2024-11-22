#include <stdio.h>
#include <math.h>
#include <unistd.h>
#define PI 3.14159265358979323846 
int main(){
    int zmax, amp, b0;
    double b, eta, eta1, eta2, Deltaz, z, zinterf1, zinterf2, R, K, deltaP, F;
    double results[4];
    
    zmax=LONGUEUR;
    amp=J;
    b0=I;
    Deltaz=0.01;
    R=0;
    eta1=mu1;
    eta2=mu2;
    zinterf1=zmax/4;
    zinterf2=3*zmax/4;
    for (z=0; z<zmax; z+=Deltaz){
        if (zinterf1 <= zinterf2 && z >= zinterf1 && z<= zinterf2)	{ eta=eta1; }
        if (zinterf1 <= zinterf2 && (z < zinterf1 || z > zinterf2) ) { eta=eta2; }		
        if (zinterf1 > zinterf2 &&  z >= zinterf2 && z<= zinterf1)	{ eta=eta2; }		
        if (zinterf1 > zinterf2 && (z > zinterf1 || z < zinterf2) )	{ eta=eta1; }

        // Compute value of b
        b = b0 + 2.0*amp*sin(2*PI*z/zmax);
        //usleep(100000);
        //printf("z,b.R = %f\n", b);

        //Compute Resistance
        R += (12.0*eta/(b*b))*Deltaz;
        // printf("z,b.R = %f, %f, %f\n", z,b,R);


    }
    K = (R != 0) ? (1 / R) : 0;
    deltaP = (1.0 / 3.0) / (5.0 * K);
    F=deltaP/zmax;
    results[0]=R;
    results[1]=K;
    results[2]=deltaP;
    results[3]=F;
    printf("%f %f %f %f\n", results[0], results[1], results[2], results[3]);





}
