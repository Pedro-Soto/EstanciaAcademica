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


#define NX 3  
#define NY EPAISSEUR  
#define NZ LONGUEUR

#define bchannel (1.0*(NY-2))

#define MAX_Function(x, y) (((x) > (y)) ? (x) : (y))
#define MIN_Function(x, y) (((x) < (y)) ? (x) : (y))

#define	Study_velocity	1
#define Study_density 1

#define Export_interface_profile_x 0

#define Export_interface_profile_y 1

#define Export_drop_data 1

#define Export_density_profiles 0

#define Pi 3.14159265359

#define PhasePuls (-0.50)

#define Coeff1 (3.0/2.0)
#define Coeff2 (-3.0/5.0)
#define Coeff3 (0.1)


FILE  *stat_file, *Reprise_file;
char file[1000], Psi_char[1000], buffer2[500];

float phi[NX][NY][NZ], psi[NX][NY][NZ], rho_e[NX][NY][NZ], rho_0[NX][NY][NZ], rho_1[NX][NY][NZ]; 
float vel[NX][NY][NZ], velX[NX][NY][NZ], velY[NX][NY][NZ], velZ[NX][NY][NZ];
float density[NX][NY][NZ]; 

float phitemp[NY][NZ], densitytemp[NY][NZ], velZtemp[NY][NZ];
float phi2[NY][NZ], density2[NY][NZ], velZ2[NY][NZ];
float phi1[NY][NZ], density1[NY][NZ], velZ1[NY][NZ];

void read_phi(char * filename);
void read_psi( );
void read_electronic_densities( );
void read_vel( );
void read_density( );


/****************************************************************************
 *  main
 ****************************************************************************/

int main(int argc, char ** argv) {

	float buffer_number;
	double time;

	printf("\nGetting time: ");
	sprintf(file,"Time2.temp");
	printf("%s\n", file);
	Reprise_file=fopen(file,"r");
	fscanf(Reprise_file,"%f", &buffer_number); 
	fclose(Reprise_file);
	time = buffer_number;


	printf("\nTreating file %f\n", time);
  	read_phi(argv[1]);
 	read_vel( );
	read_density( );

	FILE *file;
	file = fopen("velociy_result.txt", "w");
	fprintf(file, "k\tvel_k\tvel_prom\tvel_prom1\tvel_prom2\n");
	int i, j, k, ktemp;
	int icentre, jcentre, kcentre;
	icentre=(int)(NX/2.0);
	jcentre=(int)(NY/2.0);
	kcentre=(int)(NZ/2.0);
	int counter, counter1, counter2 = 0;
	float sum_vel, sum_vel1, sum_vel2 = 0;
	float vel_prom, vel_prom1, vel_prom2 = 0;
	for (k = 0; k < NZ-1; k++){
		counter += 1;
		sum_vel += vel[icentre][jcentre][k];
	// indice 1 es para phi > 0
	if ( phi[icentre][jcentre][k] > 0 ){
		counter1 +=1;
		sum_vel1 += vel[icentre][jcentre][k];
	}
	//indice 2 es para phi < 0
	if ( phi[icentre][jcentre][k] < 0){
		counter2 +=1;
		sum_vel2 += vel[icentre][jcentre][k];
	}
	//if ( phi[icentre][jcentre][k] == 0){
	//}
	float vel_prom = sum_vel / counter;
	float vel_prom1 = sum_vel1 / counter1;
	float vel_prom2 = sum_vel2 / counter2;
	fprintf(file, "%d\t%0.3f\%0.3f\%0.3f\%0.3f\n", k, vel[icentre][jcentre][k], vel_prom, vel_prom1, vel_prom2);
	}
	fclose(file);
} // End main






/*****************************************************************************
 *
 *  read_phi
 *
 *  It is assumed that the data are stored in a binary file
 *  arranged regularly with the k (z) index running fastest.
 *
 *  The data type read is float (4 bytes).
 *
 *****************************************************************************/

