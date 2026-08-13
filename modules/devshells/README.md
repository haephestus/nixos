# modules/devshells

A **standalone flake** of development shells (not part of the main `/etc/nixos`
flake). Run them with:

```sh
nix develop /etc/nixos/modules/devshells#<name>
```

or via the zsh helper: `dev_env <name>` (see [scripts/](../../scripts/README.md)).

## Available shells

| Shell | File | Stack |
|---|---|---|
| `gcc`, `clang` | `modules/cshells.nix` | C/C++: cmake, boost, gtk3, qt, ncurses, gdb, valgrind, gtest |
| `flutter` | `modules/flutter.nix` | Flutter + Android SDK (platforms 33–36, NDK), GTK/OpenGL/Vulkan desktop deps |
| `mc`, `mc_1_20_1`, `mc_latest`, `java17`, `java21` | `modules/java.nix` | Java / Minecraft modding (Forge/Fabric/NeoForge, LWJGL deps) |
| `del` | `modules/delphi.nix` | Free Pascal Compiler (`fpc`) |
| `pysh`, `pyfl`, `pyml`, `cerebrum` | `modules/python.nix` | Python 3.13: general, Flask, ML, OCR/PDF |
| `steward` | `modules/python.nix` | Steward-Daemon stack (FastAPI/uvicorn; AI deps via venv) |
| `python`, `fastapi`, `insight` | `modules/python.nix` | Python 3.12-era: plain, FastAPI + Postgres, data-science/Jupyter |
| `bun`, `nodejs_22` | `modules/jsshells.nix` | JS: Bun, Node 22 + yarn |

All Python shells (formerly `pyshell.nix`, `python.nix`, `steward.nix`) live in one
module — `modules/python.nix`. The plain `python` shell is defined there but not
exposed as a flake output.

## Status

- `allowUnfree` and Android license acceptance are enabled.
