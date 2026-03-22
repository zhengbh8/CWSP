#include <cstdio>

__global__ void k() { printf("hello from GPU!\n"); }

int main() {
  k<<<1,1>>>();
  cudaDeviceSynchronize();
  return 0;
}