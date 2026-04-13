# Heilmeier catechism — INT8 MAC accelerator for CNN convolution

## Q1. What are you trying to do?

I am designing a custom MAC hardware unit optimized for 8-bit integer (INT8)
arithmetic instead of 32-bit floating-point (FP32), specifically targeting the
convolution kernel (Conv2D._im2col) in CNN inference. The goal is to replace the
memory-bound software convolution loop with a dedicated accelerator that stores
weights and activations on-chip, eliminating repeated DRAM accesses and increasing
throughput for neural network inference on resource-constrained devices.

## Q2. How is it done today, and what are the limits of current practice?

Today, CNN convolutions are executed on general-purpose CPUs using FP32 or FP64
arithmetic with data fetched from DRAM on every operation. Profiling the
cnn_backprop reference implementation on an Intel i5-1135G7 shows that
Conv2D._im2col accounts for 9.3% of total training runtime and the broader
Conv2D.forward accounts for 14.2%, with an arithmetic intensity of only 1.057
FLOP/byte. The ridge point of this CPU is 5.25 FLOP/byte, meaning the kernel is
firmly memory-bound — the compute units sit idle waiting for data. Each weight and
activation requires 8 bytes of storage in FP64, placing heavy demand on the 51.2
GB/s memory bandwidth. On edge and battery-powered devices, DRAM accesses dominate
energy consumption, making FP32/FP64 convolution impractical for real-time
inference [1].

## Q3. What is new in my approach and why do I think it will be successful?

My approach designs a dedicated MAC unit that operates natively on INT8 operands
and stores weights and activations in on-chip SRAM rather than fetching them from
DRAM. Reducing operand width from 64 bits to 8 bits yields an 8x reduction in
memory bandwidth demand per operand. The profiling data shows the current kernel
sits at 1.057 FLOP/byte, well below the ridge point of 5.25 FLOP/byte. By
eliminating DRAM accesses through on-chip buffering, the effective arithmetic
intensity increases well above the ridge point, shifting the kernel from
memory-bound to compute-bound. My contribution is a detailed PPA (power,
performance, area) analysis of this INT8 MAC datapath compared to the FP32
baseline. Neural networks tolerate INT8 quantization with under 1% accuracy loss
on standard benchmarks [2], confirming the precision trade-off is acceptable in
practice.

## Bibliography

[1] M. Horowitz, "Computing's energy problem (and what we can do about it),"
ISSCC, 2014.

[2] B. Jacob et al., "Quantization and Training of Neural Networks for Efficient
Integer-Arithmetic-Only Inference," CVPR, 2018.