# Interface selection — INT8 MAC accelerator

## Host platform

The assumed host platform is a laptop CPU (Intel Core i5-1135G7) acting as the
host processor, connected to the INT8 MAC accelerator chiplet via an on-chip
interconnect. The accelerator is treated as an FPGA SoC peripheral for
prototyping purposes.

## Interface chosen: AXI4 Stream

AXI4 Stream is selected from the project interface table. It provides
unidirectional streaming suitable for continuous convolution data flow, pairs
well with AXI4-Lite for control signals, and delivers sufficient bandwidth at
medium implementation complexity. It is described as a natural fit for inference
pipelines with continuous data flow, which directly matches the Conv2D._im2col
kernel pattern where input patches and weights are streamed continuously into
the MAC array.

SPI and I²C were ruled out immediately — their bandwidths of 50 Mbit/s and
3.4 Mbit/s respectively are orders of magnitude below the required 2 GB/s.
PCIe would provide sufficient bandwidth but introduces unnecessary complexity
for an FPGA SoC prototype. UCIe is appropriate only for multi-die chiplet
designs which is beyond the scope of this project.

## Bandwidth requirement calculation

The Conv2D._im2col kernel transfers 279,104 bytes per forward pass call. At
the target operating point of 1 billion MACs/second, the required bandwidth is:

Required bandwidth = throughput × data width per MAC
= 1,000,000,000 MACs/sec × 2 bytes/MAC (1 byte activation + 1 byte weight)
= 2 GB/s

## Interface rated bandwidth vs required bandwidth

AXI4 Stream at 200 MHz with a 128-bit (16-byte) data bus:
Rated bandwidth = 200,000,000 Hz × 16 bytes = 3.2 GB/s

Since 3.2 GB/s > 2 GB/s, the design is not interface-bound at the target
throughput. There is a 1.2 GB/s margin.

A 64-bit AXI4 Stream at 200 MHz delivers only 1.6 GB/s, which would be
interface-bound at the 2 GB/s target and is therefore not suitable.

## Bottleneck status

The design is not interface-bound on the roofline at the target throughput
when using a 128-bit AXI4 Stream bus. The bottleneck remains the on-chip
compute throughput, which is the intended outcome — the accelerator is
compute-bound rather than interface-bound or memory-bound.