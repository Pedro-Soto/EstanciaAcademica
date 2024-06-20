#include <stdio.h>
#include <math.h>

int main () {
    // Declare all variables
    int delta_t;
    printf("Enter value for Delta_t:\n");
    if (scanf("%d" ,&delta_t)!=1) {
        fprintf(stderr,"Error: Delta_t only accepts integer value\n");    
        return 1;    
    }
    int t;
    int L;
    printf("Enter value for L:\n");
    if (scanf("%d" ,&L)!=1) {
        fprintf(stderr,"Error: L only accepts integer value\n");
        return 1; 
    }
    double pi = acos (-1);
    float z2;
    int b0;
    //starting pressure
    float P1;
    printf("Enter value for pressure at canal start |P1|:\n");
    if (scanf("%f" ,&P1)!=1) {
        fprintf(stderr,"Error: P1 only accepts float value\n");
        return 1;
    }
    //ending pressure, should be P2>P1
    float P2;
    printf("Enter value for pressure at canal end: |P2|\n");
    if (scanf("%f" ,&P2)!=1){
        fprintf(stderr,"Error: P2 only accepts float value\n");
        return 1;
    }
    float deltaP = P2 - P1;
    if (deltaP < 0){
        fprintf(stderr,"Error: P2 should be greater than P1\n");
        return 1;
    }
    printf("deltaP = %f\n", deltaP);
    float pressure_grad = deltaP / L;
    
    return 0;
    
}