void read_phi(char * filename) {

  int   i, j, k, n;
  float tmp;
  FILE *Info_file; 
  float buffer; 	


/* 
	printf("\n\n%s\n\n", filename);
*/

  FILE * fp;

  if( (fp = fopen(filename,"r")) == NULL) {
    fprintf(stderr, "Failed to open phi file %s\n", filename);
    exit(0);
  }

	Info_file=fopen(filename,"r");			


  for (i = 0; i < NX; i++) {
    for (j = 0; j < NY; j++) {
      for (k = 0; k < NZ; k++) {

	fscanf(Info_file,"%f", &buffer);

	phi[i][j][k] = buffer;
      }
    }
  }

  fclose(fp);

/*
	for (i = 0; i < NX; i++) {
	    for (j = 0; j < NY; j++) {
	     	for (k = 0; k < NZ; k++) {
										printf("%i %i %i    ->   %0.6f e-3\n", i+1, j+1, k+1, phi[i][j][k]*1000.0);
							} } }
  */
  return;
}








void read_density( )
  {
  int   i, j, k, n; 
  FILE * fp;
  FILE *Info_file; 
  float buffer; 	

  sprintf(file,"Time.temp");
  stat_file=fopen(file,"r");
  fscanf(stat_file,"%s", buffer2);
  fclose(stat_file);
  sprintf(file,"rho%s", buffer2);
  printf("rho file  %s\n", file);
  

  if ( (Info_file=fopen(file,"r")) ==NULL)
    {
    printf("no rho file\n");
    for (i = 0; i < NX; i++) {
    for (j = 0; j < NY; j++) {
    for (k = 0; k < NZ; k++) {
	density[i][j][k] = 0.0 ;
	}}}
    }
    else
    {
    for (i = 0; i < NX; i++) {
    for (j = 0; j < NY; j++) {
    for (k = 0; k < NZ; k++) {
      density[i][j][k] = 0.0;
      fscanf(Info_file,"%f", &buffer);
      density[i][j][k] += buffer;
      }}}
    }

  }









void read_psi( )
	{
    int   i, j, k; 
    FILE * fp;
	FILE *Info_file; 
 	float buffer; 	

	sprintf(file,"Time.temp");
	stat_file=fopen(file,"r");
	fscanf(stat_file,"%s", buffer2);
	fclose(stat_file);
	sprintf(file,"psi-psi%s", buffer2);
	printf("Psi file  %s\n", file);
  

	if ( (Info_file=fopen(file,"r")) ==NULL)
		{
		printf("no psi file\n");
 		for (i = 0; i < NX; i++) {
    	for (j = 0; j < NY; j++) {
      	for (k = 0; k < NZ; k++) {
			psi[i][j][k] = 0.0 ;
			}}}
		}
	else
		{
 		for (i = 0; i < NX; i++) {
    	for (j = 0; j < NY; j++) {
      	for (k = 0; k < NZ; k++) {
			fscanf(Info_file,"%f", &buffer);
			psi[i][j][k] = buffer ;
	//		printf("%i %i %i  -> %0.6f\n", i, j, k, psi[i][j][k]);
			}}}
		}
			
	
	}



