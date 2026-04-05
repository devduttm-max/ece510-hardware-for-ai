# ResNet-18 Profiling Analysis

## Top-5 Layers by MAC Count

| Rank | Layer Name   | Output Shape       | MACs        | Parameters |
|------|--------------|--------------------|-------------|------------|
| 1    | Conv2d: 1-1  | [1, 64, 112, 112]  | 118,013,952 | 9,408      |
| 2    | Conv2d: 3-1  | [1, 64, 56, 56]    | 115,605,504 | 36,864     |
| 3    | Conv2d: 3-4  | [1, 64, 56, 56]    | 115,605,504 | 36,864     |
| 4    | Conv2d: 3-7  | [1, 64, 56, 56]    | 115,605,504 | 36,864     |
| 5    | Conv2d: 3-10 | [1, 64, 56, 56]    | 115,605,504 | 36,864     |

---

## Arithmetic Intensity of the Most MAC-Intensive Layer

**Layer:** Conv2d: 1-1 — first convolution, 7×7 kernel, 3→64 channels, stride 2  
**Input shape:** [1, 3, 224, 224] → **Output shape:** [1, 64, 112, 112]

### FLOPs

```
FLOPs = 2 × MACs = 2 × 118,013,952 = 236,027,904 FLOPs
```

### Memory bytes (all weights and activations loaded from DRAM, no reuse)

| Item             | Calculation                        | Bytes      |
|------------------|------------------------------------|------------|
| Weights          | 9,408 params × 4 bytes/param       | 37,632     |
| Input activation | 1 × 3 × 224 × 224 × 4 bytes       | 602,112    |
| Output activation| 1 × 64 × 112 × 112 × 4 bytes      | 3,211,264  |
| **Total**        |                                    | **3,851,008** |

### Arithmetic Intensity

```
AI = FLOPs / bytes
   = 236,027,904 / 3,851,008
   ≈ 61.3 FLOP/byte
```

**Result: ~61.3 FLOP/byte**
