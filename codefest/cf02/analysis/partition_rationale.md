# HW/SW partition proposal — INT8 MAC accelerator for CNN convolution

## (a) Which kernel to accelerate in hardware and roofline justification

The kernel selected for hardware acceleration is `Conv2D._im2col` and the
associated matrix multiply in `Conv2D.forward`, which together account for 14.2%
of total CNN training runtime. The roofline analysis places this kernel at an
arithmetic intensity of 1.057 FLOP/byte, well below the ridge point of 5.25
FLOP/byte on the Intel i5-1135G7. This confirms the kernel is memory-bound on
current hardware. The roofline position directly supports hardware acceleration:
the convolution spends most of its time moving data between DRAM and compute units
rather than performing multiply-accumulate operations. A dedicated INT8 MAC
accelerator with on-chip SRAM buffers for weights and activations would eliminate
repeated DRAM accesses, increasing effective arithmetic intensity and shifting the
kernel toward the compute-bound region.

## (b) What the software baseline will continue to handle

The software baseline will continue to handle all non-convolution operations
including data loading, preprocessing, MaxPool2D, ReLU activations, Dense layer
forward and backward passes, the Adam optimizer update, and loss computation.
These operations either have low computational intensity or are not amenable to
MAC acceleration. The host CPU running Python will orchestrate data movement
between memory and the accelerator and handle all control flow between layers.

## (c) Interface bandwidth required to avoid becoming interface-bound

Per forward pass the Conv2D kernel transfers 279,104 bytes. With 228 calls over
2.213 seconds, the average data rate is:

Required bandwidth = (228 × 279,104 bytes) / 2.213 seconds = ~28.7 MB/s

This is well within any standard interface for the current problem size. For a
scaled-up design targeting 1 billion MACs/second, the required bandwidth becomes:

Required bandwidth = 2 × 1,000,000,000 bytes/sec = 2 GB/s

AXI4 Stream at 200 MHz with a 128-bit data bus delivers approximately 3.2 GB/s,
which comfortably avoids the interface bottleneck. A 64-bit AXI4 Stream at 200 MHz
delivers 1.6 GB/s, which would be marginally interface-bound at this target and
should be avoided.

## (d) Bound classification and whether the accelerator changes it

The Conv2D._im2col kernel is currently memory-bound at 1.057 FLOP/byte on the
i5-1135G7 CPU, sitting below the ridge point of 5.25 FLOP/byte. The proposed
hardware accelerator changes this by storing filter weights and input activation
patches in on-chip SRAM rather than fetching them from DRAM on every convolution
call. With on-chip storage, the bytes transferred per MAC drop significantly,
pushing the effective arithmetic intensity above the hardware ridge point. This
shifts the kernel from memory-bound to compute-bound, which is the primary goal
of the accelerator design and the key improvement over the software baseline.