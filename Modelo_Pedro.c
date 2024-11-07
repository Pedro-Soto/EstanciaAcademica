#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define Pi 3.14159265359

int main()
	{
	double zmax, b, b0, a, eta, eta1, eta2, gradP, z, Deltaz, Deltat;
	double zinterf1, zinterf2, K, R;
	double t, v;
	FILE *archivo;
	char name[500];
	
	gradP=10.0;
	t=0;
	Deltat=1;
	Deltaz=0.01;
	zmax=4000;
	b0=100;
	a=40;
	eta1=1;
	eta2=0.01;
	
	zinterf1=0;
	zinterf2=zmax/2.0;
	
	sprintf(name, "Estado.dat");
	archivo = fopen(name, "w");
	fprintf(archivo, "#t v zinterf1 zinterf2 R\n");
	fclose(archivo);

	for (t=0; t<=100000; t+=Deltat)
		{	
		R=0;
		/*sprintf(name, "Resistencia_t%f.dat", t);
		archivo = fopen(name, "w");
		fprintf(archivo, "#z eta b Rlocal\n");*/
		for (z=0; z<zmax; z+=Deltaz)
			{
			if (zinterf1 <= zinterf2 && z >= zinterf1 && z<= zinterf2)	{ eta=eta1; }
			if (zinterf1 <= zinterf2 && (z < zinterf1 || z > zinterf2) )	{ eta=eta2; }		
			if (zinterf1 > zinterf2 &&  z >= zinterf2 && z<= zinterf1)	{ eta=eta2; }		
			if (zinterf1 > zinterf2 && (z > zinterf1 || z < zinterf2) )	{ eta=eta1; }						
			
			b = b0 + 2.0*a*sin(2.0*Pi*z/zmax);
			
			R += 12.0*eta/(b*b)*Deltaz;

			//fprintf(archivo, "%f %f %f %f\n", z, eta, b, 12.0*eta/b);
			}
	//	fclose(archivo);
		
		v=gradP/R;
		
		sprintf(name, "Estado.dat");
		archivo = fopen(name, "a");
		fprintf(archivo, "%f %f %f %f %f\n", t, v, zinterf1, zinterf2, R);
		fclose(archivo);
		
		zinterf1=zinterf1+v*Deltat;
		zinterf2=zinterf2+v*Deltat;
		if (zinterf1 >zmax) { zinterf1 = zinterf1-zmax; }
		if (zinterf2 >zmax) { zinterf2 = zinterf2-zmax; }
		
		}
	}
