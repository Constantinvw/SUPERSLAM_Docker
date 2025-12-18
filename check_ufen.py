import torch
from pathlib import Path

# Pfad zu deinem ufen.pt auf dem Host
p = Path("/home/student/Underwater_SLAM/DOCKER/dso_docker/packages/UFEN-SLAM/UFEN_SLAM/ufen.pt")

print("Datei:", p)
print("Existiert:", p.is_file())
print("Größe (Bytes):", p.stat().st_size if p.is_file() else "N/A")

print("\n--- Versuch 1: torch.jit.load (TorchScript) ---")
try:
    m = torch.jit.load(str(p), map_location="cpu")
    print("✅ torch.jit.load erfolgreich.")
    print("Typ:", type(m))
except Exception as e:
    print("❌ torch.jit.load FEHLER:")
    print(repr(e))

print("\n--- Versuch 2: torch.load (normales PyTorch-Objekt) ---")
try:
    obj = torch.load(str(p), map_location="cpu")
    print("✅ torch.load erfolgreich.")
    print("Typ:", type(obj))
    if isinstance(obj, dict):
        print("Dict-Keys (erste 20):", list(obj.keys())[:20])
except Exception as e:
    print("❌ torch.load FEHLER:")
    print(repr(e))
