import sys
import torchvision.models as models
from torchinfo import summary

# Load ResNet-18 without pretrained weights (architecture only)
model = models.resnet18(weights=None)

# Profile a single FP32 forward pass with batch=1, input 3×224×224
result = summary(
    model,
    input_size=(1, 3, 224, 224),
    col_names=["input_size", "output_size", "num_params", "mult_adds"],
    depth=10,   # expand all nested layers
    verbose=0,  # suppress automatic printing
)

# Save full profile to file
with open("resnet18_profile.txt", "w", encoding="utf-8") as f:
    f.write(str(result))

# Print to terminal (bypass Windows cp1252 encoding issues)
sys.stdout.buffer.write(str(result).encode("utf-8"))
sys.stdout.buffer.write(b"\n")
