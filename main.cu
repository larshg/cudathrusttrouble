#include "data_source.hpp"
#include <iostream>
#include <cstdlib>
#include <cuda_runtime_api.h>
#include <thrust/reduce.h>
#include <thrust/device_ptr.h>
#include <thrust/device_vector.h>

template <typename T>
struct LARGERT
{
  __host__ __device__ __forceinline__
    T operator()(const T& x, const T& y) const {
    float4 result;
    printf("Adress first: %p\n", (void*)&x);
    printf("Adress second: %p\n", (void*)&y);
    printf("comparing LargerT: %f, %f, %f with %f %f %f\n", x.x, x.y, x.z, y.x, y.y, y.z);
    result.x = fmax(x.x, y.x);
    result.y = fmax(x.y, y.y);
    result.z = fmax(x.z, y.z);
    return result;
  }
};

template <typename T>
struct LESST
{
  __host__ __device__ __forceinline__
    T operator()(const T& x, const T& y) const {
    float4 result;
    printf("Adress first: %p\n", (void*)&x);
    printf("Adress second: %p\n", (void*)&y);
    printf("comparing LessT: %f, %f, %f with %f %f %f\n", x.x, x.y, x.z, y.x, y.y, y.z);
    result.x = fmin(x.x, y.x);
    result.y = fmin(x.y, y.y);
    result.z = fmin(x.z, y.z);
    return result;
  }
};

void error(const char* error_string, const char* file, const int line, const char* func)
{
  std::cout << "Error: " << error_string << "\t" << file << ":" << line << std::endl;
  exit(EXIT_FAILURE);
}

static inline void ___cudaSafeCall(cudaError_t err, const char* file, const int line, const char* func = "")
{
  if (cudaSuccess != err)
    error(cudaGetErrorString(err), file, line, func);
}

#define cudaSafeCall(expr)  ___cudaSafeCall(expr, __FILE__, __LINE__)


void FilterPoints(float4* baseAddress, size_t sizeBytes_)
{
  /** \brief Device pointer. */
  void* data_;

  cudaSafeCall(cudaMalloc(&data_, sizeBytes_));
  cudaSafeCall(cudaMemcpy(data_, baseAddress, sizeBytes_, cudaMemcpyHostToDevice));
  cudaSafeCall(cudaDeviceSynchronize());


  float4 max;
  max.x = max.y = max.z = FLT_MAX;
  max.w = 0;

  float4 min;
  min.x = min.y = min.z = -FLT_MAX;
  min.w = 0;

  thrust::device_ptr<float4> beg((float4*)data_);
  thrust::device_ptr<float4> end = beg + sizeBytes_ / 16;
  std::cout << "Before reduce" << std::endl;
  float4 minp = thrust::reduce(beg, end, max, LESST<float4>{});
  float4 maxp = thrust::reduce(beg, end, min, LARGERT<float4>{});

  std::cout << "minp is: " << minp.x << "," << minp.y << "," << minp.z << std::endl;
  std::cout << "maxp is: " << maxp.x << "," << maxp.y << "," << maxp.z << std::endl;
}

int main(void)
{
  DataGenerator data;
  data.data_size = 2;
  data.tests_num = 10000;
  data.cube_size = 1024.f;
  data.max_radius = data.cube_size / 30.f;
  data.shared_radius = data.cube_size / 30.f;
  data.printParams();
  //generate
  data();

  size_t sizeBytes_ = data.data_size * 16;

  std::cout << "Before filter" << std::endl;
  FilterPoints(&data.points[0], sizeBytes_);

  return 0;
}