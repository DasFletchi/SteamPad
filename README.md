<p align="center">
  <img src="assets/banner.png" alt="SteamPad Banner" width="100%"/>
</p>

<h1 align="center">🎮 SteamPad</h1>

<p align="center">
  <strong>Play your Steam library natively on iPad — no streaming, no emulation.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iPadOS_17+-blue?style=flat-square&logo=apple" alt="Platform"/>
  <img src="https://img.shields.io/badge/Architecture-ARM64-green?style=flat-square" alt="Arch"/>
  <img src="https://img.shields.io/badge/Graphics-Metal_3-orange?style=flat-square&logo=apple" alt="Graphics"/>
  <img src="https://img.shields.io/badge/License-GPL_3.0-purple?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/Sideload-AltStore-red?style=flat-square" alt="Sideload"/>
</p>

<p align="center">
  <em>A pure translation layer that converts Windows PC games to run natively on Apple Silicon iPads.<br/>Inspired by <a href="https://github.com/nicemicro/GameNative">GameNative</a> and <a href="https://gamehub-lite.com">GameHub Lite</a>'s approach — adapted for iPadOS.</em>
</p>

---

## ⚡ How It Works

SteamPad uses **zero emulation**. Every layer is a direct translation:

```
┌─────────────────────────────────────────────────────────┐
│                     YOUR PC GAME                        │
│                    (x86 Windows .exe)                    │
└──────────────────────┬──────────────────────────────────┘
                       │
          ┌────────────▼────────────┐
          │    AOT COMPILER         │  Install-time static translation
          │    x86 → ARM64          │  PE → Mach-O .dylib
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │   NATIVE ARM64 BINARY   │  Runs directly on iPad CPU
          └────────────┬────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
   ┌────▼────┐   ┌─────▼─────┐  ┌────▼─────┐
   │  WINE   │   │   DXVK    │  │  XINPUT  │
   │ Darwin  │   │ D3D → VK  │  │ Gamepad  │
   └────┬────┘   └─────┬─────┘  └──────────┘
        │              │
   POSIX/Darwin   ┌────▼─────┐
   API calls      │ MoltenVK │
                  │ VK → MTL │
                  └────┬─────┘
                       │
              ┌────────▼────────┐
              │   Apple Metal   │
              │   iPad GPU      │
              └─────────────────┘
```

| Layer | What It Does | Technology |
|-------|-------------|------------|
| **Binary Translation** | Converts x86/x64 → ARM64 at install time | AOT Static Compiler (FEX-inspired) |
| **API Translation** | Windows API → Darwin/POSIX | Wine (single-process, threaded) |
| **Graphics Translation** | Direct3D 9/11 → Vulkan → Metal | DXVK + MoltenVK |
| **Input Translation** | MFi / Xbox / DualSense → XInput | Apple GameController Framework |

---

## 🖥️ SteamOS-Inspired Interface

The launcher UI is designed to feel like the **Steam Deck's Big Picture Mode** — dark, immersive, and fully controller-navigable.

- 🎬 **Hero Carousel** — Featured games with gradient cover art and instant Play buttons
- 📚 **Library Sidebar** — Searchable game list with filter pills (All / Translated / Installed)
- 📊 **Detail Pane** — Game info, translation status, Install / Translate / Play actions
- ⬇️ **Downloads Tab** — Real-time progress for Steam depot downloads and AOT translations
- ⚙️ **Settings** — DXVK toggle, FSync, memory limiter, Wine debug levels
- 🎮 **In-Game Overlay** — FPS counter, quick settings, virtual gamepad for touch

---

## 📁 Project Structure

```
SteamPad/
├── App/
│   ├── SteamPadApp.swift              # @main entry, environment wiring
│   └── RootView.swift                 # SteamOS nav bar + tab routing
│
├── UI/
│   ├── SteamOS/
│   │   ├── HomeView.swift             # Hero carousel, game rows
│   │   ├── LibraryGridView.swift      # Sidebar list, search, detail pane
│   │   ├── DownloadsView.swift        # Download + translation progress
│   │   └── SettingsView.swift         # Engine config, system info
│   └── Overlay/
│       └── InGameOverlayView.swift    # Metal surface, FPS, virtual gamepad
│
├── Models/
│   └── GameEntry.swift                # Game model, TranslationStatus enum
│
├── SteamSync/
│   └── SteamLibraryManager.swift      # Steam Web API auth + library sync
│
├── TranslationLayer/
│   ├── AOTCompiler.swift              # PE → x86 disasm → ARM64 → Mach-O
│   ├── WineDarwin.swift               # Single-process Wine, API table
│   └── TranslationEngineManager.swift # Pipeline orchestrator
│
├── GraphicsTranslation/
│   └── MoltenMetalInterop.swift       # Metal init, MoltenVK, DXVK loader
│
├── GameContainers/
│   └── SandboxDrive.swift             # Per-game WINEPREFIX in iOS sandbox
│
├── ControllerInput/
│   └── ControllerInputManager.swift   # GameController → XInput mapping
│
├── Assets.xcassets/
├── Info.plist                         # iPad, landscape, Metal, controllers
└── SteamPad.entitlements              # Sandbox + network
```

