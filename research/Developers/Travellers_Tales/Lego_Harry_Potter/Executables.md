# Executable Reversing & Subsystems: LEGO Harry Potter

## 1. Overview of Executable Binaries

The LEGO Harry Potter codebase exists across two radically different processor architectures:
1. **Sony PlayStation 3 (CellOS):** Big-Endian 64-bit PowerPC (Cell Broadband Engine PPU) binaries contained in signed SELF wrappers (`EBOOT.BIN`).
2. **Microsoft Windows (Steam):** Little-Endian 64-bit AMD64 (x86-64) Portable Executables (`harry1.exe`, `harry2.exe`, `HarryLauncher.exe`, `LHPC.exe`).

---

## 2. PlayStation 3 PPU Executable Analysis (`EBOOT.BIN`)

Both retail PS3 executables are standalone PPU executables with ELF headers situated at offset `0x90`:

### 2.1 LEGO Harry Potter: Years 1-4 (BLES-00720)
- **File Length:** 10,223,392 bytes
- **SHA-256 Digest:** `CF0EB6DCEA11C4D328F681B6DB9D3BF2014D6B4DDD18ABFB1F953B49BB94968D`
- **Target Architecture:** `PowerPC:BE:64:default` (`e_machine = 0x0015`)
- **Official Procedure Descriptor (OPD) Entry:** `0x0000000000942F58`
- **Program Segments:**
  - `PH[0]` (RX Code): Virtual Memory `0x00010000` – `0x00922560` (FileSz: `0x00912560`, MemSz: `0x00912560`, Flags: `0x400005`)
  - `PH[1]` (RW Data): Virtual Memory `0x00930000` (FileSz: `0x0009CB48`, MemSz: `0x00322098`, Flags: `0x600006`)
  - `PH[5]` (Process Parameters): Virtual Memory `0x009547C8` (Type `0x7`, SDK version: `0x03300000`)
  - `PH[6]` / `PH[7]` (PRX Library Stubs): Virtual Memory `0x00922500` and `0x00922520`

### 2.2 LEGO Harry Potter: Years 5-7 (BLES-01348)
- **File Length:** 13,621,064 bytes
- **SHA-256 Digest:** `91E02125858B1D52E0BC02C2C8592E0879A14AB5974349CCDDDD921939CF1A86`
- **Target Architecture:** `PowerPC:BE:64:default` (`e_machine = 0x0015`)
- **Official Procedure Descriptor (OPD) Entry:** `0x0000000000B80EB0`
- **Program Segments:**
  - `PH[0]` (RX Code): Virtual Memory `0x00010000` – `0x00B77E68` (FileSz: `0x00B67E68`, MemSz: `0x00B67E68`, Flags: `0x400005`)
  - `PH[1]` (RW Data): Virtual Memory `0x00B80000` (FileSz: `0x0018A1A0`, MemSz: `0x005B2598`, Flags: `0x600006`)
  - `PH[5]` (Process Parameters): Virtual Memory `0x00BA3410` (Type `0x7`, SDK version: `0x03730000`)
  - `PH[6]` / `PH[7]` (PRX Library Stubs): Virtual Memory `0x00B77E00` and `0x00B77E28`

### 2.3 PRX Subsystem Imports (NID Stubs)
Both PS3 executables interact with the operating system through Sony PRX import stubs:
- `sys_fs`: File operations (`cellFsOpen`, `cellFsRead`, `cellFsLseek`, `cellFsClose`) targeting `GAME*.DAT`.
- `cellGcmSys`: RSX 3D graphics hardware configuration, context initialization, flip queue management.
- `cellAudio` / `cellAdec`: Hardware audio pipeline.
- `cellSysmodule`: Runtime library loading.
- `cellPad`: DualShock controller input handling.
- `cellSync`: PPU/SPU synchronization primitives.

### 2.4 Xbox 360 Xenon Executables (`Default.xex` — Retail & Kiosk Demo)

Unpacked and audited using `XexTool v7.0` (`XexTool.exe -l -u -o Default_unpacked.xex -d . -i Default.idc Default.xex`, with raw PE images extracted to `Default.pe`):