void read_electronic_densities( )
	{
    int   i, j, k; 
    FILE * fp;
	FILE *Info_file; 
 	float buffer; 	

// Electronic density
	sprintf(file,"Time.temp");
	stat_file=fopen(file,"r");
	fscanf(stat_file,"%s", buffer2);
	fclose(stat_file);
	sprintf(file,"elc-psi%s", buffer2);
	printf("rho_e file  %s\n", file);
  

	if ( (Info_file=fopen(file,"r")) ==NULL)
		{
		printf("no rho_e file\n");
 		for (i = 0; i < NX; i++) {
    	for (j = 0; j < NY; j++) {
      	for (k = 0; k < NZ; k++) {
			rho_e[i][j][k] = 0.0 ;
			}}}
		}
	else
		{
 		for (i = 0; i < NX; i++) {
    	for (j = 0; j < NY; j++) {
      	for (k = 0; k < NZ; k++) {
			fscanf(Info_file,"%f", &buffer);
			rho_e[i][j][k] = buffer ;
			}}}
		}
			
	
// rho 1
	sprintf(file,"Time.temp");
	stat_file=fopen(file,"r");
	fscanf(stat_file,"%s", buffer2);
	fclose(stat_file);
	sprintf(file,"rho0-psi%s", buffer2);
	printf("rho0 file  %s\n", file);
  

	if ( (Info_file=fopen(file,"r")) ==NULL)
		{
		printf("no rho0 file\n");
 		for (i = 0; i < NX; i++) {
    	for (j = 0; j < NY; j++) {
      	for (k = 0; k < NZ; k++) {
			rho_0[i][j][k] = 0.0 ;
			}}}
		}
	else
		{
 		for (i = 0; i < NX; i++) {
    	for (j = 0; j < NY; j++) {
      	for (k = 0; k < NZ; k++) {
			fscanf(Info_file,"%f", &buffer);
			rho_0[i][j][k] = buffer ;
			}}}
		}


// rho 2
	sprintf(file,"Time.temp");
	stat_file=fopen(file,"r");
	fscanf(stat_file,"%s", buffer2);
	fclose(stat_file);
	sprintf(file,"rho1-psi%s", buffer2);
	printf("rho1 file  %s\n", file);
  

	if ( (Info_file=fopen(file,"r")) ==NULL)
		{
		printf("no rho1 file\n");
 		for (i = 0; i < NX; i++) {
    	for (j = 0; j < NY; j++) {
      	for (k = 0; k < NZ; k++) {
			rho_1[i][j][k] = 0.0 ;
			}}}
		}
	else
		{
 		for (i = 0; i < NX; i++) {
    	for (j = 0; j < NY; j++) {
      	for (k = 0; k < NZ; k++) {
			fscanf(Info_file,"%f", &buffer);
			rho_1[i][j][k] = buffer ;
			}}}
		}



	}





void read_vel( )
	{
    int   i, j, k, n; 
    FILE * fp;
	FILE *Info_file; 
 	float buffer; 	

	sprintf(file,"Time.temp");
	stat_file=fopen(file,"r");
	fscanf(stat_file,"%s", buffer2);
	fclose(stat_file);
	sprintf(file,"vel%s", buffer2);
	printf("Vel file  %s\n", file);
  

	if ( (Info_file=fopen(file,"r")) ==NULL)
		{
		printf("no vel file\n");
 		for (i = 0; i < NX; i++) {
    		for (j = 0; j < NY; j++) {
      		for (k = 0; k < NZ; k++) {
			vel[i][j][k] = 0.0 ;
			}}}
		}
	else
		{


 		for (i = 0; i < NX; i++) {
    		for (j = 0; j < NY; j++) {
      		for (k = 0; k < NZ; k++) {
		vel[i][j][k] = 0.0;
		for (n = 1; n < 4 ; n++) 
				{
				fscanf(Info_file,"%f", &buffer);
				vel[i][j][k] += buffer*buffer*1000.0*1000.0 ;
				if (n == 1 ) { velX[i][j][k] = buffer*1000.0 ; }
				if (n == 2 ) { velY[i][j][k] = buffer*1000.0 ; }
				if (n == 3 ) { velZ[i][j][k] = buffer*1000.0 ; }
//				printf("%i %i %i n=%i  value %0.9f and value square %0.9f-> %0.9f\n", i, j, k, n, buffer, buffer*buffer, vel[i][j][k]);
				}
			vel[i][j][k] = sqrt(vel[i][j][k]);
//			printf("%i %i %i n=%i  value %f-> %0.9f\n\n", i, j, k, n, buffer, vel[i][j][k]);				
			}}}




		}
			
	
	}






