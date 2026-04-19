# GEMM analysis — naive vs tiled (Tesla T4, 1024×1024 FP32)

## Hardware platform

- GPU: Tesla T4 (Kaggle cloud)
- Peak FP32 compute: 8,100 GFLOP/s (8.1 TFLOPS)
- Peak memory bandwidth: 300 GB/s
- Ridge point: 8,100 / 300 = 27 FLOP/byte
- Profiling tool: Nsight Compute (ncu). Note: hardware performance counter
  access was unavailable on Kaggle (ERR_NVGPUCTRPERM). Timing was measured
  using cudaEventRecord.

## Results

| Kernel | Execution time | Achieved GFLOP/s |
|--------|---------------|------------------|
| Naive  | 128.355 ms    | 16.73 GFLOP/s    |
| Tiled  | 33.785 ms     | 63.56 GFLOP/s    |

Tiled kernel is 3.8x faster than naive.

## (a) Why the naive kernel is memory-bound

The naive kernel assigns one thread per output element. To compute C[i][j],
each thread independently loads an entire row of A and an entire column of B
from DRAM. Matrix B is accessed in a column-major pattern which causes
uncoalesced memory accesses — adjacent threads read non-adjacent memory
locations, wasting memory bandwidth. Despite having an arithmetic intensity
of 170.67 FLOP/byte which sits above the ridge point of 27 FLOP/byte, the
naive kernel achieves only 16.73 GFLOP/s — far below the 8,100 GFLOP/s
ceiling. This gap is caused by the uncoalesced access pattern forcing
repeated DRAM fetches with poor bandwidth utilization.

## (b) How tiling reduces DRAM traffic

The tiled kernel loads T×T blocks of A and B into shared memory (on-chip
SRAM) before computing. Each element loaded into shared memory is reused T
times within the tile before being discarded. With tile size T=8, each DRAM
load is reused 8 times, reducing DRAM traffic by a factor of T compared to
the naive case. Adjacent threads now access adjacent memory locations when
loading tiles, producing coalesced memory accesses that fully utilize the
memory bus bandwidth.

## (c) Whether the tiled kernel achieved the expected improvement

The tiled kernel achieved 63.56 GFLOP/s compared to 16.73 GFLOP/s for the
naive kernel — a 3.8x improvement. This is a significant gain but still far
below the T4 compute ceiling of 8,100 GFLOP/s. The remaining bottleneck is
the small tile size of T=8 which limits arithmetic intensity and occupancy.
A larger tile size (e.g. T=32) would increase data reuse further and push
the kernel closer to the compute ceiling. Additionally, the shared memory
bank conflicts and thread occupancy limitations at T=8 leave substantial
compute throughput unused.