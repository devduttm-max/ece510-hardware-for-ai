# Software baseline benchmark — Conv2D._im2col kernel (cnn_backprop)

## Platform configuration

- CPU: Intel Core i5-1135G7 @ 2.40 GHz (Turbo up to 4.2 GHz)
- Cores: 4 cores, 8 threads
- OS: Windows 11
- Python version: 3.13.7
- Memory: DDR4-3200 dual-channel
- Dataset: synthetic, 2000 training samples, 400 validation samples
- Config: small (8 filters, 3x3 kernel, batch size 32)
- Epochs: 3

## Execution time

- Total training time: 2.213 seconds (3 epochs)
- Conv2D._im2col cumulative time: 0.205 seconds (228 calls)
- Average per call: ~0.001 seconds

## Throughput

- 228 calls in 0.205 seconds = ~1,112 calls/second
- MACs per call: 294,912
- MAC throughput: ~327 million MACs/second

## Memory usage

- Input patches per batch: 147,456 bytes (~144 KB)
- Weights: 576 bytes
- Output activations: 131,072 bytes (~128 KB)
- Total peak memory per forward pass: ~273 KB

## Notes

This baseline uses a pure Python loop implementation of im2col in NumPy with
FP64 arithmetic. It does not exploit SIMD, vectorization, or any hardware
acceleration. This represents the worst-case software performance that a
dedicated INT8 MAC hardware accelerator is compared against in Milestone 4.