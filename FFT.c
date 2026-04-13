#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <complex.h>
void fft(complex double *X,int n){
	if(n <= 1)
		return;
	complex double *even = malloc((n/2)*sizeof(complex double));
	complex double *odd  = malloc((n/2)*sizeof(complex double));
	for(int i = 0; i<n/2;i++){
		even[i] = X[2*i];
		odd[i] = X[2*i + 1];
	}
	fft(even,n/2);
	fft(odd,n/2);
	for(int k = 0;k<n/2;k++){
		complex double t = cexp(-2.0*I*3.14*k/n)*odd[k];
		X[k] = even[k] + t;
		X[k+n/2] = even[k] - t;
	}
	free(even);
	free(odd);
}
int main(){
	int n;
	scanf("%d",&n);
	complex double X[n];
	for(int i=0;i<n;i++){
		double real,imag;
		scanf("%lf %lf",&real,&imag);
		X[i] = real + imag*I;
	}
	fft(X,n);
	for (int i = 0; i < n; i++) {
        	printf("X[%d] = %.2f + %.2fi\n", i, creal(X[i]), cimag(X[i]));
    	}
}

