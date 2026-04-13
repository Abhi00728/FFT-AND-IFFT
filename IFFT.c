#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <complex.h>

#define PI 3.14159265358979323846


void ifft_recursive(complex double *X, int n) {
    if (n <= 1) return;


    complex double even[n/2], odd[n/2];
    for (int i = 0; i < n / 2; i++) {
        even[i] = X[i * 2];
        odd[i] = X[i * 2 + 1];
    }


    ifft_recursive(even, n / 2);
    ifft_recursive(odd, n / 2);


    for (int k = 0; k < n / 2; k++) {
        complex double twiddle = cexp(I * 2.0 * PI * k / n) * odd[k]; // Inverse twiddle factor
        X[k] = (even[k] + twiddle);
        X[k + n / 2] = (even[k] - twiddle);
    }


    for (int i = 0; i < n; i++) {
        X[i] /= 2;  
    }
}


void print_complex_array(complex double *arr, int n) {
    for (int i = 0; i < n; i++) {
        printf("(%lf, %lf)\n", creal(arr[i]), cimag(arr[i]));
    }
}

int main() {
    int n;
    scanf("%d",&n);
    complex double X[n];
	for(int i=0;i<n;i++){
                double real,imag;
                scanf("%lf %lf",&real,&imag);
                X[i] = real + imag*I;
        }
	ifft_recursive(X, n);
    print_complex_array(X, n);

    return 0;
}

