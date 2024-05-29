/***************************************************************************
 *cr
 *cr            (C) Copyright 2010 The Board of Trustees of the
 *cr                        University of Illinois
 *cr                         All Rights Reserved
 *cr
 *cr   This version maintained by: Nasser Anssari (anssari1@illinois.edu)
 ***************************************************************************/

 #include <stdio.h>
 #include <stdlib.h>
 #include <cuda_runtime.h>
 
 #include "file.h"
 #include "kernel.h"
 
 void readVectorBinary(const char* filename, float** vector, unsigned* size) {
     FILE* file = fopen(filename, "rb");
     if (file == NULL) {
         fprintf(stderr, "Error opening file %s\n", filename);
         exit(EXIT_FAILURE);
     }
 
     // Read the size of the vector
     fread(size, sizeof(unsigned), 1, file);
 
     // Allocate memory for the vector
     *vector = (float*)malloc(*size * sizeof(float));
     if (*vector == NULL) {
         fprintf(stderr, "Unable to allocate memory for vector %s\n", filename);
         exit(EXIT_FAILURE);
     }
 
     // Read the vector data
     fread(*vector, sizeof(float), *size, file);
 
     fclose(file);
 }
 
 void writeVectorBinary(const char* filename, const float* vector, unsigned size) {
     FILE* file = fopen(filename, "wb");
     if (file == NULL) {
         fprintf(stderr, "Error opening file %s\n", filename);
         exit(EXIT_FAILURE);
     }
 
     // Write the size of the vector
     fwrite(&size, sizeof(unsigned), 1, file);
 
     // Write the vector data
     fwrite(vector, sizeof(float), size, file);
 
     fclose(file);
 }
 
 int main(int argc, char *argv[]) {
     float *A_h, *B_h, *C_h;
     float *A_d, *B_d, *C_d;
     unsigned vec_size;
     cudaError_t cuda_ret;
     dim3 dim_grid, dim_block;
 
     if (argc != 3) {
         fprintf(stderr, "Usage: %s <input1.dat> <input2.dat>\n", argv[0]);
         return EXIT_FAILURE;
     }
 
     /* Initialize input vectors */
     readVectorBinary(argv[1], &A_h, &vec_size);
     readVectorBinary(argv[2], &B_h, &vec_size);
 
     printf("Vector size: %u\n", vec_size);
 
     /* Allocate host memory */
     C_h = (float *)malloc(vec_size * sizeof(float));
     if(C_h == NULL) {
         fprintf(stderr, "Unable to allocate host memory for C_h\n");
         return EXIT_FAILURE;
     }
 
     /********************************************************************
     Allocate device memory for the input/output vectors
     ********************************************************************/
     cuda_ret = cudaMalloc((void**)&A_d, vec_size * sizeof(float));
     if (cuda_ret != cudaSuccess) {
         fprintf(stderr, "Unable to allocate device memory for A\n");
         return EXIT_FAILURE;
     }
     
     cuda_ret = cudaMalloc((void**)&B_d, vec_size * sizeof(float));
     if (cuda_ret != cudaSuccess) {
         fprintf(stderr, "Unable to allocate device memory for B\n");
         return EXIT_FAILURE;
     }
     
     cuda_ret = cudaMalloc((void**)&C_d, vec_size * sizeof(float));
     if (cuda_ret != cudaSuccess) {
         fprintf(stderr, "Unable to allocate device memory for C\n");
         return EXIT_FAILURE;
     }
 
     /********************************************************************
     Copy the input vectors from the host memory to the device memory
     ********************************************************************/
     cuda_ret = cudaMemcpy(A_d, A_h, vec_size * sizeof(float), cudaMemcpyHostToDevice);
     if (cuda_ret != cudaSuccess) {
         fprintf(stderr, "Unable to copy memory to device for A\n");
         return EXIT_FAILURE;
     }
     
     cuda_ret = cudaMemcpy(B_d, B_h, vec_size * sizeof(float), cudaMemcpyHostToDevice);
     if (cuda_ret != cudaSuccess) {
         fprintf(stderr, "Unable to copy memory to device for B\n");
         return EXIT_FAILURE;
     }
 
     cuda_ret = cudaMemset(C_d, 0, vec_size * sizeof(float));
     if(cuda_ret != cudaSuccess) {
         fprintf(stderr, "Unable to set device memory\n");
         return EXIT_FAILURE;
     }
 
     /********************************************************************
     Initialize thread block and kernel grid dimensions
     ********************************************************************/
     int threads_per_block = 512;
     int num_blocks = (vec_size + threads_per_block - 1) / threads_per_block;
 
     dim_block = dim3(threads_per_block, 1, 1);
     dim_grid = dim3(num_blocks, 1, 1);
 
     /********************************************************************
     Invoke CUDA kernel
     ********************************************************************/
     vecAdd<<<dim_grid, dim_block>>>(C_d, A_d, B_d, vec_size);
     cuda_ret = cudaGetLastError();
     if(cuda_ret != cudaSuccess) {
         fprintf(stderr, "Kernel launch failed: %s\n", cudaGetErrorString(cuda_ret));
         return EXIT_FAILURE;
     }
 
     cuda_ret = cudaDeviceSynchronize();
     if(cuda_ret != cudaSuccess) {
         fprintf(stderr, "Kernel execution failed: %s\n", cudaGetErrorString(cuda_ret));
         return EXIT_FAILURE;
     }
 
     printf("Kernel executed successfully\n");
 
     /********************************************************************
     Copy the result back to the host
     ********************************************************************/
     cuda_ret = cudaMemcpy(C_h, C_d, vec_size * sizeof(float), cudaMemcpyDeviceToHost);
     if (cuda_ret != cudaSuccess) {
         fprintf(stderr, "Unable to copy memory to host for C\n");
         return EXIT_FAILURE;
     }
 
     printf("Memory copied back to host successfully\n");
 
     /********************************************************************
     Print the first 10 values of C_h
     ********************************************************************/
     for (unsigned i = 0; i < 10 && i < vec_size; ++i) {
         printf("C_h[%u] = %f\n", i, C_h[i]);
     }
 
     /********************************************************************
     Write the result vector to a binary file for verification
     ********************************************************************/
     writeVectorBinary("output.dat", C_h, vec_size);
 
     /********************************************************************
     Free device memory allocations
     ********************************************************************/
     cudaFree(A_d);
     cudaFree(B_d);
     cudaFree(C_d);
 
     free(A_h);
     free(B_h);
     free(C_h);
 
     return 0;
 }
 