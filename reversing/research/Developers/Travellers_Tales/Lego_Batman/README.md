# Game Research: LEGO Batman (TT Games)

## 1. Franchise Overview
The *LEGO Batman* series marks TT Games' expansion into DC Comics, introducing suit-swapping mechanics (*LEGO Batman 1*, 2008), full voice acting and open-world hubs (*LEGO Batman 2: DC Super Heroes*, 2012), DX11 rendering and `.tsh` sprite sheets (*LEGO Batman 3: Beyond Gotham*, 2014), and 64-bit FNV-1a `.CC40TAD` archives (*LEGO DC Super-Villains*, 2018).

---

## 2. Locally Inspected Build: *LEGO Batman 2: DC Super Heroes* (Windows Steam, 2012)

### 2.1 Build & Executable Identity
- **Source Directory:** `Games/Lego_Batman/Source/WinSteam/Batman 2 DC super heroes/`
- **Executable (`LEGOBatman2.exe`):** `18,690,560` bytes, 32-bit x86 (`PE32`, `Machine = 0x014C`), 8 sections, linked `2012-05-25 13:57:20 UTC` (`0x4FBF8FC0`). Contains `StreamInfo`, `LZ2K`, `Deflate_v1.0`, and `SERIALISED` serializers.
- **Shipped Build Metadata (`GAMEVERSION.TXT`):**
  - `BuildRecordId: 412210`, `TTBuilder-Version: 1.00.51`, `Date: 2012-05-25 14:52:48`
  - `AccurevStream: SuperHeroes1-25-05-12-v0.97c_Hotfix` (`AccurevTransactionId: 4502005`)
  - `SVN_Repository: svn://ukknuwp-svn01:3691/LEGO_SuperHeroes1_Data/tags/superheroes1/TTBuilder/complete/SuperHeroes1-25-05-12-v0.97c` (`SVN_Revision: 127098`)
- **Shipped Loose Files:**
  - `FILETABLE.TXT` (`1,482,457` B, `18,915` lines): Full asset timestamp manifest including `__dlc1__` (Hero Pack: Zatanna, Damian Robin, Nightwing, Katana, Captain Marvel), `__dlc2__` (Villain Pack: Gorilla Grodd, Captain Cold, Black Manta, Black Adam, Bizarro), and `wii\strapscreens\*`.
  - `TRACKEDFILELIST360.TXT` (`55,398` B) & `DEMOPLAYTHROUGHLOGFILE.TXT` (`120,209` B): Ordered disc-layout file tracking log starting with `__DISC__` and `stuff\lensflaregradient_nxg.tex`.
  - `ICONS_TEX.PAK` (`2,361,498` B): Standalone `0x1234567A` (`7A 56 34 12`) package containing `276` (`0x0114`) UI icon entries.

### 2.2 Archive Volumes (`PakDat v1.01`, TOC `Version = -4`)
| Archive | Size (Bytes) | TOC Offset | TOC Size | Entries | Raw (`0`) | LZ2K (`2`) | SHA-256 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | :--- |
| `GAME.DAT` | `1,294,431,115` | `1,294,118,055` | `313,060` | `5,817` | `3,572` | `2,245` | `F95600D97BFB06F6BC32CCD5130C036E89C1D890F9BB9AC18DA6B83E3A845983` |
| `GAME0.DAT` | `1,235,145,401` | `1,234,911,481` | `233,920` | `4,357` | `1,858` | `2,499` | `B14914D3AAE81B29F721D8EE4A25B46586B3E5C87E751C51ADF279BF3790D603` |
| `GAME1.DAT` | `1,229,013,641` | `1,228,940,165` | `73,476` | `1,476` | `647` | `829` | `A3806AC25C6B3BD0FFAEF846B655EA6199FC0061BE28FAA2512CDD3792DD9EBA` |
| `GAME2.DAT` | `251,488,684` | `251,476,788` | `11,896` | `215` | `84` | `131` | `5C8D97A3199D85D9CE41F24E2C215B5487F7C92345C0CBEFA7642A5201183636` |
| **Total** | **`4,010,078,841`** | — | **`632,352`** | **`11,865`** | **`6,161`** | **`5,704`** | **100% (`11,865/11,865`) extracted & verified (`6,464,138,301` B)** |

### 2.3 Format Evolution Highlights in *LEGO Batman 2* (Era 3c `Gotham` Variant)
- **Cutscene Upgrade (`.cu2` -> `.cu3`):** Replaces `.cu2` (`0` occurrences) with `206` `.cu3` files (`NuResourceHeader` `.CC4` + `HSER` cutscene streams) and `185` `.sub` localized subtitle timing streams to support full voice acting.
- **AI & Scripting:** Contains `186` `.aib` (compiled AI behavior trees), `705` `.sf` script functions, `1,991` `.led` level editor streams, and `5` `.lua` scripts (`framework-data/gui/...`).
- **Shaders:** Ships `715` individual `.pc_shaders` members (`CC4HSERHSCB` header) inside `GAME*.DAT`.
