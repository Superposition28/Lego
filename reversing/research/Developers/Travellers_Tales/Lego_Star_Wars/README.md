# Game Research: LEGO Star Wars (TT Games)

## 1. Franchise Overview & Inspected Builds
*LEGO Star Wars* initiated the modern TT Games formula in 2005 and spans every major generation of Traveller's Tales' technology through *The Skywalker Saga* (2022).

### Locally Inspected Builds & Disc Images
| Title | Platform & Build | Source Path / Image | Container / Filesystem | Observed Totals |
| :--- | :--- | :--- | :--- | :--- |
| *LEGO Star Wars: The Video Game* (2005) | PS2 USA v2.00 (`SLUS_210.83`) | `D:\PS2\Lego_Star_Wars\...\LEGO Star Wars - The Video Game (USA) (v2.00).iso` (`1,869,316,096` B) | `GAME.DAT` (`615,527,160` B, TOC `Version = -1` at `615,355,768`, `TocSize = 171,392` B) | **4,223 entries**, 4,564 name nodes, 44 extensions (`.ani`: 871, `.vag`: 796, `.bsa`: 616, `.txt`: 431, `.scp`: 323, `.gsc`: 164, `.ghg`: 144). `.gsc`/`.ghg`/`.cut` wrapped in `RNC\x02` (`52 4E 43 02`). |
| *LEGO Star Wars: The Video Game* (2005) | Original Xbox USA (`default.xbe`) | `D:\Xbox\Lego_Star_Wars\LEGO Star Wars - The Video Game (USA).iso` (`1,607,401,472` B) | Unpacked XDVDFS (`RootSec = 264`) | **4,721 files**, 42 extensions (`.ani`: 973, `.txt`: 874, `.bsa`: 679, `.scp`: 500, `.nux`: 259, `.cut`: 184, `.hgx`: 163, `.rtl`: 163, `.ter`: 149, `.wavx`: 124, `.ai2`: 120, `.for`: 86, `.cns`: 72). |
| *LEGO Star Wars II: The Original Trilogy* (2006) | PS2 USA (`SLUS_214.09`), EU (`SLES_542.21`), JP (`SLPM_665.72`), Demo (`SLED_543.15`) | `Games/Lego_Star_Wars/Source/Lego Star Wars II The Original Trilogy/PS2/*.iso` | `GAME.DAT` (`1,739,697,816` B USA, TOC `Version = -1` at `1,739,348,648`, `TocSize = 349,168` B) | **8,600 entries**, 9,114 name nodes, 48 extensions (`.an3`: 2,440, `.bsa`: 1,999, `.vag`: 1,037, `.txt`: 628, `.scp`: 525, `.gsc`: 448, `.ghg`: 255, `.rtl`: 156, `.ter`: 140, `.cu2`: 76). |
| *LEGO Star Wars II: The Original Trilogy* (2006) | Original Xbox USA/EU (`default.xbe`) | `Games/Lego_Star_Wars/Source/.../Xbox/LEGO Star Wars II - The Original Trilogy (USA, Europe).iso` (`1,700,003,840` B) | Unpacked XDVDFS (`RootSec = 264`) | **8,329 files**, 60 extensions (`.an3`: 2,440, `.bsa`: 1,999, `.txt`: 612, `.scp`: 478, `.nx2`: 474, `.htm`: 334 HTML exporter reports, `.hx2`: 261, `.anl`: 184, `.wavm`: 149, `.fpk`: 137). |
| *LEGO Star Wars II: The Original Trilogy* (2006) | Xbox 360 USA (`Default.xex` + `LIVE` DLC) | `Games/Lego_Star_Wars/Source/.../Xbox 360/LEGO Star Wars II - The Original Trilogy (USA).iso` (`7,834,892,288` B) | Unpacked XDVDFS at `0x0FD90000` (`RootSec = 1766496`) | **3,973 files**, 58 extensions (`.txt`: 672, `.scp`: 556, `.gsc`: 500, `.ghg`: 254, `.anl`: 184, `.ctr`: 179, `.rtl`: 178, `.xma`: 149, `.fpk`: 141, `.cc2`: 76, `.ca3`: 26). Ships `360_exlist` and `newXBOX_STARWARS_FONT_360.h`. |
| *LEGO Star Wars II: The Original Trilogy* (2006) | Windows PC (`LEGOSTA2.EXE`) | `Games/Lego_Star_Wars/Source/.../windows/LEGO Star Wars 2 PC.iso` (`616,714,240` B) | InstallShield CABs + `LEGOSTA2.EXE` (`7,493,144` B) | PE32 (`0x014C`), built `2006-09-26 17:21:58 UTC` (`0x451961B6`), PDB `c:\projects\starwars\Release_2K\starwars_pc.pdb`. |