| Property | Years 1-4 Retail (`Default.xex`) | Years 5-7 Retail (`Default.xex`) | Years 1-4 Kiosk Demo (`Default.xex`) |
| :--- | :--- | :--- | :--- |
| **Original PE Name** | `legogame_Final_360.exe` | `harry2.master.pe` | `legogame_Final_360.exe` (Demo) |
| **Title ID** | `0x575207E6` (`WR-2022`) | `0x57520812` (`WR-2066`) | `0x575287FF` (`WR-34815`) |
| **Media ID** | `0x3E371834` | `0x61D8E1DE` | `0x05E535C2` |
| **Version / Base** | `v0.0.0.2` / `v0.0.0.1` | `v0.0.0.5` / `v0.0.0.1` | `v0.0.0.1` |
| **File Size (`.xex` / `.pe`)** | `6,963,200` B / `19,922,944` B (`Default.pe`) | `5,189,632` B / `10,354,688` B (`Default.pe`) | `6,582,272` B (`PIRS` offset `0x3EBBA000`) |
| **Load Address** | `0x82000000` | `0x82000000` | `0x82000000` |
| **Entry Point** | `0x828A0E90` | `0x82978000` | — |
| **Image Size / Stack** | `0x01820000` (`25.3 MB`) / `0x40000` | `0x00D10000` (`13.7 MB`) / `0x10000` | — |
| **Compilation Timestamp** | `0x4BFF9AEE` (`Fri May 28 20:29:02 2010`) | `0x4EA5CC1A` (`Tue Oct 25 07:35:38 2011`) | `2010-05` |
| **XDK Library Version** | `v2.0.9328.0` (Min Kernel `v2.0.8955.0`) | `v2.0.20871.0` (Min Kernel `v2.0.13599.0`) | `v2.0.9328.0` |
| **Memory Map** | Hdr/Res `0x82000000..0x821A0000`, Code `0x821A0000..0x832C0000`, Data `0x832C0000..0x83590000`, Res `0x83590000..0x83790000`, Data `0x83790000..0x83820000` | Hdr/Res `0x82000000..0x821D0000`, Code `0x821D0000..0x829E0000`, Data `0x829E0000..0x82D10000` | Xenon PPC64 Big-Endian |
| **Static XDK Libraries** | `XGRAPHC`, `XAUDIO2`, `XMCORE`, `D3D9`, `D3DX9`, `XAPILIB`, `XBOXKRNL`, `XNET`, `XONLINE` | `XGRAPHC`, `XAUDIO2`, `XMCORE`, `D3D9`, `D3DX9`, `XAPILIB`, `XBOXKRNL`, `XNET`, `XONLINE` | Same |

---

## 3. PC Collection Executable Analysis (AMD64 PE32+)

### 3.1 Compiler Toolchain & Internal PDB Signatures
All executables in the 2024 Collection remaster were compiled using Microsoft Visual Studio 2019 on an automated Continuous Integration build agent:

| Executable | Internal PDB Path | Build Target Profile | Compilation Time |
| :--- | :--- | :--- | :--- |
| `harry1.exe` | `\BuildAgent\work\a6d6b8eb0767cd34\Build_vs2019\x64FinalD11Static\harry1.pdb` | `x64FinalD11Static` | 2024-09-30 13:36:50 UTC |
| `harry2.exe` | `\BuildAgent\work\bc0dd4a19c0e4a29\Build_vs2019\x64FinalD11Static\harry2.pdb` | `x64FinalD11Static` | 2024-09-30 12:48:59 UTC |
| `LHPC.exe` | `\BuildAgent\work\348e7e39a54c85df\Build_vs2019\x64FinalD11\LHPC.pdb` | `x64FinalD11` | 2024-09-30 14:18:16 UTC |
| `HarryLauncher.exe` | *(Embedded resource)* | `x64FinalD11` | 2024-09-30 14:17:03 UTC |

### 3.2 Key Reversing Insights from the PDB Paths
- **`x64FinalD11Static`:**
  - Indicates that the Direct3D 11 graphics abstraction layer was statically compiled into the executable image rather than residing in an external DLL.
  - "Final" signifies a non-debug, ship-optimized configuration with full compiler vectorization (SSE4.2/AVX) and stripped internal assertions.
