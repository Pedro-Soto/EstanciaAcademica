/****************************************************************************
 *
 *  Interface_position.c
 *
 *  This program computes the properties of the interfaces perpendicular to the z axis
 *
 ****************************************************************************/
 
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define MAX_Function(x, y) (((x) > (y)) ? (x) : (y))
#define MIN_Function(x, y) (((x) < (y)) ? (x) : (y))

#define	Study_velocity	1
#define Study_density 1

#define Pi 3.14159265359

#define PhasePuls (-0.50)

#define Coeff1 (3.0/2.0)
#define Coeff2 (-3.0/5.0)
#define Coeff3 (0.1)

#define Duration	(CYCLES1 + CYCLES2)
#define eta1	VISC1
#define eta2	VISC2
#define f	FREQUENCY
#define F0	AMPLITUDE
#define L	LONGUEUR
#define L2	BLOCK
#define Y	EPAISSEUR
#define Mobility 1.00
#define CoeffB 0.001
#define b	( 1.0* (Y-2) )
#define Sigma0	0.00188562

FILE  *stat_file, *Reprise_file;
char file[1000], Psi_char[1000], buffer[500],  buffer2[500];

/****************************************************************************
 *  main
 ****************************************************************************/

int main(int argc, char ** argv) {

	float buffer_number;
	int Nb_lines;
	int i, j;
	

	printf("Simulation parameters\n");
	printf("#Duration %i ;  eta1 %0.4f ;  eta2 %0.4f ;  f %0.9f ;  F0 %0.9f ;  L %i ;  L2 %0.0f ;  b %0.0f ;  Mobility %0.4f ;  CoeffB %0.6f\n",  Duration, eta1, eta2, f, F0, L, L2, b, Mobility, CoeffB);

	double x1, x2, eta, L1, v0, K0, omega0, omega1, omega2, T, omega; 

	x2 = L2/(1.0*L);
	x1 = 1.0-x2; L1=L-L2;
	eta = x1*eta1+x2*eta2;
	K0 = b*b/(12.0*eta);
	omega0 = 12.0*eta/(b*b);
	omega1 = 12.0*eta1/(b*b);
	omega2 = 12.0*eta2/(b*b);
	v0 = K0*F0;
	omega = 2.0*Pi*f;
	T = 1.0/f;

	printf("Dynamics parameters parameters\n");	
	printf("#x1 %0.2f ; x2 %0.2f ; eta %0.5f ; K0 %0.5f ; omega0 %0.6f ; omega1 %0.6f ; omega2 %0.6f ; 1000*v0 %0.6f, T %0.1f, omega %0.6f\n", x1, x2, eta, K0, omega0, omega1, omega2, 1000.0*v0, T, omega);

	double Ca0, Pe0, sigma, Dphi;

	sigma = Sigma0*CoeffB/0.001;
	Dphi = 2.0*Mobility*CoeffB;
	Ca0 = eta*v0/sigma;
	Pe0 = v0*b/Dphi;

	printf("Interface parameters\n");	
	printf("#1000*sigma %0.6f ; Dphi %0.4f ; Ca0 %0.4f ; Pe0 %0.4f ; Pe0Ca0 %0.4f\n", 1000.0*sigma, Dphi, Ca0, Pe0, Ca0*Pe0);


	printf("#Analyse low viscosity phase: ");
	sprintf(file,"Nb_lines_Interface_low_viscosity.temp");
	printf("%s\n", file);
	Reprise_file=fopen(file,"r");
	fscanf(Reprise_file,"%i", &Nb_lines); 
	fclose(Reprise_file);
	printf("Got %i lines\n", Nb_lines);

	sprintf(file,"Interface_low_viscosity.dat");	
	printf("%s\n", file);
	Reprise_file=fopen(file,"r");
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	fscanf(Reprise_file,"%s", buffer); printf("%s ", buffer);
	printf("\n");

	double vel[Nb_lines-1], time[Nb_lines-1], lfinger[Nb_lines-1], drop[Nb_lines-1], filling[Nb_lines-1];
	for (i=0; i<Nb_lines-1; i++)
		{ vel[i] = 0.0; time[i] = 0.0; lfinger[i] = 0.0; drop[i] = 0.0; filling[i] = 0.0;  }
	
	for (i=0; i<Nb_lines-1; i++)
		{ 
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.5f ", buffer_number);	time[i] = buffer_number;
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.2f ", buffer_number);	lfinger[i] = buffer_number;
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.5f ", buffer_number);
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.5f ", buffer_number);	filling[i] = buffer_number;
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.5f ", buffer_number);	drop[i] = buffer_number;
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.5f ", buffer_number);
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.5f ", buffer_number);
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.5f ", buffer_number);
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.5f ", buffer_number);	vel[i] = buffer_number;
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.5f ", buffer_number);
		fscanf(Reprise_file,"%f", &buffer_number);	printf("%0.5f ", buffer_number);
		printf("\n");		
		}

	fclose(Reprise_file);

	int nPeriod = 1;
	double MaxTime = time[Nb_lines-2]*1.0;
	int MaxPeriod = (int)( MaxTime/T);
	printf("#MaxTime %0.1f Total number of periods %i\n", MaxTime, MaxPeriod);
	
	double LFinger[MaxPeriod], NbDrop[MaxPeriod], Fill[MaxPeriod], Vel[MaxPeriod];

	for (j=0; j<MaxPeriod; j++)
		{
		LFinger[j] = 0.0; NbDrop[j] = 0.0; Fill[j] = 0.0; Vel[j] = 0.0;
		}

	for (i=1; i<Nb_lines-2; i++)
		{
		if ( fabs(lfinger[i]) > LFinger[nPeriod-1] ) 	{ LFinger[nPeriod-1]=fabs(lfinger[i]) ; }
		if ( fabs(filling[i]) > Fill[nPeriod-1] ) 	{ Fill[nPeriod-1]=fabs(filling[i]) ; }
		if ( fabs(drop[i]) > NbDrop[nPeriod-1] ) 	{ NbDrop[nPeriod-1]=fabs(drop[i]) ; }
		if ( fabs(vel[i]) > Vel[nPeriod-1] ) 		{ Vel[nPeriod-1]=fabs(vel[i]) ; }

		if (time[i-1]/T<nPeriod && time[i]/T>=nPeriod)
			{
			nPeriod += 1;
			printf("t %0.1f t/T %0.3f Entering Period %i\n", time[i], time[i]/T, nPeriod);  
			}
		}
		printf("End loop at t %0.1f t/T %0.3f in Period %i\n", time[i], time[i]/T, nPeriod);  

	double Av_LFinger, Av_NbDrop, Av_Fill, Av_Vel;
	Av_LFinger = ( LFinger[MaxPeriod-3]+LFinger[MaxPeriod-2]+LFinger[MaxPeriod-1] ) / 3.0 ;
	Av_NbDrop = ( NbDrop[MaxPeriod-3]+NbDrop[MaxPeriod-2]+NbDrop[MaxPeriod-1] ) / 3.0 ;
	Av_Fill = ( Fill[MaxPeriod-3]+Fill[MaxPeriod-2]+Fill[MaxPeriod-1] ) / 3.0 ;
	Av_Vel = ( Vel[MaxPeriod-3]+Vel[MaxPeriod-2]+Vel[MaxPeriod-1] ) / 3.0 ;

	printf("Finger length %0.5f ; Filling %0.5f ; Nb_drops %0.1f ; 1000*Vel %0.5f\n", Av_LFinger, Av_Fill, Av_NbDrop, Av_Vel);

	sprintf(file,"../../../Results_Sigma%0.3f_M%0.3f_b%0.0f_eta_%0.4f_%0.4f_Ca%0.6f_Pe%0.6f.dat", sigma/Sigma0, Mobility, b, eta1, eta2, Ca0, Pe0);
	stat_file=fopen(file,"r");
	if (stat_file == NULL)
		{	
		stat_file=fopen(file,"w");
		fprintf(stat_file, "#1-sigma/sigma0 2-M 3-b 4-eta1 5-eta2 6-Pe0 7-Ca0 8-Pe0Ca0 9-omega 10-omega/omega0 11-1000vmax 12-vmax/v0 13-LfingerMax 14-Filling 15-Drop\n");
		}
	fclose(stat_file);

	sprintf(file,"../../../Results_Sigma%0.3f_M%0.3f_b%0.0f_eta_%0.4f_%0.4f_Ca%0.6f_Pe%0.6f.dat", sigma/Sigma0, Mobility, b, eta1, eta2, Ca0, Pe0);
	stat_file=fopen(file,"a");
	fprintf(stat_file, "%0.3f %0.3f %0.0f %0.6f %0.6f %0.9f %0.9f %0.9f %0.9f %0.9f %0.9f %0.9f %0.3f %0.3f %0.1f\n", sigma/Sigma0, Mobility, b, eta1, eta2, Pe0, Ca0, Pe0*Ca0, omega, omega/omega0, Av_Vel, Av_Vel/(1000.0*v0), Av_LFinger, Av_Fill, Av_NbDrop);
	fclose(stat_file);



} // End main