---

## 2. Key Technical Findings from *LEGO Star Wars I & II*

### 2.1 TOC `Version = -1` (Early Console `GAME.DAT`)
- In both *LSW1* (`2005`) and *LSW2* (`2006`) PS2 `GAME.DAT` archives:
  - Bytes `0x00..0x07` store `int32_t TocOffset` and `uint32_t TocSize` (little-endian), followed by zero padding up to the first 2048-byte DVD sector (`0x800`).
  - At `TocOffset`: `Version = -1` (`0xFFFFFFFF`), `uint32_t FileCount`, `16-byte` file entries (`uint32_t DirectByteOffset`, `uint32_t CompressedSize`, `uint32_t UncompressedSize`, `uint32_t Flags = 0`), `uint32_t NameNodeCount`, `8-byte` `NameNodes`, `uint32_t StringTableSize`, and `char StringTable[StringTableSize]`.
  - **No Trailing Hash Table:** `TocOffset + 8 + FileCount*16 + 4 + NameNodeCount*8 + 4 + StringTableSize == FileSize` (`RemainderBytes = 0`). The trailing `TtPathHash[FileCount]` array was introduced in TOC `Version = -2`.

### 2.2 The `360_exlist` Cross-Platform Extension Rosetta Stone
Shipped in the root of the *LEGO Star Wars II* Xbox 360 retail disc (`Sec = 1783935`, `672` bytes), `360_exlist` groups TT Games' platform-specific file extensions by asset family:
- **Scenes**: `.nup` (PC), `.gsc` (PS2/Xbox 360), `.csc` (GameCube), `.nux` (Xbox v1), `.nx2` (Xbox v2, `"NU20"` header), `.nus` (PSP / Xbox `"GSC0"` + `"VERS"`).
- **Character Models**: `.hgp` (PC), `.ghg` (PS2/Xbox 360), `.chg` (GameCube), `.phg` / `.hgo` (PSP), `.hgx` (Xbox v1), `.hx2` (Xbox v2, accompanied by `334` `.hx2.htm` HTML exporter memory reports from `C:\Projects\LocalDataXbox\`).
- **Terrain Collision**: `.ter` (little-endian `100-byte` `TerrainMeshFace` records) vs. `.ctr` (big-endian Xbox 360 / GameCube terrain).
- **Skeletal & Facial Animations**: `.ani` (Gen 1 relocated animation, byte-identical between PS2 and Xbox) -> `.an3` (`4INA` little-endian) / `.ca3` (`ANI5` big-endian with relocation table offset at `0x00`); `.bsa` (little-endian blendshape) / `.cbs` (big-endian blendshape).
- **Cutscenes**: `.cut` (Gen 1 relocated cutscene, `RNC\x02`-compressed on PS2) / `.cct` / `.rcu` -> `.cu2` (little-endian v516 `0x0204`) / `.cc2` (big-endian v516 `0x00000204`).
- **Star Wars Gameplay Tables**: `.for` (Force-manipulable object tables), `.cns` (LEGO Build-it construction tables), `.bur` (debris burst emitters), `.fsp` (podrace/vehicle flight splines).
