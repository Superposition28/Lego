# LEGO Games: Extraction, Research, and Reverse Engineering

This project brings together tools, research, format specifications, and reverse-engineering environments for LEGO games within the [RemakeEngine](https://github.com/yggdrasil-au/RemakeEngine) ecosystem. For now, its purpose is extraction, research, and reverse engineering

---

## Project Organization

The project is architected around two core organizational principles:
1. **Shared vs. Game-Specific Division:**
   - The parent module (`A:\RemakeEngine\Main\EngineApps\Games\Lego`) holds shared documentation, developer history, toolchain configurations, and shared operations.
   - Individual game modules are nested under `Games/` (e.g., `Games/Lego_Harry_Potter`), containing game-specific source dumps, reverse-engineering workstations (REA), and extraction manifests.
2. **Developer-First Documentation Hierarchy:**
   - Documentation in [`research/Developers/`](research/Developers/) is organized first by **Game Developer**, then sub-organized by **Specific Game Title** (grouping all re-releases, ports, and remasters together under that title).

---

## Research Documentation Directory

### [Traveller's Tales (TT Games)](research/Developers/Travellers_Tales/README.md)
The primary focus of this project, covering the history, NuP/TT Engine evolution (Gen 1 through modern NTT/Collection remasters), and individual title research:
- [**LEGO Harry Potter**](research/Developers/Travellers_Tales/Lego_Harry_Potter/README.md) — *Years 1–4* (2010), *Years 5–7* (2011), and the *2024 Collection Remaster*.
  - [**Versions Comparison**](research/Developers/Travellers_Tales/Lego_Harry_Potter/Versions_Comparison.md) — Comprehensive technical cross-comparison across PS3 discs (`v01.02` vs `v03.01`), Years 5-7, and Steam PC Collection.
  - [**Format Analysis**](research/Developers/Travellers_Tales/Lego_Harry_Potter/Format_Analysis.md) — Reverse engineering of `PakDat v1.01`, the modern `datwin` trailing TOC format (delimited by canary `0x12345678`), launcher packages (`.pkiwin`/`.pkdwin`), and Direct3D shader blobs.
  - [**Executables & Subsystems**](research/Developers/Travellers_Tales/Lego_Harry_Potter/Executables.md) — Disassembly analysis of Cell PPU 64-bit PowerPC `EBOOT.BIN` and AMD64 `harry1.exe` / `harry2.exe`.
- [**LEGO Star Wars**](research/Developers/Travellers_Tales/Lego_Star_Wars/README.md) — *The Video Game*, *Original Trilogy*, *The Complete Saga*, *The Clone Wars*, *The Force Awakens*, and *The Skywalker Saga*.
- [**LEGO Batman**](research/Developers/Travellers_Tales/Lego_Batman/README.md) — *LEGO Batman 1*, *LEGO Batman 2: DC Super Heroes*, *LEGO Batman 3: Beyond Gotham*, and *LEGO DC Super-Villains*.
- [**LEGO Indiana Jones**](research/Developers/Travellers_Tales/Lego_Indiana_Jones/README.md) — *The Original Adventures* and *The Adventure Continues*.
- [**LEGO The Lord of the Rings & The Hobbit**](research/Developers/Travellers_Tales/Lego_The_Lord_of_the_Rings/README.md) — Middle-earth overland streaming, Mithril crafting, and film audio systems.
- [**LEGO Marvel**](research/Developers/Travellers_Tales/Lego_Marvel/README.md) — *Marvel Super Heroes*, *Avengers*, and *Marvel Super Heroes 2*.
- [**LEGO Pirates of the Caribbean**](research/Developers/Travellers_Tales/Lego_Pirates_of_the_Caribbean/README.md) — Dynamic ocean fluid rendering, buoyancy physics, and 7th-gen engine transition.

### [Other LEGO Game Developers](research/Developers/Other_Developers/README.md)
Historical and non-TT LEGO titles across diverse genres: Silicon Dreams Studio (*Island 2*, *Island Xtreme Stunts*), Mindscape (*LEGO Island*), High Voltage (*LEGO Racers*), Data Design Interactive (*Rock Raiders*), Visual Concepts / 2K (*LEGO 2K Drive*), ClockStone (*LEGO Bricktales*), and Studio Gobo / Guerrilla Games (*LEGO Horizon Adventures*).

---


## Project Layout

- `Games/` — Individual game work, organized into nested game title folders.
- `research/` — Research notes organized by Developer $\rightarrow$ Game Title.
- `operations/` — Shared engine operation scripts as they are developed.
- `operations.toml` — Shared operation definitions.
- `Tools.toml` — External tool declarations (Blender, QuickBMS, vgmstream, FFmpeg, ImageMagick).
- [TODO.md](TODO.md) — Project and engine roadmap (including planned engine support for nested game modules).
- [AGENTS.md](AGENTS.md), [Style.md](Style.md), and [cli.md](cli.md) — Contributor and agent instructions.
