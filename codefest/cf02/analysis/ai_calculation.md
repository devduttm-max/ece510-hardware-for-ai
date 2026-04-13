# Arithmetic intensity calculation — Conv2D._im2col kernel (cnn_backprop)

## Dominant kernel identification

Profiling was performed using cProfile on train.py with the synthetic dataset,
3 epochs, small config (batch size 32, 8 filters, 3x3 kernel, 16x16 input).

The dominant kernel is `Conv2D._im2col` in cnn.py:91, called 228 times with a
cumulative time of 0.205 seconds, accounting for approximately 9.3% of total
training time (2.213 seconds). The broader Conv2D.forward (cnn.py:43) accounts
for 14.2% of total runtime and contains _im2col as its core bottleneck.

## Layer configuration (small config, synthetic dataset)

- Batch size N = 32
- Input channels C_in = 1
- Kernel size k = 3
- Output spatial size H_out = W_out = 8 (from 16x16 input, same padding, pool 2x2)
- Output channels C_out = 8
- Data type: FP64 (8 bytes per element)

## FLOPs calculation

Formula: FLOPs = 2 × N × C_in × k² × H_out × W_out × C_out

Substituted values:
FLOPs = 2 × 32 × 1 × 9 × 8 × 8 × 8 = **294,912 FLOPs**

The factor of 2 counts one multiply and one accumulate per MAC operation.

## Bytes transferred (DRAM, no reuse)

- Load input patches: N × C_in × k² × H_out × W_out × 8 bytes
  = 32 × 1 × 9 × 64 × 8 = 147,456 bytes
- Load weights: C_out × C_in × k² × 8 bytes
  = 8 × 1 × 9 × 8 = 576 bytes
- Store output: N × C_out × H_out × W_out × 8 bytes
  = 32 × 8 × 64 × 8 = 131,072 bytes
- Total: **279,104 bytes**

## Arithmetic intensity

AI = 294,912 / 279,104 = **~1.057 FLOP/byte**

## Classification

Ridge point for Intel i5-1135G7:
- Peak FP32 compute: 4 cores × 4.2 GHz × 16 FLOP/cycle (AVX2 + FMA) = 268.8 GFLOP/s
  Source: Intel ARK (https://ark.intel.com/content/www/us/en/ark/products/208658)
  confirms 4 cores, 4.2 GHz max turbo. AVX2 + FMA gives 2 × 8 FP32 FLOPs/cycle
  per core = 16 FLOP/cycle, a standard Tiger Lake specification.
- Peak memory bandwidth: 51.2 GB/s (DDR4-3200, dual-channel)
  Source: Intel ARK (https://ark.intel.com/content/www/us/en/ark/products/208658)
  lists max memory bandwidth as 51.2 GB/s for the i5-1135G7.
- Ridge point: 268.8 / 51.2 = **5.25 FLOP/byte**

Since 1.057 < 5.25, the Conv2D._im2col kernel is **memory-bound** on this hardware.

This confirms the project motivation: even the core convolution kernel in a real
CNN is bottlenecked by memory bandwidth, not compute. A dedicated INT8 MAC
accelerator with on-chip SRAM for weights and activations would eliminate repeated
DRAM accesses and shift this kernel toward the compute-bound region.