- **Embedded Libraries:**
  - **LZHAM Decompressor** (`E:\BuildAgent\work\a6d6b8eb0767cd34\d11-engine\Inc\lzham\lzhamdecomp\`, used for `.datwin` `CompressionType == 4` streams).
  - **Zlib 1.2.3** (`inflateInit_` / `inflate`, used for `CompressionType == 3` streams).
  - **TT Games LZ2K Decompressor** (`VA 0x1404D4A50`, used for `PakDat v1.01` `CompressionType == 2` streams).
  - FMOD Core & Studio Sound Engine (replaces the PS3 `cellAudio` hardware drivers).
  - RAD Game Tools Bink 2 Video.
  - Microsoft DirectX Shader Compiler runtime (`dxcompiler.dll`) & AMD FidelityFX OpticalFlow (`ffxOpticalflowResourceIsNull`).
  - Valve Steamworks API integration (`steam_api64.dll`).

### 3.3 `harry1.exe` PE32+ Sections & Decompiled Function Landmarks (`ImageBase = 0x140000000`)

#### PE Section Table
| Section | Virtual RVA Range | Raw File Offset Range | Formula (`FileOffset -> VA`) |
| :--- | :--- | :--- | :--- |
| `.text` | `0x00001000 .. 0x0060F1AF` | `0x00000400 .. 0x0060E600` | `VA = FileOffset + 0x140000C00` |
| `.rdata` | `0x00610000 .. 0x0104AA14` | `0x0060E600 .. 0x01049200` | `VA = FileOffset + 0x140001A00` |
| `.data` | `0x0104B000 .. 0x0171CD78` | `0x01049200 .. 0x01415200` | `VA = FileOffset + 0x140001E00` |

#### Decompiled Archive & Compression Functions in `harry1.exe`
| Virtual Address (`VA`) | File Offset | Symbol / Function Role | Verified Behavior |
| :--- | :--- | :--- | :--- |
| `0x140208320` | `0x0207720` | `TtPathHash_Dual` | Computes `h = (h ^ toupper(c)) * 0x00199933` from seed `0x811C9DC5` (`/` -> `\`). |
| `0x1404D49B0` | `0x04D3DB0` | `LZ2K_DecompressStream` | Iterates `12`-byte `"LZ2K"` chunk headers and dispatches `LZ2K_Decompress`. |
| `0x1404D4A50` | `0x04D3E50` | `LZ2K_Decompress` | Decompresses a single `LZ2K` chunk (`<= 0x8000` B) via `0x2000` B sub-blocks (`0x140568A40`). |
| `0x1404D4BB0` | `0x04D3FB0` | `LZ2K_ParseChunkHeader` | Validates `"LZ2K"` magic (`RVA 0x93729C`) and reads `UncompSize` (`+4`) / `CompSize` (`+8`). |
| `0x1404D4F80` | `0x04D4380` | `PakArchive::FindFileByPath` | Hashes path (`0x811C9DC5` / `0x00199933`), binary-searches `PathHashes[N]`, falls back to `NameTree`. |
| `0x1404D5D30` | `0x04D5130` | `PakArchive::LoadToc` | Parses legacy `PakDat` TOC (`Entries[N]`, `NameNodes[M]`, `StringTable`, `PathHashes[N]`). |
| `0x14052D1C0` | `0x052C5C0` | `NuFileDeviceDat::OpenStream` | Reads 24-byte `DatwinFileEntry`, shifts `Offset << 8` if `Version <= -2`, creates `NuFileStreamDat`. |
| `0x14052D540` | `0x052C940` | `NuFileDeviceDat::MountArchives` | Mounts `HARRY1.DAT`, `HARRY1B.DAT`, `HARRY1P.DAT` (appending `"WIN"` at `RVA 0x937474`). |
| `0x14052E030` | `0x052D430` | `NuFileDeviceDat::LoadDatToc` | Reads 16-byte header (`if (TocOffset < 0) TocOffset = (-TocOffset) << 8`), `Entries[N]`, `PathHashes[N]`. |
| `0x1405367A0` | `0x0535BA0` | `NuFileStreamDat::Read` | Dispatches `CompressionType` (`0` = Raw, `2` = LZ2K, `3` = Zlib 1.2.3, `4` = LZHAM). |
| `0x1405B4380` | `0x05B3780` | `ZLibDecompress_Buffer` | Inflates `CompressionType == 3` streams via `zlib 1.2.3`. |
| `0x1405B47B0` | `0x05B3BB0` | `LzhamDecompress_Buffer` | Decompresses `CompressionType == 4` (`0E C6`) streams (`DictSizeLog2=15`, `Flags=5`). |
| `0x1405D93F0` | `0x05D87F0` | `lzham_decompress` | Thunk to `VA 0x1405E83F0` (`lzham::lzham_lib_decompress`). |
| `0x1405D9400` | `0x05D8800` | `lzham_decompress_deinit` | Thunk to `VA 0x1405E84B0` (`lzham::lzham_lib_decompress_deinit`, returns Adler32). |
| `0x1405D9410` | `0x05D8810` | `lzham_decompress_init` | Thunk to `VA 0x1405E8510` (`lzham::lzham_lib_decompress_init`). |
| `0x1405D9420` | `0x05D8820` | `lzham_set_memory_callbacks` | Thunk to `VA 0x1405D96F0`. |

---

## 4. Cross-Architecture Reversing Strategy

The presence of the native x64 Windows executables alongside the 64-bit PowerPC PS3 binaries provides a massive reverse-engineering advantage:
1. **Decompilation Clarity:**
   Ghidra's x86-64 decompiler output on `harry1.exe` and `harry2.exe` avoids PowerPC TOC-relative pointer indirection (`r2`) and OPD function descriptors, providing clean, readable C pseudocode.
2. **Correlating Function Boundaries:**
   TT Games retained identical function signatures and class hierarchies between the console and PC versions. Identifying an archive loader or hash routine in `harry1.exe` directly reveals its counterpart in PS3 `EBOOT.BIN`.
3. **Data Structure Layouts:**
   Class field alignments and struct member offsets can be cross-verified by comparing the 64-bit AMD64 binary layouts against the 64-bit PowerPC layouts.

