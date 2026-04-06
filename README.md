# ece510-hardware-for-ai-ml

**Name:** Devdutt M.  
**Course:** ECE 410/510 Spring 2026  
**Project topic:** Custom MAC accelerator: designing an efficient INT8 multiply-accumulate unit optimized for neural network inference

---

## Course overview

This course explores the hardware foundations of artificial intelligence and machine learning. Topics include workload analysis, neural network inference, hardware accelerator design, and the trade-offs between precision, power, and performance in AI systems.

---

## Project overview

Modern AI inference on edge devices is bottlenecked by the cost of 32-bit floating-point (FP32) arithmetic. This project designs a custom Multiply-Accumulate (MAC) hardware unit that operates on 8-bit integers (INT8) instead of FP32. By reducing operand width from 32 bits to 8 bits, the design achieves a 4x improvement in memory bandwidth utilization and a simpler arithmetic datapath, making it better suited for battery-powered and resource-constrained devices. The contribution is a detailed PPA (power, performance, area) analysis of the INT8 MAC unit compared to a baseline FP32 MAC.

---

## Languages and tools

- Python — model profiling and workload analysis
- PyTorch — ResNet-18 profiling via torchinfo
- Markdown — documentation and analysis write-ups
- Git / GitHub — version control and submission

---
