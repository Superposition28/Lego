# Game Research: LEGO Harry Potter (All Releases & Re-releases)

## 1. Title Scope & Historical Context

*LEGO Harry Potter* covers the complete eight-film adaptation across two primary release cycles and subsequent remastered collections:

1. **LEGO Harry Potter: Years 1–4 (2010):**
   - Covers *Philosopher's Stone*, *Chamber of Secrets*, *Prisoner of Azkaban*, and *Goblet of Fire*.
   - Original platforms: PlayStation 3, Xbox 360, Wii, Microsoft Windows, Mac OS X, Nintendo DS, PlayStation Portable, iOS.
2. **LEGO Harry Potter: Years 5–7 (2011):**
   - Covers *Order of the Phoenix*, *Half-Blood Prince*, and *Deathly Hallows (Parts 1 & 2)*.
   - Original platforms: PlayStation 3, Xbox 360, Wii, Microsoft Windows, Mac OS X, PlayStation Vita, Nintendo 3DS/DS, iOS.
3. **LEGO Harry Potter Collection (2016 / 2018 / 2024 Remaster):**
   - Remastered compilation uniting both games with enhanced graphics, 60 FPS support, updated lighting, and bundled DLC character/spell packs.
   - Initial release: PlayStation 4 (2016), Xbox One & Nintendo Switch (2018).
   - **Current PC Release:** Released for Microsoft Windows on Steam on October 8, 2024 (compiled September 30, 2024), featuring native 64-bit AMD64 executables, launcher integration, and modern Direct3D 11 backend.

---

## 2. Available Target Sources in Workspace

The user workspace contains complete binary dumps for all major target variants:

```text
Games/Lego_Harry_Potter/Source/
├── Orginals/
│   └── PS3/
│       ├── LEGO Harry Potter - Years 1-4 (Europe) (En,Fr,De,Es,It,Da) (v01.02)
│       ├── LEGO Harry Potter - Years 1-4 (Europe) (En,Fr,De,Es,It,Da) (v03.01)
│       └── LEGO Harry Potter - Years 5-7 (Europe) (En,Fr,De,Es,It,Nl,Da)
└── Collection/
    ├── Main/          (Launcher: LHPC.exe, HarryLauncher.exe, launcher.pkdwin)
    ├── Years 1-4/     (Engine: harry1.exe, harry1*.datwin, shaderblob_pc.blob)
    └── Years 5-7/     (Engine: harry2.exe, harry2*.datwin, harry2_shaderblob_pc.blob)
```

---

## 3. Sub-Documents & Research Breakdown

- [**Versions_Comparison.md**](Versions_Comparison.md) — Comprehensive technical cross-comparison matrix evaluating all available PS3 and PC Collection releases, disc mastering variants (`v01.02` vs. `v03.01`), file sizes, and asset distribution differences.
- [**Format_Analysis.md**](Format_Analysis.md) — Reverse-engineered specifications for the `PakDat v1.01` (`.DAT`) format, the modern `datwin` trailing Table of Contents format (delimited by canary `0x12345678`), the `.pkiwin`/`.pkdwin` launcher packages, and shader blobs.
- [**Executables.md**](Executables.md) — Binary-level disassembly analysis, ELF/PE header analysis, entry points, OPD descriptors, TOC base pointers (`r2`), PDB symbol signatures, and CellOS PRX imports.

---

## 4. Reverse Engineering Assistant (REA) Workspace

The executable analysis workstation mirroring the parent engine's reference architecture is situated at:
[`Games/Lego_Harry_Potter/Source/Orginals/PS3/REA/`](../../../../Games/Lego_Harry_Potter/Source/Orginals/PS3/REA/guide.md)

