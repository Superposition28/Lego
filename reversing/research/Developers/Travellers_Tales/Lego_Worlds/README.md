# Game Research: LEGO Worlds (TT Games)

## 1. Title Overview
*LEGO Worlds* (Early Access 2015, Full Release March 2017) is TT Games' procedural voxel and brick-by-brick sandbox game built on the **Era 4b (`TFA` DX11)** variant of the Next-Gen TT Engine.

---

## 2. Engine & Format Architecture
- **Platforms:** Microsoft Windows (Steam 64-bit DX11), PlayStation 4, Xbox One, Nintendo Switch.
- **Archive Format (`.DAT` / `.HDR`):**
  - Uses the big-endian **`.CC40TAD` (`4CC.DAT0`)** TOC format (`Version = -8` / `-10` / `-11`) with chunked `DFLT` / `ZIPX` compression.
- **Core Formats:**
  - **`.lxfml` / `.gsc` / `_dx11.ghg`:** Supports LEGO Digital Designer (`.lxfml`) brick assemblies alongside compiled `_dx11.gsc` / `_dx11.ghg` (`MESH` v`0xA9`–`0xAF`) meshes and `.tsh` (`NuTextureSheet` v4/v5) icon sheets.
  - **Procedural Voxel & Biome Descriptors:** Uses `.led` / `.cd` (`EdFile` `StreamInfo`) and biome/terrain generation tables to stream voxel chunks and place prefab LEGO brick structures at runtime.

> **Status Note:** The local `Games/Lego_Worlds/Source/` directory does not yet contain retail archive dumps; format specifications in this module reflect verified Era 4b TT Engine documentation and cross-title `.lxfml`/`.tsh` evidence observed in *LEGO Dimensions*.
