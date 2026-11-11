# LEGO Games Reverse Engineering Research Index

This directory (`EngineApps\Games\Lego\reversing\research\`) contains the technical research, binary format specifications, cross-title comparisons, community tool catalogs, and Remake Engine C# integration blueprints for Traveller's Tales (TT Games / TT Fusion) LEGO titles (`2005`–`2024`).

---

## 1. Online Resources, Community Tools & Remake Engine Integration

| Document | Scope & Contents |
| :--- | :--- |
| **[Online_Resources_and_Tools.md](Online_Resources_and_Tools.md)** | Comprehensive catalog of online reverse-engineering websites (`ttmodding.com`, `aluigi.altervista.org/quickbms.htm`, Xentax/ZenHAX archives, Rock Raiders United, PCGamingWiki), all 11+ QuickBMS scripts (`ttgames.bms` v0.9.11a, `gsc_nu20.bms`, `bionicle.bms`, `crash_woc_dat.bms`, `fuse_fib.bms`, `lego_alltxt.bms`, `lego_starwars_nds.bms`, `lego_universe.bms`), 35+ open-source GitHub repositories (`AcK77/TTGames-Explorer-Rebirth`, `AcK77/EdRegistry`, `Loomirr/TTGames-Workshop`, `AlubJ/TTGames-Extraction-Tools`, `IsaMorphic/DATOneArchiver`, `IsaMorphic/NuXtractor`, `Clarence-Oveur/EasyAN3`, `DarkShadowNemo/GSCDeepDocumentation`, `KillzXGaming/NTT-Model-Dumper`, `BrickBench/BrickBench`, `Matthew6596/GizEdit_2`, `connorh315/CBXDecoder`, `ellierocks/lsw1-decomp`, `liolu/lego-star-wars-ii-the-original-trilogy-decomp`, `Berny23/LD-ToyPad-Emulator`, etc.), and an audit of local clones in [`../ExternalTools/`](../ExternalTools/) and [`../TTModding-Docs/`](../TTModding-Docs/). |
| **[RemakeEngine_GameFormats_Integration.md](RemakeEngine_GameFormats_Integration.md)** | Architectural analysis and implementation blueprint for integrating native C# TT Games Nu20/NTT format parsers (`DATArchive`, `Pk`, `LZ2K`, `Deflatev1`, `UnRefpack`, `NuScene`/`.gsc`/`.ghg`, `NXGTextures`, `TSH`, `FT2`, `An3`, `CBX`, `EdFile`, `PinnerDynamicsObj`) from [`../ExternalTools/TTGames-Explorer-Rebirth`](../ExternalTools/TTGames-Explorer-Rebirth/src/TTGamesExplorerRebirth.sln) directly into [`EngineNet/source/GameFormats/ttgames/`](../../../../EngineNet/source/GameFormats) and [`EngineNet/source/Core/DiscImages/`](../../../../EngineNet/source/Core/DiscImages). |

---

## 2. Developer & Per-Title Binary Research (`Developers/Travellers_Tales/`)

| Document / Folder | Era & TOC Version | Inspected Titles, Releases & Binary Evidence |
| :--- | :--- | :--- |
| **[Developers/Travellers_Tales/README.md](Developers/Travellers_Tales/README.md)** | `1999`–`2024` (`v-1` to `v-12`) | Master architectural synthesis of the Traveller's Tales Nu2 / Nu20 / NTT engine across 6 hardware/engine generations, `.DAT`/`.HDR` TOC evolution (`v-1` through `v-12`), `LZ2K`/`CMP2`/`Oodle` compression, `NU20`/`20UN`/`ROTV` `.GSC`/`.GHG` scene graphs, and the 184-extension cross-title file census. |
| **[Developers/Travellers_Tales/Lego_Star_Wars/](Developers/Travellers_Tales/Lego_Star_Wars/README.md)** | Gen 1 (`2005`, No `.DAT` / Early `v-1`) | *LEGO Star Wars: The Video Game* — PS2 (`SLUS-20945` raw filesystem + `SLUS-21083` GH `DATA.DAT`/`DATA.HDR` TOC `v-1`), Original Xbox (`default.xbe` XISO), and GameCube (`GL5E4F` `.rvz`). |
| **[Developers/Travellers_Tales/Lego_Star_Wars_II/](Developers/Travellers_Tales/Lego_Star_Wars_II/README.md)** | Gen 1 → Gen 2 Transition (`2006`, TOC `v-1`) | *LEGO Star Wars II: The Original Trilogy* — PS2 (`SLUS_214.09`, `SLES_542.21`, `SLED_543.15` Demo, `SLPM_665.72` JP), Original Xbox, Xbox 360 (`default.xex` + `360_exlist.txt` + `LIVE` STFS DLC), and Windows PC (`LEGOSTA2.EXE`). |
| **[Developers/Travellers_Tales/Lego_Star_Wars_TCS/](Developers/Travellers_Tales/Lego_Star_Wars_TCS/README.md)** | Gen 2 (`2007`, TOC `v-1` / `v-2`) | *LEGO Star Wars: The Complete Saga* — Early next-gen Nu20 architecture, `ST2` stream containers, `.hgp`/`.gsa` transitions. |
| **[Developers/Travellers_Tales/Lego_Indiana_Jones/](Developers/Travellers_Tales/Lego_Indiana_Jones/README.md)** | Gen 2 (`2008`–`2009`, TOC `v-2` / `v-3`) | *LEGO Indiana Jones: The Original Adventures* & *LEGO Indiana Jones 2: The Adventure Continues* — Introduction of `.gsc`/`.ghg`, `.nxg_textures`, and level creator systems. |
| **[Developers/Travellers_Tales/Lego_Batman/](Developers/Travellers_Tales/Lego_Batman/README.md)** | Gen 2 → Gen 3 (`2008`–`2014`, TOC `v-2` to `v-5`) | *LEGO Batman: The Videogame* (`2008`), *LEGO Batman 2: DC Super Heroes* (`2012` WinSteam `LEGOBatman2.exe`, `GAME0.DAT`–`GAME6.DAT` + `.WAD` + `__GlyphData.eng` + `FMV/*.OGO`), and *LEGO Batman 3: Beyond Gotham* (`2014`). |
| **[Developers/Travellers_Tales/Lego_Harry_Potter/](Developers/Travellers_Tales/Lego_Harry_Potter/README.md)** | Gen 2.5 (`2010`–`2011` / `2024`, TOC `v-5`) | *LEGO Harry Potter: Years 1–4* & *Years 5–7* — PS3 (`BLUS30513`, `BLES00779`, `BLES01447`), Xbox 360 Retail & Demos, and 2024 Double Eleven Remastered PC (`__data/*.datwin` + `launcher.pkiwin`/`launcher.pkdwin` + `GAME.CFP`). Includes [Y1-4_vs_Y5-7_Evolution.md](Developers/Travellers_Tales/Lego_Harry_Potter/Y1-4_vs_Y5-7_Evolution.md). |
| **[Developers/Travellers_Tales/Lego_Dimensions/](Developers/Travellers_Tales/Lego_Dimensions/README.md)** | Gen 4 (`2015`, TOC `v-7` + `CMP2` LZMA) | *LEGO Dimensions* — PS3 EU (`BLES02158`) & US (`BLUS31456`), 10 `.HDR`/`.DAT` pairs (`56,574` entries), `CMP2` LZMA-chunked `INSTALL0_*.DAT` packages, `.ADP` middleware, `.BUILD`/`.BLD`, and 47 180-byte NTAG213 NFC Toy Tag `.bin` dumps (`0x24`/`0x25` XTEA payload + `0x2B` PWD). |

---

## 3. Cross-Reference Comparisons (`cross-reference/`)

| Document | Scope |
| :--- | :--- |
| **[cross-reference/README.md](cross-reference/README.md)** | Cross-platform & cross-title binary comparison across PS2, Original Xbox, GameCube, Xbox 360, PS3, and Windows PC (`2005`–`2024`). |
| **[cross-reference/GameFiles_Comparison.md](cross-reference/GameFiles_Comparison.md)** | Byte-level comparison of extracted `.DAT` archives across PS3, Xbox 360, and PC releases of *LEGO Harry Potter* (`Years 1–4` and `Years 5–7`). |
| **[cross-reference/ISO_and_Release_Comparison.md](cross-reference/ISO_and_Release_Comparison.md)** | Disc image layout, sector geometry, and regional SKU comparison across all inspected ISO/XISO/RVZ/PKG/Steam dumps. |

---

## 4. Generated HTML Documentation Sites (`../docs/` & `../../Games/*/reversing/docs/`)

All interactive HTML documentation sites are generated by [`../../generate_docs.ps1`](../../generate_docs.ps1) and verified in Chrome:
- **Master Traveller's Tales Documentation:** [`../docs/Travellers_Tales/index.html`](../docs/Travellers_Tales/index.html)
- **Per-Game Documentation Sites:**
  - [`../../Games/Lego_Star_Wars/reversing/docs/index.html`](../../Games/Lego_Star_Wars/reversing/docs/index.html)
  - [`../../Games/Lego_Star_Wars_II/reversing/docs/index.html`](../../Games/Lego_Star_Wars_II/reversing/docs/index.html)
  - [`../../Games/Lego_Star_Wars_TCS/reversing/docs/index.html`](../../Games/Lego_Star_Wars_TCS/reversing/docs/index.html)
  - [`../../Games/Lego_Indiana_Jones/reversing/docs/index.html`](../../Games/Lego_Indiana_Jones/reversing/docs/index.html)
  - [`../../Games/Lego_Batman/reversing/docs/index.html`](../../Games/Lego_Batman/reversing/docs/index.html)
  - [`../../Games/Lego_Harry_Potter/reversing/docs/index.html`](../../Games/Lego_Harry_Potter/reversing/docs/index.html)
  - [`../../Games/Lego_Dimensions/reversing/docs/index.html`](../../Games/Lego_Dimensions/reversing/docs/index.html)
  - [`../../Games/Lego_Hobbit_LOTR/reversing/docs/index.html`](../../Games/Lego_Hobbit_LOTR/reversing/docs/index.html)