---

## 🧠 Key Design Decisions

### Why AOT Instead of JIT?

Apple blocks `mmap(RWX)` on sideloaded apps — meaning runtime JIT compilation (used by Box64, FEX, etc.) is impossible without a jailbreak. SteamPad solves this by doing **all binary translation at install time**:

```
Download game → Parse PE → Disassemble x86 → Translate to ARM64 → Link as .dylib → Done.
```

The resulting `.dylib` contains pure ARM64 machine code. To the iOS kernel, it's indistinguishable from any native library.

### Why Single-Process Wine?

Standard Wine spawns `wineserver` as a child process via `fork()`. iPadOS prohibits this. SteamPad restructures Wine to run **entirely within one process** — `wineserver` becomes a background thread communicating via shared memory instead of Unix sockets.

### Why DXVK + MoltenVK?

This is the same proven stack used by **CrossOver**, **Whisky**, and Apple's own **Game Porting Toolkit** on macOS. Direct3D → Vulkan → Metal is battle-tested.

---

## 🚀 Getting Started

### Requirements

- macOS with Xcode 15+
- iPad with Apple Silicon (A12+) running iPadOS 17+
- [AltStore](https://altstore.io) or [SideStore](https://sidestore.io) for sideloading

### Build

```bash
# Clone
git clone https://github.com/your-username/SteamPad.git
cd SteamPad

# Open in Xcode
open SteamPad.xcodeproj

# Select your iPad as target → Build & Run
# Or archive → Export IPA → Sideload via AltStore
```

---

## ⚠️ Current Status

> **This is an architectural prototype.** The UI, data models, and pipeline orchestration are fully implemented in Swift. The following components require native C/C++ open-source libraries to be cross-compiled for ARM64 Darwin and bundled as `.dylib` frameworks:

| Component | Status | What's Needed |
|-----------|--------|---------------|
| SwiftUI Launcher | ✅ Complete | — |
| Steam Library Sync | 🟡 Stubbed | Integrate SteamKit / DepotDownloader |
| AOT Compiler | 🟡 Structure only | Integrate Capstone (disasm) + custom ARM64 codegen |
| Wine Darwin | 🟡 Orchestrator only | Cross-compile Wine for ARM64 Darwin (single-process patch) |
| DXVK | 🟡 Loader only | Cross-compile DXVK as ARM64 `.dylib` |
| MoltenVK | 🟡 Loader only | Bundle [MoltenVK](https://github.com/KhronosGroup/MoltenVK) |
| Controller Input | ✅ Complete | — |
| Sandbox Manager | ✅ Complete | — |

---

## 🔮 Roadmap

- [ ] Cross-compile Wine 9.0 for ARM64 Darwin (single-process fork)
- [ ] Integrate MoltenVK framework
- [ ] Build AOT compiler using Capstone + custom ARM64 backend
- [ ] Cross-compile DXVK for ARM64
- [ ] Implement Steam depot downloader
- [ ] Add cloud save sync
- [ ] Hybrid mode: local translation for light games + Moonlight streaming for AAA
- [ ] Plugin system for community-contributed game patches
- [ ] Apple Game Porting Toolkit (D3DMetal) integration if it comes to iPadOS

---

## 📜 License

GPL 3.0 — Built on the shoulders of open-source giants:
[Wine](https://www.winehq.org/) · [DXVK](https://github.com/doitsujin/dxvk) · [MoltenVK](https://github.com/KhronosGroup/MoltenVK) · [FEX](https://github.com/FEX-Emu/FEX) · [GameNative](https://github.com/nicemicro/GameNative)

---

<p align="center">
  <sub>love y'all</sub>
</p>
