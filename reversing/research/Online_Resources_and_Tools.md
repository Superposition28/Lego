# Online Resources, QuickBMS Scripts & Open-Source Tools for TT Games LEGO Reverse Engineering

This document catalogs online documentation portals, QuickBMS extraction scripts, open-source repositories, Blender plugins, decompilations, and hardware protocol libraries relevant to reverse engineering Traveller's Tales (TT Games / TT Fusion) LEGO games and integrating their formats into RemakeEngine.

---

## 1. Local Clones in This Workspace

The following external resources have already been cloned into [`EngineApps/Games/Lego/reversing/`](file:///a:/RemakeEngine/Main/EngineApps/Games/Lego/reversing):

| Local Path | Upstream Source | License | Description |
| :--- | :--- | :--- | :--- |
| [`reversing/ExternalTools/TTGames-Explorer-Rebirth`](file:///a:/RemakeEngine/Main/EngineApps/Games/Lego/reversing/ExternalTools/TTGames-Explorer-Rebirth) | https://github.com/AcK77/TTGames-Explorer-Rebirth | MIT | C# (`.NET`) library, CLI, WinForms UI, DirectX shader decompiler, and runtime hook for TT Games archives (`.dat`, `.pak`, `.pac`, `.fpk`, `.pkiwin`/`.pkdwin`, `.fib`) and inner formats (`.ghg`/`.gsc` `NuCore`, `.nxg_textures`, `.tsh`, `.ft2`, `.an3`, `.cbx`, `.dno` `PinnerDynamicsObj`, `EdFile` `StreamInfo`, `.pc_shaders`, `.blob`, `LZ2K`, `RefPack`, `GCBF` LZ4, `ZIPX` RC4). |
| [`reversing/TTModding-Docs`](file:///a:/RemakeEngine/Main/EngineApps/Games/Lego/reversing/TTModding-Docs) | https://github.com/AcK77/TTModding-Docs (`https://ttmodding.com`) | Open Community Docs | Markdown (`mdBook`) source for `ttmodding.com`, including engine taxonomy ([`src/engine.md`](file:///a:/RemakeEngine/Main/EngineApps/Games/Lego/reversing/TTModding-Docs/src/engine.md)), game pages ([`src/games/`](file:///a:/RemakeEngine/Main/EngineApps/Games/Lego/reversing/TTModding-Docs/src/games)), format specs ([`cbx.md`](file:///a:/RemakeEngine/Main/EngineApps/Games/Lego/reversing/TTModding-Docs/src/fileformats/cbx.md), [`giz.md`](file:///a:/RemakeEngine/Main/EngineApps/Games/Lego/reversing/TTModding-Docs/src/fileformats/giz.md), [`tsh.md`](file:///a:/RemakeEngine/Main/EngineApps/Games/Lego/reversing/TTModding-Docs/src/fileformats/tsh.md)), and tool guides. |

---

## 2. QuickBMS (`aluigi.altervista.org`) Scripts for TT Games & LEGO Titles

Index page: https://aluigi.altervista.org/quickbms.htm (script lists served from `https://aluigi.altervista.org/quickbms_list.php` and `https://aluigi.altervista.org/quickbms_list.php?folder=xentax_cs`).

### 2.1 Traveller's Tales & TT Fusion Scripts

| Script | Direct URL | Target Games & Formats | Technical Parsing & Compression Summary |
| :--- | :--- | :--- | :--- |
| **`ttgames.bms`** (v0.9.11a) | https://aluigi.altervista.org/bms/ttgames.bms | Universal TT Games `.DAT` / `.HDR` archives (`TOC v-1` through `v-11` `.CC40TAD`), standalone compressed streams, and `0x1234567a` `.pak` (`alltxt.pak`) | **1.** Detects `0x1234567a` `.pak` containers (`28B` entries + optional `"Deflate_v1.0"` payload compression).<br>**2.** Detects outer `"CMP2CMP2CMP2CMP2"` + 16B hash + `uint64` size wrapper and decompresses via `comtype lzma` before parsing TOC.<br>**3.** Checks for companion `.hdr` file before falling back to `.dat` header (`INFO_OFF`, `INFO_SIZE`).<br>**4.** Parses both `.CC40TAD` (`TYPE_BOH <= -8`, `NEW_FORMAT_VER 1/2`, 32-bit or 64-bit FNV-1) and classic TOC (`v-1`..`v-9`, 8B or 12B `NameNodes` for `v <= -5`).<br>**5.** Decompresses chunked streams (`LZ2K`, `DFLT`, `ZLIB`, `LZMA`, `RFPK`, `ZIPX` with 4-byte RC4 header decryption keyed by decimal `CHUNK_ZSIZE`, and unchunked `RNC_`). |
| **`gsc_nu20.bms`** (v0.1) | https://aluigi.altervista.org/bms/gsc_nu20.bms | Early TT Games `.GSC` (`NU20`) scene containers | Checks for direct `"NU20"` magic (`MODE = 0`) or pre-header skip (`MODE = 1`). Reads `INFO_SIZE`, `VER`, `DUMMY`, and iterates `NTBL` (string table) and `TST0` (texture headers) to extract embedded texture payloads starting at `DATA_OFF`. |
| **`bionicle.bms`** | https://aluigi.altervista.org/bms/bionicle.bms | *Bionicle Heroes* (2006) `.DAT` archives | Reads `[TABLE_OFF u32, TABLE_SIZE u32]`, seeks to `TABLE_OFF`, reads `FILES * 16B` entry records (`OFFSET, ZSIZE, SIZE, ZIP`) and `FILES * 8B` name records (`NAME_OFF u32, FILE_NUM u16, DIR_NUM u16`). |
| **`crash_bandicoot_ttgames.bms`** (v0.2) | https://aluigi.altervista.org/bms/crash_bandicoot_ttgames.bms | Early Nu2 TT Games (*Crash Wrath of Cortex*, *Crash Twinsanity*) `.BH`/`.BD`, `.MH`/`.MB`, `.DAT` | Extracts companion header/data `.BH`/`.BD` and `.MH`/`.MB` pairs, `RNC` (`SCUMMVM7` / `rnc2`) streams, and early `.DAT` TOCs. |
| **`crash_woc_dat.bms`** (v0.1) | https://aluigi.altervista.org/bms/crash_woc_dat.bms | *Crash Bandicoot: The Wrath of Cortex* `.DAT` | Parses early Struct-of-Arrays (SoA) `.DAT` TOC (`NAME_OFF[FILES]`, `OFFSET[FILES]`, `SIZE[FILES]`, `NAMES_SIZE`, string pool). |
| **`finding_nemo.bms`** (v0.1) | https://aluigi.altervista.org/bms/finding_nemo.bms | *Finding Nemo* (2003, Nu2 Engine) `.DAT` | Parses TOC `SIGN == -1` with `FILES * 16B` entries and `NAMES * 8B` (`NAME_OFF u32, PREV_ID s16, FILE_ID s16`). |
| **`fuse_fib.bms`** (v0.1.4) | https://aluigi.altervista.org/bms/fuse_fib.bms | TT Fusion handheld `.FIB` archives (DS / 3DS / Vita LEGO games) | Verifies `"FUSE1.00"` magic, reads `[FILES u32, ZERO u32, INFO_OFF u32, CRC u32]`, and iterates 12-byte TOC entries (`CRC u32, OFFSET u32, SIZE_AND_FLAGS u32`). Decompresses `0x40000000` entries with `comtype rfpk` (EA RefPack). |
| **`lego_alltxt.bms`** | https://aluigi.altervista.org/bms/lego_alltxt.bms | `alltxt.pak` / `.pak` containers | Extracts 28-byte entry table from `0x1234567a` `.pak` containers. |
| **`lego_starwars_nds.bms`** | https://aluigi.altervista.org/bms/lego_starwars_nds.bms | *LEGO Star Wars* (Nintendo DS) `.bin` & `.bfm_multi` | Extracts offset-table `.bin` (`FILES = FIRST_OFFSET / 4`) and `.bfm_multi` multi-file containers. |

### 2.2 Other Historical LEGO Game Scripts on QuickBMS

| Script | Direct URL | Target Game & Format |
| :--- | :--- | :--- |
| **`lego_universe.bms`** (v0.3.2) | https://aluigi.altervista.org/bms/lego_universe.bms | *LEGO Universe* `.pki` / `.pk` / `trunk.txt` / `sd0` chunked zlib packages (ancestor of Double Eleven's `.pkiwin`/`.pkdwin` format). |
| **`lego_chess.bms`** & **`lego_chess_z.bms`** | https://aluigi.altervista.org/bms/lego_chess.bms | *LEGO Chess* archives & PKWare DCL (`explode`) `main.z`. |
| **`lego_creator.bms`** | https://aluigi.altervista.org/bms/lego_creator.bms | *LEGO Creator: Knights Kingdom* `DPAK` archive. |
| **`lego_island_wdb.bms`** | https://aluigi.altervista.org/bms/lego_island_wdb.bms | *LEGO Island* `WORLD.WDB` bitmap extractor. |
| **`legoland.bms`** | https://aluigi.altervista.org/bms/legoland.bms | *LEGOLAND* archive extractor. |
| **`legoracer_jam.bms`** | https://aluigi.altervista.org/bms/legoracer_jam.bms | *LEGO Racers* `LJAM` (`.JAM`) archive extractor. |

---

## 3. Open-Source GitHub Repositories & Community Tools

### 3.1 Archive Explorers, `.DAT` Libraries & Compression Codecs

| Repository / Project | URL | Language | Key Capabilities & Relevance to RemakeEngine |
| :--- | :--- | :--- | :--- |
| **TTGames-Explorer-Rebirth** (`AcK77`) | https://github.com/AcK77/TTGames-Explorer-Rebirth | C# (`.NET`) | Full C# library (`TTGamesExplorerRebirthLib`) for `.DAT` (`v-1`..`v-11`), `.FIB`, `.PAK`, `.PK` (`.pkiwin`/`.pkdwin`), `.GHG`/`.GSC` (`NuCore`), `.NXG_TEXTURES`, `.TSH`, `.FT2`, `.AN3`, `.CBX`, `.DNO` (`PinnerDynamicsObj`), `EdFile` (`StreamInfo`), `.PC_SHADERS`, `.BLOB`, `UnLZ2K`, `UnRefpack`, `GCBF` (LZ4), `ZIPX` (RC4). Cloned locally in `reversing/ExternalTools/TTGames-Explorer-Rebirth`. |
| **EdRegistry** (`AcK77` / `JayFrancoe`) | https://github.com/AcK77/EdRegistry | CSV / JS | Comprehensive registry of `EdFile` (`StreamInfo`) classes, types, and properties across TT Games titles (`data/EdRegistry.csv`). |
| **DATOneArchiver** (`IsaMorphic`) | https://github.com/IsaMorphic/DATOneArchiver | C# | Clean-room `.DAT` extractor and repacker specifically targeting Era 1–2 (*LSW1* and *LSW2*) across PC, PS2, PSP, Xbox, and GameCube, including `RNC` ProPack support. |
| **DATManager / DATExtract / DATPacker** (`connorh315`) | https://github.com/connorh315/DATManager | C# | Archive extraction and repacking utilities for Era 3–4 TT Games `.DAT` files. |
| **DatLibrary** (`ArchLeaders`) | https://github.com/ArchLeaders/DatLibrary | C# | Standalone C# `.DAT` reader library modeled on `ttgames.bms`. |
| **unlz2k** (`pianistrevor`) & **liblz2k** (`LunaticInAHat`) | https://github.com/pianistrevor/unlz2k <br> https://github.com/LunaticInAHat/liblz2k | C++ | Original reverse-engineered C++ implementations of TT Games' `LZ2K` compression algorithm. |
| **TTGamesPatcher** (`AlubJ`) | https://github.com/AlubJ/TTGamesPatcher | C# / Python | Patches Era 4b (`TFA`-variant) game executables so they load unpacked files directly from the filesystem without requiring `.DAT` archives. |

### 3.2 3D Models (`.GHG`, `.GSC`, `.HGP`, `.NUP`), Animations (`.AN3`, `.AN4`, `.CU2`, `.CU3`) & Textures

| Repository / Project | URL | Language | Key Capabilities & Formats Covered |
| :--- | :--- | :--- | :--- |
| **TTGames-Workshop** (`Loomirr`) | https://github.com/Loomirr/TTGames-Workshop | Python / C# | Actively maintained suite of Blender 4.2+/4.4+ extensions and format scripts:<br>• `lsw1_hgp_importer` (*LSW1* `.hgp` models, shaders, morphs, animations)<br>• `io_lsw2_hgp` (*LSW2* `.hgp` importer & exporter)<br>• `TT_Character_Importer` (`io_scene_tt_character`: imports `.cd`, `.ghg`, `.gsc` rigs, facial targets, and animations across *TCS*, *LB1*, *LB2*, *LMSH1*, *LB3*, *Hobbit*, *Avengers*)<br>• `TT_Cutscene_Importer` (`io_scene_lego_cu3`: imports `.cu3` cutscenes and `.an4` animations)<br>• `formats/classic-pc/tools/` (`nu20.py`, `an3.py`, `cu2.py`, `giz.py`) & 3DS `.btga` texture converter. |
| **TTGames-Extraction-Tools** (`AlubJ` / `JayFrancoe` / Sluicer) | https://github.com/AlubJ/TTGames-Extraction-Tools <br> https://github.com/JayFrancoe/TTGames-Extraction-Tools | C# | Decompiled source code of **Sluicer's** three foundational model/scene extractors:<br>• `ExtractPcGHG`: Classic PC (`NU20`) `.ghg` model/skeleton extractor.<br>• `ExtractNxgMESH`: Next-Gen (`_nxg.ghg` / `_nxg.gsc`) extractor covering `DISP15`/`17`/`21`, `HGOL01`/`10`, `IVL501`, `MESH04`/`05`/`2E`/`2F`/`30`/`A9`/`AA`/`AF`, `TXGH01`–`0C`.<br>• `ExtractDx11MESH`: DX11 (`_dx11.ghg` / `_dx11.gsc`) extractor (`MESHC8`). |
| **NuXtractor** (`IsaMorphic`) | https://github.com/IsaMorphic/NuXtractor | C# / Kaitai Struct | Model and texture extractor for *LSW1* containing **Kaitai Struct (`.ksy`)** binary grammar definitions (`csc_gc.ksy`, `gsc_ps2.ksy`, `hgp_v1.ksy`, `nup_v1.ksy`, `nup_v2.ksy`). |
| **BactaTank-Classic** & **NUPv2 / NXG Research** (`AlubJ`) | https://github.com/AlubJ/BactaTank-Classic <br> https://github.com/AlubJ/NUPv2-Model-Loader <br> https://github.com/AlubJ/lego-tt-nxg-formats | C# / Python | Classic era character editor, Blender plugin (`BactaTank-Classic-Blender-Plugin`), NUPv2 model loader, and NXG format notes. |
| **EasyAN3** (`Clarence-Oveur`) | https://github.com/Clarence-Oveur/EasyAN3 | Python | Bidirectional `.AN3` (`4INA`, `6INA`, `8INA`) <-> `.JSON` converter supporting skeletal, facial, and camera animations, `.GHG` bone name binding, and `.CU2` cutscenes. |
| **DarkShadowNemo Early Nu2 Tools** | https://github.com/DarkShadowNemo/GSCDeepDocumentation <br> https://github.com/DarkShadowNemo/GHGNoesis | Python / Markdown | Deep binary documentation (`GSCDeepDocumentation`) and Blender/Noesis importers (`old-TTGames-NemoGSCBeta`, `old-TTGames-NemoGHGBeta`, `GHGNoesis`, `oldTTGamesPS2Ani`, `oldTTGamesPS2Cut`) for early PS2/Xbox/PC Nu2 titles. |
| **NTT-Model-Dumper** (`KillzXGaming`) | https://github.com/KillzXGaming/NTT-Model-Dumper | C# | `.model` mesh/skeleton dumper for *LEGO Star Wars: The Skywalker Saga* (`NTT` Engine). |
| **NuTCrackerV3** (`JayFrancoe`) | https://github.com/JayFrancoe/NuTCrackerV3 | C | Extracts and repacks `.NXG_TEXTURES` DDS texture containers. |
| **BacTSH** (`AlubJ`) | https://github.com/AlubJ/BacTSH | C# / Python | Unpacks and repacks DX11 `.TSH` (`NuTextureSheet`) icon/sprite atlases. |
| **WiiUTexturesTool** (`connorh315`) | https://github.com/connorh315/WiiUTexturesTool | C# | Deswizzles Wii U GX2 textures in TT Games titles. |

### 3.3 Level Editors, Audio Tools, Decompilations & Modding Frameworks

| Repository / Project | URL | Language | Key Capabilities |
| :--- | :--- | :--- | :--- |
| **BrickBench** (`BrickBench`) | https://github.com/BrickBench/BrickBench <br> https://brickbench.github.io/ | Java | Full 3D level editor for *LEGO Star Wars: The Complete Saga* and level viewer for *LEGO Indiana Jones 1* & *LEGO Batman 1* (`.gsc`, `.giz`, `.ter`, `.rtl`, `.ai2`, `.scp`, `.txt`). |
| **GizEdit_2** (`Matthew6596`) | https://github.com/Matthew6596/GizEdit_2 | C# | Dedicated `.GIZ` level gizmo editor for *TCS*. |
| **CBXDecoder** (`connorh315`) | https://github.com/connorh315/CBXDecoder | C++ / C# | Decodes `.CBX` ("ChatterBoX" / EA MicroTalk variant) audio files into `.WAV` (ported to C# in `TTGamesExplorerRebirthLib/Formats/CBX.cs`). |
| **SoundEventEditor & AbilityDefEditor** (`connorh315` / `AcK77`) | https://github.com/AcK77/SoundEventEditor <br> https://github.com/connorh315/AbilityDefEditor | C# | Editors for *LEGO Dimensions* sound event tables and `.ats` / ability definitions. |
| **lsw1-decomp** (`ellierocks`) | https://github.com/ellierocks/lsw1-decomp | C / C++ | Decompilation project for *LEGO Star Wars: The Video Game* (GameCube). |
| **lego-star-wars-ii-the-original-trilogy-decomp** (`liolu`) | https://github.com/liolu/lego-star-wars-ii-the-original-trilogy-decomp | C / C++ | Matching decompilation project for *LEGO Star Wars II: The Original Trilogy* (Nintendo DS). |
| **LegoCloneWarsWii** (`ThePlayerRolo`) | https://github.com/ThePlayerRolo/LegoCloneWarsWii | C++ | Decompilation project for *LEGO Star Wars III: The Clone Wars* (Nintendo Wii). |
| **anomaly** (`connorh315`), **Traveller** (`BrickBench`), **omp-lswtss** | https://github.com/connorh315/anomaly <br> https://github.com/BrickBench/Traveller <br> https://github.com/open-modding-platform/omp-lswtss | C++ / C# | Runtime modloaders and scripting hooks for *LEGO Dimensions*, *TCS*, and *The Skywalker Saga*. |

### 3.4 *LEGO Dimensions* Toy Pad & NTAG213 NFC Tag Ecosystem

| Repository / Project | URL | Language | Key Capabilities |
| :--- | :--- | :--- | :--- |
| **LD-ToyPad-Emulator** (`Berny23`) | https://github.com/Berny23/LD-ToyPad-Emulator | JS / Node | Full USB gadget emulator and web drag-and-drop interface for the LEGO Dimensions Toy Pad. |
| **lego_dimensions_protocol** (`woodenphone`) | https://github.com/woodenphone/lego_dimensions_protocol | Python | Reverse-engineered USB HID protocol specification (`0x0E6F:0x0241`) and command framing for the Toy Pad. |
| **ldnfctags** (`phogar`) & **LegoDimensions** (`Ellerbach`) | https://github.com/phogar/ldnfctags <br> https://github.com/Ellerbach/LegoDimensions | C / C# | NTAG213 180-byte NFC tag TEA encryption/decryption, UID key derivation (`0xAA55` seed), and character/vehicle ID database. |
| **LegoToypad** (`harrysof`) & **RPCS3 Seamless Toypad** | https://github.com/harrysof/LegoToypad <br> https://github.com/NeverCookFirst/RPCS3-Seamless-Toypad-Build | C++ | Native C++ Toy Pad emulation used in RPCS3 and Cemu. |

### 3.5 *LEGO Worlds* & LDD (`.lxfml`) Tools

| Repository / Project | URL | Language | Key Capabilities |
| :--- | :--- | :--- | :--- |
| **LEGO-Worlds-lxfml-adapter** (`Alcom1`) | https://github.com/Alcom1/LEGO-Worlds-lxfml-adapter | Python / JS | Converts standard LEGO Digital Designer (`.lxfml`) blueprints into *LEGO Worlds* compatible `.lxfml` brick assemblies. |
| **ImportLDD** (`sttng`) | https://github.com/sttng/ImportLDD | Python | Blender addon for importing `.lxf` and `.lxfml` brick models. |
