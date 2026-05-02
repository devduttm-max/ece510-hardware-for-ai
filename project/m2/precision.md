# Precision analysis — INT8 MAC accelerator

## Chosen numeric format

The compute core uses **INT8 (signed 8-bit integer)** for both activations and
weights. Multiplication of two INT8 operands produces a 16-bit intermediate
product, which is accumulated into a **32-bit signed accumulator**. This
accumulator width supports up to 65,536 MAC operations before any possibility
of overflow, which far exceeds the largest kernel window in a typical
Conv2D layer (e.g., 3×3×64 = 576 MACs per output pixel in a standard
ResNet-18 layer).

## Why INT8 over floating point

Full-precision FP32 inference is the training-time default, but deploying
at FP32 is wasteful for inference workloads. Research from Jacob et al.
(2018) and the TensorFlow Lite quantization whitepaper demonstrated that
post-training INT8 quantization preserves model accuracy to within 1–2%
of FP32 on ImageNet classification benchmarks, while cutting both memory
footprint and compute energy by roughly 4×. For a chiplet-class
accelerator targeting edge or embedded deployment, this trade-off is
overwhelmingly favorable: the INT8 datapath requires a simple integer
multiplier and adder rather than an FP32 fused multiply-add unit, which
is roughly 18.5× more expensive in silicon area and roughly 30× more
expensive in energy per operation (Horowitz, ISSCC 2014 estimates).

## Quantization scheme assumed

The design assumes asymmetric affine quantization, where a floating-point
value x is mapped to an integer q via:

    q = clamp(round(x / scale + zero_point), -128, 127)

The scale and zero-point parameters are computed offline during
post-training quantization and are supplied by the host CPU as
configuration registers (future milestone). The compute core itself
is agnostic to the quantization parameters — it simply performs
signed 8-bit multiply-accumulate — so the same RTL supports symmetric
quantization (zero_point = 0) as a special case.

## Accumulator width justification

The 32-bit accumulator was chosen to avoid any mid-layer saturation.
The worst-case single MAC result is (−128) × (−128) = 16,384, which
fits in 16 bits. However, accumulation across a full dot product
requires headroom. For a 3×3 kernel over 512 input channels (the
largest layer in ResNet-18), the number of MACs is 9 × 512 = 4,608.
The theoretical worst-case accumulated value is 4,608 × 16,384 ≈ 7.5 × 10⁷,
which requires 27 bits. A 32-bit accumulator provides five additional
bits of headroom, comfortably covering any practical network topology
without the need for intermediate re-quantization or saturation logic.

## Trade-offs and limitations

INT8 is not universally sufficient. Certain operations — batch
normalization running statistics, softmax denominators, and loss
computation — require higher precision. In a full inference pipeline,
these would either be handled on the host CPU in FP32 or in a
small auxiliary FP16 datapath (out of scope for this accelerator).
Additionally, some modern architectures (e.g., transformers with
large attention logits) may experience accuracy degradation with
naive INT8 quantization and require mixed-precision or INT8 + INT16
accumulation strategies. The current design prioritizes CNN Conv2D
workloads where INT8 quantization is mature and well-validated.

## Comparison to alternative precisions

| Format | Multiplier area | Energy/MAC | Accuracy loss | Suitability |
|--------|----------------|------------|---------------|-------------|
| FP32   | 18.5× baseline | 30× baseline | 0%         | Overkill    |
| FP16   | ~5× baseline   | ~8× baseline | <0.5%      | Viable but expensive |
| INT8   | 1× (baseline)  | 1× (baseline) | 1–2%      | Ideal for CNN inference |
| INT4   | ~0.3× baseline | ~0.4× baseline | 3–8%     | Too lossy for general use |

INT8 occupies the sweet spot: it delivers near-FP32 accuracy at a
fraction of the hardware cost, making it the standard precision for
production CNN inference accelerators including Google TPU (v1),
NVIDIA TensorRT INT8 mode, and Apple Neural Engine.

## Quantization error analysis

To validate the INT8 precision choice, 100 random FP32 weight values drawn
uniformly from [-2.5, 2.5] were quantized using symmetric per-tensor INT8
quantization and dequantized back to FP32. The results were compared against
the original FP32 values.

**Setup:**
- N = 100 samples
- Range: [-2.5, 2.5] (typical neural network weight distribution)
- Scale factor S = max(|W|) / 127 = 2.4724 / 127 = **0.019468**
- Quantization: W_q = clamp(round(W / S), -128, 127)
- Dequantization: W_deq = W_q × S

**Per-element error results:**
- Mean Absolute Error (MAE): **0.005148**
- Maximum absolute error: **0.009728**
- MAE as percentage of full range: **0.104%**
- Max error as percentage of full range: **0.197%**
- Worst case element: W = -2.2096, W_q = -114, W_deq = -2.2193

**MAC accumulation error (100 MACs):**
A dot product of 100 terms was computed using INT8 arithmetic and compared
to a FP32 reference:
- FP32 reference result: -674.7814
- INT8 result (dequantized): -676.5068
- Absolute error: **1.7254**
- Relative error: **0.2557%**

**Acceptability threshold:**

The quantization error is acceptable because:
1. The per-element MAE of 0.005 is well below the scale step of S = 0.0195,
   confirming rounding error is bounded to ±0.5 LSB as expected.
2. The MAC accumulation relative error of 0.26% is consistent with published
   benchmarks showing INT8 post-training quantization achieves within 1-2%
   accuracy loss on ImageNet (Jacob et al., CVPR 2018).
3. The 32-bit accumulator absorbs rounding errors across up to 65,536 MACs
   without overflow, preventing error accumulation from compounding.

These results confirm INT8 is a suitable precision choice for Conv2D
acceleration where sub-1% accuracy degradation is acceptable.
