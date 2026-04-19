import torch
import torch.nn as nn
import sys

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

if device.type != "cuda":
    print("No CUDA GPU found. Exiting.")
    sys.exit(1)

print(f"Device: {torch.cuda.get_device_name(0)}")

model = nn.Sequential(
    nn.Linear(4, 5),
    nn.ReLU(),
    nn.Linear(5, 1)
)

model.to(device)

x = torch.randn(16, 4)
x = x.to(device)

output = model(x)

print(f"Output shape: {output.shape}")
print(f"Output device: {output.device}")
