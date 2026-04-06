import torchvision.models as models
from torchinfo import summary

model = models.resnet18(weights=None)

result = summary(
    model,
    input_size=(1, 3, 224, 224),
    col_names=["input_size", "output_size", "num_params", "mult_adds"],
    depth=10,
    verbose=0,
)

with open("resnet18_profile.txt", "w", encoding="utf-8") as f:
    f.write(str(result))

import sys
sys.stdout.buffer.write(str(result).encode("utf-8"))
sys.stdout.buffer.write(b"\n")
